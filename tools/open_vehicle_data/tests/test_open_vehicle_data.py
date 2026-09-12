from __future__ import annotations

import json
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.open_vehicle_data.consensus import resolve_mmy, year_overlaps
from tools.open_vehicle_data.eea_aggregate import aggregate_eea_rows, upsert_payload
from tools.open_vehicle_data.normalize import (
    cm3_to_liters,
    configuration_key,
    kw_to_hp,
    normalize_fuel,
    normalize_make_key,
    normalize_model_key,
    normalize_rdw_body,
    normalize_tan_base,
)
from tools.open_vehicle_data.privacy import assert_no_pii, forbidden_keys_present
from tools.open_vehicle_data.rdw_aggregate import aggregate_rdw_rows, sanitize_rdw_row
from tools.open_vehicle_data.vehiclesdb_identity import nameplate_rows, split_payloads

ALIASES = {
    ("bmw", "320i"): ("bmw", "3 series"),
    ("bmw", "330e"): ("bmw", "3 series"),
}


def _cfg(**overrides):
    row = {
        "make_key": "skoda",
        "model_key": "octavia",
        "year_min": 2018,
        "year_max": 2018,
        "fuel_type": "petrol",
        "engine_displacement_cm3": 1395,
        "power_kw": 110,
        "body_type_rdw": "wagon",
        "configuration_key": "5e|acdada|nfm6",
    }
    row.update(overrides)
    return row


class NormalizeTest(unittest.TestCase):
    def test_skoda_diacritic_and_vw_alias(self):
        self.assertEqual(normalize_make_key("Škoda"), "skoda")
        self.assertEqual(normalize_make_key("VW"), "volkswagen")
        self.assertEqual(normalize_make_key("Mercedes-Benz"), "mercedesbenz")
        self.assertEqual(normalize_make_key("Mercedes Benz"), "mercedesbenz")

    def test_tan_revision_stripped(self):
        self.assertEqual(
            normalize_tan_base("e11*2007/46*0243*25"),
            "e11*2007/46*0243",
        )
        self.assertEqual(
            normalize_tan_base("E2*2001/116*0314*88"),
            "e2*2001/116*0314",
        )

    def test_tvv_key_casefold(self):
        self.assertEqual(
            configuration_key("5E", "ACDADAX0", "NFM6FM62S022STVLN687"),
            configuration_key("5e", "acdadax0", "nfm6fm62s022stvln687"),
        )

    def test_fuel_matrix(self):
        self.assertEqual(normalize_fuel("PETROL", "M"), "petrol")
        self.assertEqual(normalize_fuel("DIESEL", "M"), "diesel")
        self.assertEqual(normalize_fuel("PETROL", "H"), "hybrid")
        self.assertEqual(normalize_fuel("PETROL/ELECTRIC", "P"), "plug_in_hybrid")
        self.assertEqual(normalize_fuel("ELECTRIC", "E"), "electric")
        self.assertEqual(normalize_fuel("LPG", "M"), "lpg")
        self.assertEqual(normalize_fuel("NG", "M"), "cng")
        self.assertIsNone(normalize_fuel("LPG", "B"))
        self.assertIsNone(normalize_fuel("UNKNOWN", "M"))
        self.assertIsNone(normalize_fuel("PETROL", "P"))

    def test_displacement_not_rounded(self):
        self.assertEqual(cm3_to_liters(1998), 1.998)
        self.assertIsNone(cm3_to_liters(None))

    def test_kw_to_hp_not_averaged(self):
        self.assertEqual(kw_to_hp(110), 150)

    def test_pre_normalized_rdw_body_roundtrip(self):
        self.assertEqual(normalize_rdw_body(inrichting="wagon"), "wagon")
        self.assertEqual(normalize_rdw_body(inrichting="sedan"), "sedan")
        self.assertEqual(normalize_rdw_body(inrichting="suv"), "suv")


class PrivacyTest(unittest.TestCase):
    def test_plate_rejected(self):
        with self.assertRaises(ValueError):
            sanitize_rdw_row(
                {
                    "kenteken": "XX123X",
                    "type_code": "5E",
                    "variant_code": "A",
                    "version_code": "B",
                }
            )

    def test_vin_detected(self):
        self.assertEqual(forbidden_keys_present({"VIN": "WVWZZZ"}), {"vin"})
        assert_no_pii({"type_code": "5E", "variant_code": "A", "version_code": "B"})


class EeaRdwJoinTest(unittest.TestCase):
    def test_aggregate_collapses_registrations(self):
        rows = [
            {
                "make": "SKODA",
                "model": "OCTAVIA",
                "year": 2018,
                "tan": "e8*2007/46*0318*00",
                "type_code": "5E",
                "variant_code": "ACDDYAX0",
                "version_code": "NFM5A",
                "ft": "Diesel",
                "fm": "M",
                "ec_cm3": 1598,
                "ep_kw": 85,
                "status": "F",
            },
            {
                "make": "Skoda",
                "model": "OCTAVIA",
                "year": 2018,
                "tan": "e8*2007/46*0318*03",
                "type_code": "5E",
                "variant_code": "ACDDYAX0",
                "version_code": "NFM5A",
                "ft": "DIESEL",
                "fm": "M",
                "ec_cm3": 1598,
                "ep_kw": 85,
                "status": "F",
            },
        ]
        aggregated = aggregate_eea_rows(rows)
        self.assertEqual(len(aggregated), 1)
        self.assertEqual(aggregated[0]["observation_count"], 2)
        self.assertEqual(aggregated[0]["tan_base"], "e8*2007/46*0318")
        self.assertEqual(aggregated[0]["fuel_type"], "diesel")

    def test_provisional_dropped_when_finalized_exists(self):
        rows = [
            {
                "make": "SKODA",
                "model": "OCTAVIA",
                "year": 2018,
                "tan": "e8*2007/46*0318*00",
                "type_code": "5E",
                "variant_code": "ACDDYAX0",
                "version_code": "NFM5A",
                "ft": "Diesel",
                "fm": "M",
                "ec_cm3": 1598,
                "ep_kw": 85,
                "status": "F",
            },
            {
                "make": "SKODA",
                "model": "OCTAVIA",
                "year": 2018,
                "tan": "e8*2007/46*0318*00",
                "type_code": "5E",
                "variant_code": "ACDDYAX0",
                "version_code": "NFM5A",
                "ft": "Diesel",
                "fm": "M",
                "ec_cm3": 1598,
                "ep_kw": 85,
                "status": "P",
            },
        ]
        aggregated = aggregate_eea_rows(rows)
        self.assertEqual(len(aggregated), 1)
        self.assertEqual(aggregated[0]["observation_count"], 1)

    def test_idempotent_aggregate(self):
        rows = [
            {
                "make": "TESLA",
                "model": "MODEL 3",
                "year": 2021,
                "tan": "E4*2007/46*1293*15",
                "type_code": "003",
                "variant_code": "E6R",
                "version_code": "PGb1s5N",
                "ft": "ELECTRIC",
                "fm": "E",
                "ec_cm3": None,
                "ep_kw": 100,
                "status": "F",
            }
        ]
        a = aggregate_eea_rows(rows)
        b = aggregate_eea_rows(rows)
        self.assertEqual(a[0]["configuration_key"], b[0]["configuration_key"])
        self.assertIsNone(a[0]["engine_displacement_cm3"])

    def test_tvv_join_octavia_logan_x5(self):
        eea = configuration_key("5E", "ACDADAX0", "NFM6FM62S022STVLN687")
        rdw = configuration_key("5E", "ACDADAX0", "NFM6FM62S022STVLN687")
        self.assertEqual(eea, rdw)
        self.assertEqual(
            configuration_key("SD", "07ES", "JR5CJ000M500"),
            configuration_key("sd", "07ES", "JR5CJ000M500"),
        )
        self.assertEqual(
            configuration_key("G5X", "TA61", "DAA50900"),
            configuration_key("G5X", "TA61", "DAA50900"),
        )

    def test_rdw_aggregate_drops_to_tvv(self):
        rows = [
            {
                "type_code": "5E",
                "variant_code": "AC",
                "version_code": "V1",
                "carrosserietype": "AA",
                "eu_description": "Sedan",
                "inrichting": "sedan",
            },
            {
                "type_code": "5E",
                "variant_code": "AC",
                "version_code": "V1",
                "carrosserietype": "AC",
                "eu_description": "Stationwagen",
                "inrichting": "stationwagen",
            },
        ]
        out = aggregate_rdw_rows(rows)
        self.assertEqual(len(out), 1)
        self.assertEqual(out[0]["body_class_count"], 2)
        self.assertIsNone(out[0]["body_type_rdw"])
        self.assertNotIn("kenteken", json.dumps(out))


class ConsensusTest(unittest.TestCase):
    def test_null_prevents_consensus(self):
        rows = [
            _cfg(fuel_type="petrol"),
            _cfg(fuel_type=None, configuration_key="other"),
        ]
        result = resolve_mmy(
            make="Skoda",
            model="Octavia",
            year=2018,
            configurations=rows,
        )
        self.assertIsNone(result["consensusSpecs"]["fuelType"])

    def test_source_conflict_null(self):
        rows = [
            _cfg(fuel_type="petrol"),
            _cfg(fuel_type="diesel", configuration_key="other"),
        ]
        result = resolve_mmy(
            make="Skoda",
            model="Octavia",
            year=2018,
            configurations=rows,
        )
        self.assertIsNone(result["consensusSpecs"]["fuelType"])
        self.assertEqual(result["clarification"]["attribute"], "fuel")

    def test_octavia_asks_body(self):
        rows = [
            _cfg(body_type_rdw="sedan", fuel_type="petrol"),
            _cfg(
                body_type_rdw="wagon",
                fuel_type="diesel",
                configuration_key="other",
            ),
        ]
        result = resolve_mmy(
            make="Škoda",
            model="Octavia",
            year=2018,
            configurations=rows,
            nameplate_bodies=["hatchback", "wagon"],
        )
        self.assertEqual(result["clarification"]["attribute"], "body")
        self.assertIsNone(result["consensusSpecs"]["bodyType"])
        self.assertIsNone(result["consensusSpecs"]["transmissionType"])
        self.assertIsNone(result["consensusSpecs"]["drivetrain"])

    def test_tucson_body_from_nameplate_fuel_question(self):
        rows = [
            _cfg(
                make_key="hyundai",
                model_key="tucson",
                year_min=2021,
                year_max=2021,
                fuel_type="petrol",
                body_type_rdw="wagon",
            ),
            _cfg(
                make_key="hyundai",
                model_key="tucson",
                year_min=2021,
                year_max=2021,
                fuel_type="hybrid",
                configuration_key="h",
                body_type_rdw="wagon",
            ),
        ]
        result = resolve_mmy(
            make="Hyundai",
            model="Tucson",
            year=2021,
            configurations=rows,
            nameplate_bodies=["suv"],
        )
        self.assertEqual(result["consensusSpecs"]["bodyType"], "suv")
        self.assertEqual(result["clarification"]["attribute"], "fuel")

    def test_model_3_electric_sedan_no_question(self):
        rows = [
            _cfg(
                make_key="tesla",
                model_key="model 3",
                year_min=2021,
                year_max=2021,
                fuel_type="electric",
                engine_displacement_cm3=None,
                power_kw=100,
                body_type_rdw="sedan",
            ),
            _cfg(
                make_key="tesla",
                model_key="model 3",
                year_min=2021,
                year_max=2021,
                fuel_type="electric",
                engine_displacement_cm3=None,
                power_kw=155,
                configuration_key="other",
                body_type_rdw="sedan",
            ),
        ]
        result = resolve_mmy(
            make="Tesla",
            model="Model 3",
            year=2021,
            configurations=rows,
            nameplate_bodies=["sedan"],
        )
        self.assertEqual(result["consensusSpecs"]["fuelType"], "electric")
        self.assertEqual(result["consensusSpecs"]["bodyType"], "sedan")
        self.assertIsNone(result["consensusSpecs"]["engineDisplacementLiters"])
        self.assertIsNone(result["consensusSpecs"]["enginePowerHp"])
        self.assertIsNone(result["clarification"])

    def test_bmw_does_not_infer_xdrive(self):
        rows = [
            _cfg(
                make_key="bmw",
                model_key="3 series",
                year_min=2020,
                year_max=2020,
                fuel_type="petrol",
                body_type_rdw="sedan",
            ),
            _cfg(
                make_key="bmw",
                model_key="3 series",
                year_min=2020,
                year_max=2020,
                fuel_type="diesel",
                body_type_rdw="wagon",
                configuration_key="touring",
            ),
        ]
        result = resolve_mmy(
            make="BMW",
            model="320i",
            year=2020,
            configurations=rows,
            nameplate_bodies=["sedan", "wagon"],
            aliases=ALIASES,
        )
        self.assertEqual(result["identity"]["modelKey"], "3 series")
        self.assertEqual(result["clarification"]["attribute"], "body")
        self.assertIsNone(result["consensusSpecs"]["drivetrain"])

    def test_nodata_tiggo(self):
        result = resolve_mmy(
            make="Chery",
            model="Tiggo 7",
            year=2019,
            configurations=[],
            nameplate_bodies=["hatchback", "wagon"],
        )
        self.assertEqual(result["status"], "noData")

    def test_year_tolerance(self):
        self.assertTrue(year_overlaps(2018, 2018, 2019))
        self.assertFalse(year_overlaps(2018, 2018, 2020))
        rows = [_cfg(year_min=2018, year_max=2018, fuel_type="diesel")]
        hit = resolve_mmy(
            make="Skoda", model="Octavia", year=2019, configurations=rows
        )
        miss = resolve_mmy(
            make="Skoda", model="Octavia", year=2020, configurations=rows
        )
        self.assertEqual(hit["status"], "ok")
        self.assertEqual(hit["consensusSpecs"]["fuelType"], "diesel")
        self.assertEqual(miss["status"], "noData")

    def test_answer_does_not_emit_second_question(self):
        rows = [
            _cfg(body_type_rdw="sedan", fuel_type="petrol"),
            _cfg(
                body_type_rdw="wagon",
                fuel_type="diesel",
                configuration_key="other",
            ),
        ]
        result = resolve_mmy(
            make="Skoda",
            model="Octavia",
            year=2018,
            configurations=rows,
            answer={"attribute": "body", "value": "sedan"},
        )
        self.assertEqual(result["consensusSpecs"]["bodyType"], "sedan")
        self.assertEqual(result["consensusSpecs"]["fuelType"], "petrol")
        self.assertIsNone(result["clarification"])

    def test_single_rdw_ac_not_autofill_without_nameplate(self):
        rows = [
            _cfg(make_key="volkswagen", model_key="golf", body_type_rdw="wagon"),
            _cfg(
                make_key="volkswagen",
                model_key="golf",
                body_type_rdw="wagon",
                fuel_type="diesel",
                configuration_key="d",
            ),
        ]
        result = resolve_mmy(
            make="Volkswagen",
            model="Golf",
            year=2018,
            configurations=rows,
            nameplate_bodies=["hatchback", "wagon"],
        )
        self.assertIsNone(result["consensusSpecs"]["bodyType"])
        self.assertEqual(result["clarification"]["attribute"], "body")

    def test_nameplate_body_answer_does_not_wipe_candidates(self):
        rows = [
            _cfg(make_key="volkswagen", model_key="golf", body_type_rdw="wagon"),
            _cfg(
                make_key="volkswagen",
                model_key="golf",
                body_type_rdw="wagon",
                fuel_type="diesel",
                configuration_key="d",
            ),
        ]
        result = resolve_mmy(
            make="Volkswagen",
            model="Golf",
            year=2018,
            configurations=rows,
            nameplate_bodies=["hatchback", "wagon"],
            answer={"attribute": "body", "value": "hatchback"},
        )
        self.assertEqual(result["status"], "ok")
        self.assertEqual(result["consensusSpecs"]["bodyType"], "hatchback")
        self.assertGreater(result["candidateCount"], 0)
        self.assertIsNone(result["clarification"])


class VehiclesDbTest(unittest.TestCase):
    def test_identity_only(self):
        models = [
            {
                "make_id": "skoda",
                "name": "Octavia",
                "body_types": ["hatchback", "wagon"],
                "aliases": None,
                "xrefs": {"tan": ["e8*2007/46*0318*00"]},
            }
        ]
        rows = nameplate_rows(models, source_version="2026.09.1")
        plates, aliases = split_payloads(rows)
        self.assertEqual(len(plates), 1)
        self.assertEqual(plates[0]["body_types"], ["hatchback", "wagon"])
        self.assertEqual(plates[0]["tan_bases"], ["e8*2007/46*0318"])
        self.assertEqual(aliases, [])


if __name__ == "__main__":
    unittest.main()
