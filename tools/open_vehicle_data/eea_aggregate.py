"""Collapse EEA registration rows to configuration facts. No dump committed."""

from __future__ import annotations

import json
from collections.abc import Iterable, Iterator
from pathlib import Path
from typing import Any

from .eea_source import infer_status_from_name, iter_eea_records
from .normalize import (
    MAPPING_VERSION,
    configuration_key,
    normalize_fuel,
    normalize_make_key,
    normalize_model_key,
    normalize_tan_base,
)

# EEA 2010–2021 finalized (F) must not be double-counted with provisional (P).
FINALIZED_YEAR_MAX = 2021

EEA_FIELDS = (
    "make",
    "model",
    "year",
    "tan",
    "type_code",
    "variant_code",
    "version_code",
    "ft",
    "fm",
    "ec_cm3",
    "ep_kw",
    "status",
)


def _int(value: Any) -> int | None:
    if value is None or value == "":
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return None


def _physical_int(value: Any, *, max_value: int) -> int | None:
    """EEA 0 / garbage numbers are missing, not a real measurement."""
    number = _int(value)
    if number is None or number <= 0 or number > max_value:
        return None
    return number


class EeaStats:
    def __init__(self) -> None:
        self.read = 0
        self.rejected = 0
        self.accepted = 0

    def as_dict(self) -> dict[str, int]:
        return {
            "source_rows_read": self.read,
            "rows_rejected": self.rejected,
            "rows_accepted": self.accepted,
        }


def collect_finalized_years(rows: Iterable[dict[str, Any]]) -> set[int]:
    years: set[int] = set()
    for raw in rows:
        if str(raw.get("status") or "").upper() != "F":
            continue
        year = _int(raw.get("year"))
        if year is not None:
            years.add(year)
    return years


def _merge_eea_row(
    buckets: dict[tuple[Any, ...], dict[str, Any]],
    raw: dict[str, Any],
    *,
    finalized_years: set[int],
    make_keys: frozenset[str] | None,
    stats: EeaStats | None,
) -> None:
    if stats is not None:
        stats.read += 1
    status = str(raw.get("status") or "").upper()
    if status and status not in {"F", "P"}:
        if stats is not None:
            stats.rejected += 1
        return
    year = _int(raw.get("year"))
    if year is None or year < 2010 or year > 2100:
        if stats is not None:
            stats.rejected += 1
        return
    if status == "P" and (year <= FINALIZED_YEAR_MAX or year in finalized_years):
        if stats is not None:
            stats.rejected += 1
        return
    cfg = configuration_key(
        raw.get("type_code"),
        raw.get("variant_code"),
        raw.get("version_code"),
    )
    make_key = normalize_make_key(raw.get("make"))
    model_key = normalize_model_key(raw.get("model"))
    if cfg is None or make_key is None or model_key is None:
        if stats is not None:
            stats.rejected += 1
        return
    if make_keys is not None and make_key not in make_keys:
        if stats is not None:
            stats.rejected += 1
        return
    fuel = normalize_fuel(raw.get("ft"), raw.get("fm"))
    displ = _physical_int(raw.get("ec_cm3"), max_value=20000)
    if fuel == "electric":
        displ = None
    power = _physical_int(raw.get("ep_kw"), max_value=2000)
    count = _int(raw.get("observation_count"))
    if count is None or count < 1:
        count = 1
    key = (cfg, make_key, model_key)
    bucket = buckets.get(key)
    if stats is not None:
        stats.accepted += 1
    if bucket is None:
        buckets[key] = {
            "configuration_key": cfg,
            "type_code": (raw.get("type_code") or "").strip() or None,
            "variant_code": (raw.get("variant_code") or "").strip() or None,
            "version_code": (raw.get("version_code") or "").strip() or None,
            "tan_base": normalize_tan_base(raw.get("tan")),
            "make": raw.get("make"),
            "model": raw.get("model"),
            "make_key": make_key,
            "model_key": model_key,
            "year_min": year,
            "year_max": year,
            "year_basis": "registration",
            "fuel_type": fuel,
            "engine_displacement_cm3": displ,
            "power_kw": power,
            "observation_count": count,
            "mapping_version": MAPPING_VERSION,
            "ft": raw.get("ft"),
            "fm": raw.get("fm"),
            "tan": raw.get("tan"),
        }
        return
    bucket["year_min"] = min(bucket["year_min"], year)
    bucket["year_max"] = max(bucket["year_max"], year)
    bucket["observation_count"] += count
    if bucket["fuel_type"] != fuel and fuel is not None and bucket["fuel_type"] is not None:
        bucket["fuel_type"] = None
    elif bucket["fuel_type"] is None:
        bucket["fuel_type"] = fuel
    if (
        bucket["engine_displacement_cm3"] != displ
        and displ is not None
        and bucket["engine_displacement_cm3"] is not None
    ):
        bucket["engine_displacement_cm3"] = None
    elif bucket["engine_displacement_cm3"] is None:
        bucket["engine_displacement_cm3"] = displ
    if bucket["power_kw"] != power and power is not None and bucket["power_kw"] is not None:
        bucket["power_kw"] = None
    elif bucket["power_kw"] is None:
        bucket["power_kw"] = power
    if bucket.get("tan_base") is None:
        bucket["tan_base"] = normalize_tan_base(raw.get("tan"))


def aggregate_eea_stream(
    rows: Iterable[dict[str, Any]],
    *,
    finalized_years: set[int],
    make_keys: frozenset[str] | None = None,
    stats: EeaStats | None = None,
) -> list[dict[str, Any]]:
    """Aggregate a stream. Caller supplies finalized years; raw rows are not stored."""
    buckets: dict[tuple[Any, ...], dict[str, Any]] = {}
    for raw in rows:
        _merge_eea_row(
            buckets,
            raw,
            finalized_years=finalized_years,
            make_keys=make_keys,
            stats=stats,
        )
    return list(buckets.values())


def aggregate_eea_rows(
    rows: Iterable[dict[str, Any]],
    *,
    make_keys: frozenset[str] | None = None,
) -> list[dict[str, Any]]:
    """In-memory helper for tests. Production must use aggregate_eea_file()."""
    materialized = list(rows)
    finalized_years = collect_finalized_years(materialized)
    return aggregate_eea_stream(
        materialized,
        finalized_years=finalized_years,
        make_keys=make_keys,
    )


def collect_finalized_years_from_paths(
    paths: Iterable[Path],
    *,
    status_override: str | None = None,
) -> set[int]:
    years: set[int] = set()
    for path in paths:
        hint = status_override or infer_status_from_name(path.name)
        if hint == "P":
            continue
        years |= collect_finalized_years(
            iter_eea_records(path, status_override=status_override)
        )
    return years


def aggregate_eea_paths(
    paths: Iterable[Path],
    *,
    make_keys: frozenset[str] | None = None,
    status_override: str | None = None,
    stats: EeaStats | None = None,
) -> list[dict[str, Any]]:
    """Multi-file/year stream. F years collected first so P cannot double-count."""
    materialized_paths = list(paths)
    if status_override == "P":
        finalized_years: set[int] = set()
    else:
        finalized_years = collect_finalized_years_from_paths(
            materialized_paths,
            status_override=status_override,
        )
    buckets: dict[tuple[Any, ...], dict[str, Any]] = {}
    for path in materialized_paths:
        for raw in iter_eea_records(path, status_override=status_override):
            _merge_eea_row(
                buckets,
                raw,
                finalized_years=finalized_years,
                make_keys=make_keys,
                stats=stats,
            )
    return list(buckets.values())


def aggregate_eea_file(
    path: Path,
    *,
    make_keys: frozenset[str] | None = None,
    status_override: str | None = None,
    stats: EeaStats | None = None,
) -> list[dict[str, Any]]:
    """Two sequential reads. Memory is buckets only, not the raw registration dump."""
    return aggregate_eea_paths(
        [path],
        make_keys=make_keys,
        status_override=status_override,
        stats=stats,
    )


def iter_chunked(
    rows: Iterable[dict[str, Any]],
    size: int,
) -> Iterator[list[dict[str, Any]]]:
    if size <= 0:
        raise ValueError("chunk size must be positive")
    chunk: list[dict[str, Any]] = []
    for row in rows:
        chunk.append(row)
        if len(chunk) >= size:
            yield chunk
            chunk = []
    if chunk:
        yield chunk


def upsert_payload(aggregated: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    payload = []
    for row in aggregated:
        payload.append(
            {
                "type_code": row.get("type_code"),
                "variant_code": row.get("variant_code"),
                "version_code": row.get("version_code"),
                "tan": row.get("tan"),
                "make": row.get("make"),
                "model": row.get("model"),
                "year": row.get("year_min"),
                "year_min": row.get("year_min"),
                "year_max": row.get("year_max"),
                "ft": row.get("ft"),
                "fm": row.get("fm"),
                "ec_cm3": row.get("engine_displacement_cm3"),
                "ep_kw": row.get("power_kw"),
                "observation_count": row.get("observation_count", 1),
            }
        )
    return payload


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def write_jsonl(path: Path, rows: Iterable[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, ensure_ascii=False) + "\n")
