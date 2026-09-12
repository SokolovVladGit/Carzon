"""Official-source acquisition. Streaming copy only. No catalog ingest."""

from __future__ import annotations

import json
import shutil
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

# Official portals. Downloads are opt-in via CLI --url. Unit tests never call HTTP.
EEA_PORTAL = (
    "https://www.eea.europa.eu/en/datahub/datahubitem-view/"
    "fa8b1229-3db6-495d-b18e-9c9b3267c02b"
)
EEA_FORMATS = ("csv", "tsv", "zip")
EEA_COLUMNS = ("Mk", "Cn", "Year|r", "Tan", "T", "Va", "Ve", "Ft", "Fm", "Ec", "Ep", "Status")

RDW_VEHICLES_CSV = "https://opendata.rdw.nl/resource/m9d7-ebf2.csv"
RDW_BODIES_CSV = "https://opendata.rdw.nl/resource/vezc-m2t6.csv"
RDW_TGK_VERSNELLING = "https://opendata.rdw.nl/resource/7rjk-eycs.json"
RDW_VEHICLE_SELECT = (
    "kenteken,type,variant,uitvoering,typegoedkeuringsnummer,inrichting"
)
RDW_BODY_SELECT = "kenteken,carrosserie_voertuig_nummer_europees"

ALLOWED_HOSTS = frozenset(
    {
        "opendata.rdw.nl",
        "data.overheid.nl",
        "www.eea.europa.eu",
        "sdi.eea.europa.eu",
        "discomap.eea.europa.eu",
        "discodata.eea.europa.eu",
        "raw.githubusercontent.com",
        "cdn.jsdelivr.net",
        "github.com",
    }
)

DISCODATA_SQL = "https://discodata.eea.europa.eu/sql"
EEA_TABLE = "[CO2Emission].[latest].[co2cars]"
VEHICLESDB_MODELS = (
    "https://raw.githubusercontent.com/vehiclesdb/vehiclesdb/main/catalog/car/models.json"
)
VEHICLESDB_MAKES = (
    "https://raw.githubusercontent.com/vehiclesdb/vehiclesdb/main/catalog/car/makes.json"
)
VEHICLESDB_MANIFEST = (
    "https://raw.githubusercontent.com/vehiclesdb/vehiclesdb/main/manifest.json"
)
VEHICLESDB_ATTRIBUTION = (
    "https://raw.githubusercontent.com/vehiclesdb/vehiclesdb/main/ATTRIBUTION.md"
)

DEFAULT_CACHE = Path(__file__).resolve().parent / ".cache"


def assert_allowed_url(url: str) -> None:
    host = (urlparse(url).hostname or "").lower()
    if host not in ALLOWED_HOSTS:
        raise ValueError(f"refusing download from host={host or 'missing'}")


def stream_copy(source: Path, dest: Path) -> Path:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with source.open("rb") as src, dest.open("wb") as out:
        shutil.copyfileobj(src, out, length=1024 * 1024)
    return dest


def stream_http(url: str, dest: Path) -> Path:
    """Chunked download to dest. Not used by unit tests."""
    assert_allowed_url(url)
    dest.parent.mkdir(parents=True, exist_ok=True)
    request = urllib.request.Request(url, method="GET", headers={"User-Agent": "carzon-open-data/h2"})
    with urllib.request.urlopen(request, timeout=180) as response, dest.open("wb") as out:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            out.write(chunk)
    return dest


def fetch_json(url: str) -> object:
    assert_allowed_url(url)
    request = urllib.request.Request(url, method="GET", headers={"User-Agent": "carzon-open-data/h2"})
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.loads(response.read().decode("utf-8"))


def discodata_query(query: str, *, page: int = 1, page_size: int = 10000) -> dict:
    from urllib.parse import urlencode

    params = urlencode({"query": query, "p": str(page), "nrOfHits": str(page_size)})
    url = f"{DISCODATA_SQL}?{params}"
    assert_allowed_url(url)
    request = urllib.request.Request(url, method="GET", headers={"User-Agent": "carzon-open-data/h2"})
    with urllib.request.urlopen(request, timeout=180) as response:
        return json.loads(response.read().decode("utf-8"))


EEA_MAKE_SQL = """(
    UPPER(REPLACE(Mk,' ','')) IN (
        'SKODA','VOLKSWAGEN','VW','BMW','MERCEDESBENZ','MERCEDES-BENZ',
        'HYUNDAI','KIA','TOYOTA','DACIA','TESLA','BYD'
    )
    OR UPPER(Mk) LIKE 'SKODA%'
    OR UPPER(Mk) LIKE 'VOLKSWAGEN%'
    OR UPPER(Mk) LIKE 'MERCEDES%'
    OR UPPER(Mk) LIKE 'TESLA%'
    OR UPPER(Mk) LIKE 'BYD%'
)"""


def eea_grouped_query(status: str) -> str:
    return f"""
SELECT Mk, Cn, [Year], Tan, T, Va, Ve, Ft, Fm, Ec, Ep, Status, COUNT(*) AS cnt
FROM {EEA_TABLE}
WHERE Status = '{status}'
  AND {EEA_MAKE_SQL}
GROUP BY Mk, Cn, [Year], Tan, T, Va, Ve, Ft, Fm, Ec, Ep, Status
""".strip()
