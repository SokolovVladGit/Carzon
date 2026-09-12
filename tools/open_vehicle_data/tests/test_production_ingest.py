from __future__ import annotations

import io
import json
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.open_vehicle_data.acquire import ALLOWED_HOSTS, assert_allowed_url
from tools.open_vehicle_data.cli import main
from tools.open_vehicle_data.eea_aggregate import (
    EeaStats,
    aggregate_eea_file,
    aggregate_eea_paths,
    iter_chunked,
    upsert_payload,
)
from tools.open_vehicle_data.eea_source import iter_eea_records, project_eea_row
from tools.open_vehicle_data.loader import LoaderError, ServiceRoleLoader
from tools.open_vehicle_data.makes import FIRST_ROLLOUT_MAKES, parse_makes_arg
from tools.open_vehicle_data.pipeline import run_pipeline
from tools.open_vehicle_data.privacy import assert_no_pii, forbidden_keys_present
from tools.open_vehicle_data.rdw_aggregate import aggregate_rdw_rows, merge_payload
from tools.open_vehicle_data.rdw_source import iter_rdw_joined, iter_rdw_records, project_rdw_row
from tools.open_vehicle_data.vehiclesdb_source import PAID_KEYS, load_open_identity

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"


class EeaOfficialAdapterTest(unittest.TestCase):
    def test_official_columns_and_units(self):
        row = project_eea_row(
            {
                "Mk": "SKODA",
                "Cn": "OCTAVIA",
                "r": "2018",
                "Tan": "e8*2007/46*0318*00",
                "T": "5E",
                "Va": "ACDDYAX0",
                "Ve": "NFM5A",
                "Ft": "Diesel",
                "Fm": "M",
                "Ec (cm3)": "1598",
                "ep (KW)": "85",
                "Status": "F",
                "Ms": "NL",
            }
        )
        self.assertEqual(row["make"], "SKODA")
        self.assertEqual(row["year"], "2018")
        self.assertEqual(row["ec_cm3"], "1598")
        self.assertEqual(row["ep_kw"], "85")
        self.assertEqual(row["status"], "F")
        self.assertNotEqual(row["status"], "NL")

    def test_stream_official_csv(self):
        rows = list(iter_eea_records(FIXTURES / "eea_official_sample.csv"))
        self.assertGreaterEqual(len(rows), 6)
        self.assertTrue(all("make" in row for row in rows))

    def test_zip_streams_without_list_materialize_helper(self):
        with tempfile.TemporaryDirectory() as tmp:
            archive = Path(tmp) / "eea-official.zip"
            with zipfile.ZipFile(archive, "w") as zf:
                zf.write(FIXTURES / "eea_official_sample.csv", "co2_sample.csv")
            stats = EeaStats()
            aggregated = aggregate_eea_file(archive, stats=stats)
            self.assertGreater(len(aggregated), 0)
            self.assertGreater(stats.read, len(aggregated))

    def test_fp_preference_and_make_filter(self):
        stats = EeaStats()
        make_keys = parse_makes_arg(None, preset="first")
        aggregated = aggregate_eea_file(
            FIXTURES / "eea_official_sample.csv",
            make_keys=make_keys,
            stats=stats,
        )
        keys = {row["make_key"] for row in aggregated}
        self.assertNotIn("chery", keys)
        self.assertIn("skoda", keys)
        octavia = [row for row in aggregated if row["make_key"] == "skoda"]
        self.assertEqual(sum(row["observation_count"] for row in octavia), 2)
        self.assertGreater(stats.rejected, 0)

    def test_zero_power_and_displacement_become_null(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "zero.csv"
            path.write_text(
                "Mk,Cn,Year,Tan,T,Va,Ve,Ft,Fm,Ec,Ep,status\n"
                "BMW,120D,2014,e1*2007/46*0283*00,1K4,1C31,5H25000,DIESEL,M,1995,0,F\n",
                encoding="utf-8",
            )
            aggregated = aggregate_eea_file(path)
            self.assertEqual(len(aggregated), 1)
            self.assertIsNone(aggregated[0]["power_kw"])
            self.assertEqual(aggregated[0]["engine_displacement_cm3"], 1995)

    def test_p_file_does_not_duplicate_finalized_year(self):
        with tempfile.TemporaryDirectory() as tmp:
            finalized = Path(tmp) / "co2_2018_f.csv"
            provisional = Path(tmp) / "co2_2018_p.csv"
            finalized.write_text(
                "Mk,Cn,Year,Tan,T,Va,Ve,Ft,Fm,Ec,Ep,status\n"
                "SKODA,OCTAVIA,2018,e8*2007/46*0318*00,5E,A,B,Diesel,M,1598,85,F\n",
                encoding="utf-8",
            )
            provisional.write_text(
                "Mk,Cn,Year,Tan,T,Va,Ve,Ft,Fm,Ec,Ep,status\n"
                "SKODA,OCTAVIA,2018,e8*2007/46*0318*00,5E,A,B,Diesel,M,1598,85,P\n"
                "SKODA,OCTAVIA,2024,e8*2007/46*0318*00,5E,A,C,Diesel,M,1598,85,P\n",
                encoding="utf-8",
            )
            aggregated = aggregate_eea_paths([finalized, provisional])
            years = {(row["year_min"], row["year_max"], row["version_code"]) for row in aggregated}
            self.assertIn((2018, 2018, "B"), years)
            self.assertIn((2024, 2024, "C"), years)
            self.assertEqual(len(aggregated), 2)

    def test_partial_and_malformed_rows(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "partial.csv"
            path.write_text(
                "Mk,Cn,Year,status\n"
                "SKODA,OCTAVIA,2018,F\n"
                ",,not-a-year,F\n"
                "SKODA,OCTAVIA,2018,X\n",
                encoding="utf-8",
            )
            stats = EeaStats()
            aggregated = aggregate_eea_file(path, stats=stats)
            self.assertEqual(aggregated, [])
            self.assertEqual(stats.read, 2)
            self.assertEqual(stats.rejected, 2)


class ChunkAndLoaderTest(unittest.TestCase):
    def test_chunk_boundaries(self):
        rows = [{"n": i} for i in range(5)]
        chunks = list(iter_chunked(rows, 2))
        self.assertEqual([len(chunk) for chunk in chunks], [2, 2, 1])

    def test_retry_then_success(self):
        attempts = {"n": 0}

        def transport(name: str, payload: dict) -> int:
            attempts["n"] += 1
            if attempts["n"] < 3:
                raise LoaderError("timeout")
            return 1

        loader = ServiceRoleLoader(
            url="http://127.0.0.1:54321",
            service_role_key="super-secret-service-role-key-xyz",
            chunk_size=10,
            transport=transport,
            sleep=lambda _: None,
        )
        sent = loader.send_chunks("carzon_open_data_upsert_configurations", [{"type_code": "5E"}])
        self.assertEqual(sent["rows"], 1)
        self.assertEqual(attempts["n"], 3)

    def test_failed_chunk_index_and_no_secret_in_logs(self):
        logs: list[str] = []

        def transport(name: str, payload: dict) -> int:
            raise LoaderError("timeout")

        loader = ServiceRoleLoader(
            url="https://example.supabase.co",
            service_role_key="super-secret-service-role-key-xyz",
            chunk_size=1,
            transport=transport,
            sleep=lambda _: None,
            log=logs.append,
        )
        with self.assertRaises(LoaderError) as ctx:
            loader.send_chunks(
                "carzon_open_data_upsert_configurations",
                [{"a": 1}, {"a": 2}],
            )
        self.assertEqual(ctx.exception.chunk_index, 0)
        blob = "\n".join(logs)
        self.assertNotIn("super-secret-service-role-key-xyz", blob)
        self.assertIn("chunk=0", blob)

    def test_idempotent_same_payload(self):
        seen: list[list] = []

        def transport(name: str, payload: dict) -> int:
            seen.append(payload["p_rows"])
            return len(payload["p_rows"])

        rows = [{"type_code": "5E", "variant_code": "A", "version_code": "B"}]
        loader = ServiceRoleLoader(
            url="http://127.0.0.1:54321",
            service_role_key="local-test-key",
            transport=transport,
        )
        loader.send_chunks("carzon_open_data_upsert_configurations", rows)
        loader.send_chunks("carzon_open_data_upsert_configurations", rows)
        self.assertEqual(seen[0], seen[1])

    def test_resume_skips_start_chunk(self):
        names: list[int] = []

        def transport(name: str, payload: dict) -> int:
            names.append(len(payload["p_rows"]))
            return 1

        loader = ServiceRoleLoader(
            url="http://127.0.0.1:54321",
            service_role_key="local-test-key",
            chunk_size=1,
            transport=transport,
        )
        sent = loader.send_chunks(
            "carzon_open_data_upsert_configurations",
            [{"a": 1}, {"a": 2}, {"a": 3}],
            start_chunk=2,
        )
        self.assertEqual(sent["skipped"], 2)
        self.assertEqual(sent["rows"], 1)


class RdwAcquisitionTest(unittest.TestCase):
    def test_official_drops_plate_before_aggregate(self):
        rows = list(iter_rdw_records(FIXTURES / "rdw_official_sample.csv"))
        self.assertTrue(rows)
        for row in rows:
            assert_no_pii(row)
            self.assertNotIn("kenteken", row)
        out = aggregate_rdw_rows(rows)
        self.assertNotIn("kenteken", json.dumps(out))
        payload = merge_payload(out)
        self.assertTrue(any(item["inrichting"] == "wagon" for item in payload))
        self.assertTrue(any(item["inrichting"] == "sedan" for item in payload))

    def test_transient_plate_join(self):
        with tempfile.TemporaryDirectory() as tmp:
            vehicles = Path(tmp) / "vehicles.csv"
            bodies = Path(tmp) / "bodies.csv"
            vehicles.write_text(
                "kenteken,type,variant,uitvoering,typegoedkeuringsnummer\n"
                "XX123X,5E,ACDDYAX0,NFM5A,e8*2007/46*0318*00\n",
                encoding="utf-8",
            )
            bodies.write_text(
                "kenteken,carrosserietype,inrichting\n"
                "XX123X,AC,stationwagen\n",
                encoding="utf-8",
            )
            rows = list(iter_rdw_joined(vehicles, bodies))
            self.assertEqual(len(rows), 1)
            assert_no_pii(rows[0])
            self.assertEqual(rows[0]["type_code"], "5E")
            aggregated = aggregate_rdw_rows(rows)
            self.assertEqual(aggregated[0]["body_type_rdw"], "wagon")

    def test_raw_official_still_rejected_by_sanitize_path(self):
        raw = {"kenteken": "XX123X", "type": "5E", "variant": "A", "uitvoering": "B"}
        self.assertIn("kenteken", forbidden_keys_present(raw))
        self.assertIsNotNone(project_rdw_row(raw))


class VehiclesDbAcquisitionTest(unittest.TestCase):
    def test_free_layer_and_attribution(self):
        payload = load_open_identity(
            FIXTURES / "vehiclesdb_sample.json",
            source_version="unknown",
        )
        self.assertEqual(payload["source_version"], "2026.09.1")
        self.assertIsNotNone(payload["attribution"])
        self.assertGreaterEqual(len(payload["nameplates"]), 3)
        self.assertTrue(any(row.get("alias_model") == "Octavia Combi" for row in payload["aliases"]))
        self.assertTrue(payload["paid_fields_ignored"])
        self.assertTrue(PAID_KEYS)

    def test_paid_specs_not_mapped(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "paid.json"
            path.write_text(
                json.dumps(
                    {
                        "source_version": "x",
                        "attribution": {"license": "CC BY 4.0"},
                        "models": [
                            {
                                "make": "Skoda",
                                "name": "Octavia",
                                "body_types": ["wagon"],
                                "engines": [{"hp": 150}],
                                "specs": {"awd": "xDrive"},
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            payload = load_open_identity(path, source_version="x")
            blob = json.dumps(payload)
            self.assertNotIn("xDrive", blob)
            self.assertNotIn("engines", blob)


class DryRunPipelineTest(unittest.TestCase):
    def test_dry_run_reports_without_transport(self):
        calls: list[str] = []

        def transport(name: str, payload: dict) -> int:
            calls.append(name)
            return 1

        loader = ServiceRoleLoader(
            url="https://example.supabase.co",
            service_role_key="super-secret-service-role-key-xyz",
            dry_run=True,
            chunk_size=2,
            transport=transport,
        )
        report = run_pipeline(
            loader=loader,
            eea_paths=[FIXTURES / "eea_official_sample.csv"],
            rdw_path=FIXTURES / "rdw_official_sample.csv",
            vehiclesdb_path=FIXTURES / "vehiclesdb_sample.json",
            source_version="test-local",
            make_keys=parse_makes_arg(None, preset="first"),
            vehiclesdb_version="2026.09.1",
        )
        self.assertEqual(calls, [])
        self.assertTrue(report["dry_run"])
        self.assertGreater(report["eea"]["source_rows_read"], 0)
        self.assertGreater(report["eea"]["normalized_configurations"], 0)
        self.assertGreater(report["eea"]["chunks"]["chunks"], 0)
        self.assertGreater(report["rdw"]["body_aggregates"], 0)
        self.assertGreater(report["vehiclesdb"]["nameplates"], 0)
        self.assertFalse(report["would_mutate_hosted"])

    def test_cli_dry_run(self):
        buf = io.StringIO()
        old = sys.stdout
        sys.stdout = buf
        try:
            code = main(
                [
                    "ingest",
                    "--dry-run",
                    "--eea",
                    str(FIXTURES / "eea_official_sample.csv"),
                    "--rdw",
                    str(FIXTURES / "rdw_official_sample.csv"),
                    "--vehiclesdb",
                    str(FIXTURES / "vehiclesdb_sample.json"),
                    "--source-version",
                    "cli-dry",
                    "--makes-preset",
                    "first",
                    "--chunk-size",
                    "2",
                ]
            )
        finally:
            sys.stdout = old
        self.assertEqual(code, 0)
        report = json.loads(buf.getvalue())
        self.assertTrue(report["dry_run"])

    def test_acquire_rejects_unknown_host(self):
        with self.assertRaises(ValueError):
            assert_allowed_url("https://evil.example/dump.csv")
        self.assertIn("opendata.rdw.nl", ALLOWED_HOSTS)

    def test_first_rollout_is_config_not_hardcoded_catalog(self):
        self.assertEqual(len(FIRST_ROLLOUT_MAKES), 10)
        custom = parse_makes_arg("Skoda,Tesla", preset=None)
        self.assertEqual(custom, frozenset({"skoda", "tesla"}))


if __name__ == "__main__":
    unittest.main()
