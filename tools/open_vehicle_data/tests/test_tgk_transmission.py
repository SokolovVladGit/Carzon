from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.open_vehicle_data.loader import ServiceRoleLoader
from tools.open_vehicle_data.tgk_transmission import (
    TGK_MAPPING_VERSION,
    TGK_SOURCE,
    aggregate_tgk_rows,
    consensus_for_codes,
    ingest_row,
    ingest_tgk_transmissions,
    iter_tgk_pages,
    join_catalog,
    map_tgk_gearbox,
    sanity_gate,
    summarize,
    tvv_key,
)


class MappingTest(unittest.TestCase):
    def test_official_safe_codes(self):
        self.assertEqual(map_tgk_gearbox("M"), "manual")
        self.assertEqual(map_tgk_gearbox("A"), "automatic")
        self.assertEqual(map_tgk_gearbox("C"), "cvt")
        self.assertEqual(map_tgk_gearbox("D"), "dual_clutch")
        self.assertEqual(map_tgk_gearbox("G"), "robotic")
        self.assertEqual(map_tgk_gearbox("O"), "other")
        self.assertEqual(map_tgk_gearbox("c"), "cvt")

    def test_conservative_unmapped(self):
        for code in ("F", "H", "S", "W", "X", "", None):
            self.assertIsNone(map_tgk_gearbox(code))

    def test_fixed_ratio_is_not_automatic(self):
        decision = consensus_for_codes(["F", "F"])
        self.assertIsNone(decision["transmission_type"])
        self.assertEqual(decision["status"], "unmapped")


class ConsensusTest(unittest.TestCase):
    def test_agree(self):
        decision = consensus_for_codes(["M", "m", "M"])
        self.assertEqual(decision["transmission_type"], "manual")
        self.assertEqual(decision["status"], "agree")
        self.assertEqual(decision["raw"], "M")

    def test_conflict_is_null_no_majority(self):
        decision = consensus_for_codes(["M", "M", "A"])
        self.assertIsNone(decision["transmission_type"])
        self.assertEqual(decision["status"], "conflict")
        self.assertEqual(decision["raw"], "A,M")

    def test_unresolved_relevant_is_null(self):
        decision = consensus_for_codes(["A", "F"])
        self.assertIsNone(decision["transmission_type"])
        self.assertIn(decision["status"], {"unresolved", "conflict"})


class JoinTest(unittest.TestCase):
    def test_tan_revision_and_tvv(self):
        self.assertEqual(
            tvv_key("e8*2007/46*0318*25", "ACDDYAX0", "NFM5A"),
            ("e8*2007/46*0318", "acddyax0", "nfm5a"),
        )

    def test_duplicate_revisions_agree(self):
        agg = aggregate_tgk_rows(
            [
                {
                    "typegoedkeuringsnummer": "e11*2007/46*0243*01",
                    "codevarianttgk": "AA",
                    "codeuitvoeringtgk": "BB",
                    "volgnummerrevisieuitvoering": "1",
                    "volgnummerversnelling": "1",
                    "codetypeversnellingsbak": "A",
                },
                {
                    "typegoedkeuringsnummer": "e11*2007/46*0243*88",
                    "codevarianttgk": "aa",
                    "codeuitvoeringtgk": "bb",
                    "volgnummerversnelling": "2",
                    "codetypeversnellingsbak": "A",
                },
            ]
        )
        key = ("e11*2007/46*0243", "aa", "bb")
        self.assertEqual(agg.decisions()[key]["transmission_type"], "automatic")

    def test_duplicate_revisions_conflict(self):
        agg = aggregate_tgk_rows(
            [
                {
                    "typegoedkeuringsnummer": "e11*2007/46*0243*01",
                    "codevarianttgk": "AA",
                    "codeuitvoeringtgk": "BB",
                    "codetypeversnellingsbak": "M",
                },
                {
                    "typegoedkeuringsnummer": "e11*2007/46*0243*02",
                    "codevarianttgk": "AA",
                    "codeuitvoeringtgk": "BB",
                    "codetypeversnellingsbak": "A",
                },
            ]
        )
        key = ("e11*2007/46*0243", "aa", "bb")
        self.assertIsNone(agg.decisions()[key]["transmission_type"])

    def test_join_updates_existing_tvv_only(self):
        decisions = {
            ("e1*1", "v", "u"): consensus_for_codes(["C"]),
            ("missing", "v", "u"): consensus_for_codes(["A"]),
        }
        matched = join_catalog(decisions, {("e1*1", "v", "u")})
        self.assertEqual(len(matched), 1)
        self.assertEqual(matched[0]["transmission_type"], "cvt")
        self.assertEqual(matched[0]["raw"], "C")
        self.assertNotIn("drivetrain", matched[0])


class StreamingTest(unittest.TestCase):
    def test_pages_are_not_materialized_by_helper(self):
        pages = [
            [
                {
                    "typegoedkeuringsnummer": "e1*1*1*1",
                    "codevarianttgk": "V",
                    "codeuitvoeringtgk": "U",
                    "codetypeversnellingsbak": "M",
                }
            ],
            [],
        ]

        def fetch(_url: str) -> list:
            return pages.pop(0)

        rows = list(iter_tgk_pages(page_size=1, fetch=fetch, base_url="https://opendata.rdw.nl/resource/7rjk-eycs.json"))
        self.assertEqual(len(rows), 1)
        self.assertEqual(map_tgk_gearbox(rows[0]["codetypeversnellingsbak"]), "manual")


class LoaderIdempotencyTest(unittest.TestCase):
    def test_chunk_retry_and_lineage_payload(self):
        calls: list[tuple[str, dict]] = []

        def transport(name: str, payload: dict):
            calls.append((name, payload))
            if name == "carzon_open_data_begin_import_batch":
                return "batch-1"
            return 2

        loader = ServiceRoleLoader(
            url="https://example.supabase.co",
            service_role_key="service-role-key",
            chunk_size=1,
            transport=transport,
        )
        rows = [
            ingest_row(("e1", "v", "u"), consensus_for_codes(["M"])),
            ingest_row(("e2", "v", "u"), consensus_for_codes(["A", "M"])),
        ]
        report = ingest_tgk_transmissions(loader, rows, source_version="ivi-1.11")
        self.assertTrue(report["ok"])
        self.assertEqual(report["rows"], 2)
        rpc_names = [name for name, _ in calls]
        self.assertEqual(rpc_names[0], "carzon_open_data_begin_import_batch")
        self.assertEqual(calls[0][1]["p_source"], TGK_SOURCE)
        upserts = [payload for name, payload in calls if name == "carzon_open_data_upsert_tgk_transmissions"]
        self.assertEqual(len(upserts), 2)
        self.assertEqual(upserts[0]["p_batch_id"], "batch-1")
        self.assertEqual(upserts[0]["p_rows"][0]["raw"], "M")
        self.assertIsNone(upserts[1]["p_rows"][0]["transmission_type"])
        self.assertEqual(TGK_MAPPING_VERSION, "m1.1")


class SanityTest(unittest.TestCase):
    def test_t0_like_distribution_passes(self):
        agg = aggregate_tgk_rows([])
        agg.rows_read = 5_800_000
        agg.code_counts.update({"M": 5610000, "A": 4180000, "C": 90000})
        report = summarize(agg, {})
        report["match_pct"] = 80.0
        self.assertEqual(sanity_gate(report), [])

    def test_material_contradiction_blocks(self):
        report = {
            "rows_read": 100,
            "code_distribution": {"F": 90, "A": 10},
            "match_pct": 10,
        }
        self.assertTrue(sanity_gate(report))


if __name__ == "__main__":
    unittest.main()
