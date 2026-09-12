"""Official H2 source fetch. Writes gitignored cache only. No hosted writes."""

from __future__ import annotations

import csv
import hashlib
import json
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

from .acquire import (
    DEFAULT_CACHE,
    DISCODATA_SQL,
    VEHICLESDB_ATTRIBUTION,
    VEHICLESDB_MAKES,
    VEHICLESDB_MANIFEST,
    VEHICLESDB_MODELS,
    assert_allowed_url,
    discodata_query,
    fetch_json,
    stream_http,
)

CACHE = DEFAULT_CACHE
UA = {"User-Agent": "carzon-open-data/h2"}

MAKE_PATTERNS = (
    "SKODA%",
    "VOLKSWAGEN%",
    "VW",
    "BMW%",
    "MERCEDES%",
    "HYUNDAI%",
    "KIA%",
    "TOYOTA%",
    "DACIA%",
    "TESLA%",
    "BYD%",
)

EEA_SOURCES = (
    ("[CO2Emission].[latest].[co2cars]", "F", list(range(2010, 2022)), "co2cars_F_2010_2021"),
    ("[CO2Emission].[latest].[co2cars_2022Fv26]", "F", [2022], "co2cars_2022Fv26"),
    ("[CO2Emission].[latest].[co2cars_2023Fv28]", "F", [2023], "co2cars_2023Fv28"),
    ("[CO2Emission].[latest].[co2cars_2024Fv30]", "F", [2024], "co2cars_2024Fv30"),
    ("[CO2Emission].[latest].[co2cars_2025Pv31]", "P", [2025], "co2cars_2025Pv31"),
)

RDW_MERKS = (
    "SKODA",
    "VOLKSWAGEN",
    "BMW",
    "MERCEDES-BENZ",
    "HYUNDAI",
    "KIA",
    "TOYOTA",
    "DACIA",
    "TESLA",
    "BYD",
)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _http_json(url: str, timeout: int = 180) -> object:
    assert_allowed_url(url)
    request = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def fetch_eea(dest: Path) -> dict:
    dest.parent.mkdir(parents=True, exist_ok=True)
    written = 0
    pages = 0
    with dest.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "Mk",
                "Cn",
                "Year",
                "Tan",
                "T",
                "Va",
                "Ve",
                "Ft",
                "Fm",
                "Ec",
                "Ep",
                "status",
                "observation_count",
            ],
        )
        writer.writeheader()
        for table, status, years, dataset in EEA_SOURCES:
            for year in years:
                for pattern in MAKE_PATTERNS:
                    clause = (
                        f"UPPER(Mk) = 'VW'"
                        if pattern == "VW"
                        else f"UPPER(Mk) LIKE '{pattern}'"
                    )
                    query = f"""
SELECT Mk, Cn, [Year], TAN, T, Va, Ve, Ft, Fm, [Ec (cm3)], [Ep (KW)], Status, COUNT(*) AS cnt
FROM {table}
WHERE Status = '{status}' AND [Year] = {year} AND {clause}
GROUP BY Mk, Cn, [Year], TAN, T, Va, Ve, Ft, Fm, [Ec (cm3)], [Ep (KW)], Status
""".strip()
                    page = 1
                    while True:
                        data = discodata_query(query, page=page, page_size=10000)
                        if data.get("errors"):
                            raise RuntimeError(
                                f"{dataset} {year} {pattern} page {page}: {data['errors']}"
                            )
                        rows = data.get("results") or []
                        pages += 1
                        for raw in rows:
                            writer.writerow(
                                {
                                    "Mk": raw.get("Mk"),
                                    "Cn": raw.get("Cn"),
                                    "Year": raw.get("Year"),
                                    "Tan": raw.get("TAN"),
                                    "T": raw.get("T"),
                                    "Va": raw.get("Va"),
                                    "Ve": raw.get("Ve"),
                                    "Ft": raw.get("Ft"),
                                    "Fm": raw.get("Fm"),
                                    "Ec": raw.get("Ec (cm3)"),
                                    "Ep": raw.get("Ep (KW)"),
                                    "status": raw.get("Status") or status,
                                    "observation_count": raw.get("cnt") or 1,
                                }
                            )
                            written += 1
                        if len(rows) < 10000:
                            break
                        page += 1
                    time.sleep(0.05)
    return {
        "path": str(dest),
        "rows": written,
        "pages": pages,
        "bytes": dest.stat().st_size,
        "sha256": _sha256(dest),
    }


def fetch_rdw(dest: Path) -> dict:
    dest.parent.mkdir(parents=True, exist_ok=True)
    merks = ",".join(f"'{item}'" for item in RDW_MERKS)
    written = 0
    offset = 0
    limit = 50000
    with dest.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "type",
                "variant",
                "uitvoering",
                "typegoedkeuringsnummer",
                "inrichting",
                "merk",
            ],
        )
        writer.writeheader()
        while True:
            params = {
                "$select": "type,variant,uitvoering,typegoedkeuringsnummer,inrichting,merk,count(*)",
                "$group": "type,variant,uitvoering,typegoedkeuringsnummer,inrichting,merk",
                "$where": f"merk in({merks})",
                "$limit": str(limit),
                "$offset": str(offset),
            }
            url = "https://opendata.rdw.nl/resource/m9d7-ebf2.json?" + urllib.parse.urlencode(params)
            rows = _http_json(url)
            if not isinstance(rows, list) or not rows:
                break
            for raw in rows:
                writer.writerow(
                    {
                        "type": raw.get("type"),
                        "variant": raw.get("variant"),
                        "uitvoering": raw.get("uitvoering"),
                        "typegoedkeuringsnummer": raw.get("typegoedkeuringsnummer"),
                        "inrichting": raw.get("inrichting"),
                        "merk": raw.get("merk"),
                    }
                )
                written += 1
            if len(rows) < limit:
                break
            offset += limit
    return {
        "path": str(dest),
        "rows": written,
        "bytes": dest.stat().st_size,
        "sha256": _sha256(dest),
    }


def fetch_vehiclesdb(dest_dir: Path) -> dict:
    dest_dir.mkdir(parents=True, exist_ok=True)
    paths = {
        "models": dest_dir / "models.json",
        "makes": dest_dir / "makes.json",
        "manifest": dest_dir / "manifest.json",
        "attribution": dest_dir / "ATTRIBUTION.md",
    }
    stream_http(VEHICLESDB_MODELS, paths["models"])
    stream_http(VEHICLESDB_MAKES, paths["makes"])
    stream_http(VEHICLESDB_MANIFEST, paths["manifest"])
    stream_http(VEHICLESDB_ATTRIBUTION, paths["attribution"])
    manifest = json.loads(paths["manifest"].read_text(encoding="utf-8"))
    models = json.loads(paths["models"].read_text(encoding="utf-8"))
    makes = json.loads(paths["makes"].read_text(encoding="utf-8"))
    wrapped = dest_dir / "vehiclesdb_open.json"
    wrapped.write_text(
        json.dumps(
            {
                "source_version": manifest.get("version"),
                "attribution": manifest.get("attribution"),
                "models": models,
                "makes": makes,
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    return {
        "version": manifest.get("version"),
        "built_at": manifest.get("built_at"),
        "license": manifest.get("license"),
        "models_bytes": paths["models"].stat().st_size,
        "models_sha256": _sha256(paths["models"]),
        "wrapped": str(wrapped),
    }


def main() -> int:
    CACHE.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).isoformat()
    meta = {
        "acquired_at": stamp,
        "eea": None,
        "rdw": None,
        "vehiclesdb": None,
    }
    print("fetch vehiclesdb", flush=True)
    meta["vehiclesdb"] = fetch_vehiclesdb(CACHE / "vehiclesdb")
    print("fetch rdw", flush=True)
    meta["rdw"] = fetch_rdw(CACHE / "rdw_grouped.csv")
    print("fetch eea", flush=True)
    meta["eea"] = fetch_eea(CACHE / "eea_grouped.csv")
    (CACHE / "h2_source_metadata.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(meta, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
