"""RDW TGK Versnelling → CARZON transmission. Official IVI GearboxTypeCode only.

Does not infer drivetrain. Does not materialize the full 5.8M-row table.
"""

from __future__ import annotations

import json
import urllib.parse
import urllib.request
from collections import Counter
from collections.abc import Callable, Iterable, Iterator, Sequence
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from .acquire import ALLOWED_HOSTS, DEFAULT_CACHE
from .loader import ServiceRoleLoader
from .normalize import normalize_tan_base

TGK_MAPPING_VERSION = "m1.1"
TGK_SOURCE = "rdw_tgk_versnelling"
TGK_DATASET = "7rjk-eycs"
TGK_URL = f"https://opendata.rdw.nl/resource/{TGK_DATASET}.json"
TGK_SELECT = (
    "typegoedkeuringsnummer,codevarianttgk,codeuitvoeringtgk,"
    "volgnummerrevisieuitvoering,volgnummerversnelling,"
    "codetypeversnellingsbak,"
    "aantalversnellingenondergrens,aantalversnellingenbovengrens"
)
PAGE_SIZE = 20_000

# EU IVI Data Dictionary 1.11 (2025-04-02) GearboxTypeCode, monitored by RDW.
SAFE_GEARBOX = {
    "M": "manual",
    "A": "automatic",
    "C": "cvt",
    "D": "dual_clutch",
    "G": "robotic",
    "O": "other",
}
# Official but not semantically exact in CARZON taxonomy → null.
UNMAPPED_OFFICIAL = frozenset({"F", "H", "S", "W"})

RowFetcher = Callable[[str], list[dict[str, Any]]]


def map_tgk_gearbox(code: str | None) -> str | None:
    if code is None:
        return None
    return SAFE_GEARBOX.get(code.strip().upper())


def tvv_key(tan: str | None, variant: str | None, version: str | None) -> tuple[str, str, str] | None:
    base = normalize_tan_base(tan)
    var = (variant or "").strip().lower()
    ver = (version or "").strip().lower()
    if base is None or not var or not ver:
        return None
    return base, var, ver


def consensus_for_codes(raw_codes: Iterable[str | None]) -> dict[str, Any]:
    codes = [((c or "").strip().upper()) for c in raw_codes]
    present = [c for c in codes if c]
    mapped: list[str] = []
    unresolved = False
    for code in present:
        value = map_tgk_gearbox(code)
        if value:
            mapped.append(value)
        else:
            unresolved = True
    raw = ",".join(sorted(set(present)))
    unique = set(mapped)
    if unresolved or not unique:
        status = "unmapped" if not unique else "unresolved"
        if len(unique) > 1:
            status = "conflict"
        return {
            "transmission_type": None,
            "status": status if present else "empty",
            "raw": raw,
        }
    if len(unique) > 1:
        return {"transmission_type": None, "status": "conflict", "raw": raw}
    return {
        "transmission_type": next(iter(unique)),
        "status": "agree",
        "raw": raw,
    }


def ingest_row(key: tuple[str, str, str], decision: dict[str, Any]) -> dict[str, str | None]:
    return {
        "tan_base": key[0],
        "variant_code": key[1],
        "version_code": key[2],
        "transmission_type": decision["transmission_type"],
        "raw": decision["raw"],
    }


class TgkAggregate:
    def __init__(self) -> None:
        self.rows_read = 0
        self.skipped = 0
        self.code_counts: Counter[str] = Counter()
        self._codes: dict[tuple[str, str, str], set[str]] = {}

    def add(self, row: dict[str, Any]) -> None:
        self.rows_read += 1
        code = str(row.get("codetypeversnellingsbak") or "").strip().upper()
        self.code_counts[code or "<null>"] += 1
        key = tvv_key(
            row.get("typegoedkeuringsnummer"),
            row.get("codevarianttgk"),
            row.get("codeuitvoeringtgk"),
        )
        if key is None:
            self.skipped += 1
            return
        self._codes.setdefault(key, set()).add(code)

    def decisions(self) -> dict[tuple[str, str, str], dict[str, Any]]:
        return {key: consensus_for_codes(codes) for key, codes in self._codes.items()}

    def unique_keys(self) -> int:
        return len(self._codes)


def _http_json(url: str, timeout: int = 120) -> list[dict[str, Any]]:
    host = (urlparse(url).hostname or "").lower()
    if host not in ALLOWED_HOSTS:
        raise ValueError(f"refusing download from host={host or 'missing'}")
    request = urllib.request.Request(
        url,
        method="GET",
        headers={"User-Agent": "carzon-open-data/tgk-m1.1", "Accept": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        payload = json.loads(response.read().decode("utf-8"))
    if not isinstance(payload, list):
        raise ValueError("TGK page must be a JSON array")
    return payload


def iter_tgk_pages(
    *,
    page_size: int = PAGE_SIZE,
    max_rows: int | None = None,
    fetch: RowFetcher | None = None,
    base_url: str = TGK_URL,
    log: Callable[[str], None] | None = None,
) -> Iterator[dict[str, Any]]:
    """Offset pages. Caller must not keep the raw page list."""
    getter = fetch or _http_json
    offset = 0
    seen = 0
    while True:
        query = urllib.parse.urlencode(
            {
                "$select": TGK_SELECT,
                "$order": ":id",
                "$limit": page_size,
                "$offset": offset,
            }
        )
        page = getter(f"{base_url}?{query}")
        if not page:
            break
        for row in page:
            yield row
            seen += 1
            if max_rows is not None and seen >= max_rows:
                return
        if log is not None:
            log(f"tgk page offset={offset} page={len(page)} seen={seen}")
        if len(page) < page_size:
            break
        offset += page_size


def aggregate_tgk_rows(rows: Iterable[dict[str, Any]]) -> TgkAggregate:
    agg = TgkAggregate()
    for row in rows:
        agg.add(row)
    return agg


def join_catalog(
    decisions: dict[tuple[str, str, str], dict[str, Any]],
    catalog_keys: set[tuple[str, str, str]],
) -> list[dict[str, str | None]]:
    return [
        ingest_row(key, decisions[key])
        for key in catalog_keys
        if key in decisions
    ]


def summarize(
    agg: TgkAggregate,
    decisions: dict[tuple[str, str, str], dict[str, Any]],
    *,
    catalog_keys: set[tuple[str, str, str]] | None = None,
    matched: Sequence[dict[str, str | None]] | None = None,
) -> dict[str, Any]:
    status_counts = Counter(item["status"] for item in decisions.values())
    mapped_counts = Counter(
        item["transmission_type"]
        for item in decisions.values()
        if item["transmission_type"]
    )
    catalog_n = len(catalog_keys) if catalog_keys is not None else None
    match_n = len(matched) if matched is not None else None
    agree_n = sum(1 for row in (matched or []) if row.get("transmission_type"))
    null_n = sum(1 for row in (matched or []) if not row.get("transmission_type"))
    return {
        "mapping_version": TGK_MAPPING_VERSION,
        "source": TGK_SOURCE,
        "dataset": TGK_DATASET,
        "rows_read": agg.rows_read,
        "skipped_incomplete_tvv": agg.skipped,
        "unique_tgk_tvv": agg.unique_keys(),
        "code_distribution": dict(agg.code_counts.most_common()),
        "decision_status": dict(status_counts),
        "mapped_value_counts": dict(mapped_counts),
        "catalog_tvv_keys": catalog_n,
        "exact_tvv_matches": match_n,
        "matched_non_null": agree_n if matched is not None else None,
        "matched_null": null_n if matched is not None else None,
        "match_pct": (
            round(100.0 * match_n / catalog_n, 2)
            if catalog_n and match_n is not None
            else None
        ),
    }


def sanity_gate(report: dict[str, Any]) -> list[str]:
    """Stop hosted ingest if live TGK contradicts the T0 control picture."""
    reasons: list[str] = []
    rows = int(report.get("rows_read") or 0)
    if rows < 1_000_000:
        reasons.append(f"rows_read={rows} < 1000000")
    codes = report.get("code_distribution") or {}
    total = sum(int(v) for v in codes.values()) or 1
    m_pct = 100.0 * int(codes.get("M") or 0) / total
    a_pct = 100.0 * int(codes.get("A") or 0) / total
    if m_pct < 40 or m_pct > 75:
        reasons.append(f"M%={m_pct:.1f} outside 40-75")
    if a_pct < 25 or a_pct > 60:
        reasons.append(f"A%={a_pct:.1f} outside 25-60")
    match_pct = report.get("match_pct")
    if match_pct is not None and match_pct < 40:
        reasons.append(f"exact TVV match%={match_pct} < 40 (T0 control was 87.1)")
    return reasons


def fetch_catalog_tvv_keys(loader: ServiceRoleLoader) -> set[tuple[str, str, str]]:
    keys: set[tuple[str, str, str]] = set()
    last_id = ""
    page = 1000
    while True:
        params = {
            "select": "id,tan_base,variant_code,version_code",
            "tan_base": "not.is.null",
            "order": "id.asc",
            "limit": str(page),
        }
        if last_id:
            params["id"] = f"gt.{last_id}"
        rows = loader.rest_get("vehicle_open_data_configuration", params)
        if not rows:
            break
        for row in rows:
            key = tvv_key(row.get("tan_base"), row.get("variant_code"), row.get("version_code"))
            if key:
                keys.add(key)
            if row.get("id"):
                last_id = str(row["id"])
        if len(rows) < page:
            break
    return keys


def write_aggregate_cache(path: Any, agg: TgkAggregate, decisions: dict[tuple[str, str, str], dict[str, Any]]) -> None:
    write_decisions(path, decisions)
    meta_path = Path(path).with_suffix(".meta.json")
    meta_path.write_text(
        json.dumps(
            {
                "rows_read": agg.rows_read,
                "skipped_incomplete_tvv": agg.skipped,
                "code_distribution": dict(agg.code_counts),
                "unique_tgk_tvv": agg.unique_keys(),
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def load_aggregate_cache(path: Any) -> tuple[TgkAggregate, dict[tuple[str, str, str], dict[str, Any]]]:
    decisions = read_decisions(path)
    agg = TgkAggregate()
    meta_path = Path(path).with_suffix(".meta.json")
    if meta_path.exists():
        meta = json.loads(meta_path.read_text(encoding="utf-8"))
        agg.rows_read = int(meta.get("rows_read") or 0)
        agg.skipped = int(meta.get("skipped_incomplete_tvv") or 0)
        agg.code_counts.update(meta.get("code_distribution") or {})
        # unique keys come from decisions; _codes unused after cache load
    else:
        agg.rows_read = len(decisions)
    return agg, decisions


def write_decisions(path: Any, decisions: dict[tuple[str, str, str], dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for key, decision in decisions.items():
            handle.write(
                json.dumps(
                    {
                        "tan_base": key[0],
                        "variant_code": key[1],
                        "version_code": key[2],
                        **decision,
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )


def read_decisions(path: Any) -> dict[tuple[str, str, str], dict[str, Any]]:
    out: dict[tuple[str, str, str], dict[str, Any]] = {}
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            row = json.loads(line)
            out[(row["tan_base"], row["variant_code"], row["version_code"])] = {
                "transmission_type": row.get("transmission_type"),
                "status": row.get("status"),
                "raw": row.get("raw") or "",
            }
    return out


def ingest_tgk_transmissions(
    loader: ServiceRoleLoader,
    rows: Sequence[dict[str, str | None]],
    *,
    source_version: str,
    start_chunk: int = 0,
) -> dict[str, Any]:
    batch_id = loader.begin_batch(TGK_SOURCE, TGK_DATASET, source_version)
    ok = False
    try:
        sent = loader.send_chunks(
            "carzon_open_data_upsert_tgk_transmissions",
            list(rows),
            extra={"p_batch_id": batch_id},
            start_chunk=start_chunk,
        )
        ok = True
        return {"batch_id": batch_id, **sent, "ok": True}
    finally:
        loader.complete_batch(batch_id, len(rows) if ok else 0, ok)


def cache_report_path() -> Any:
    return DEFAULT_CACHE / "tgk_transmission_dry_run.json"
