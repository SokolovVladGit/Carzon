"""Official RDW Open Data adapter. Drops plate/VIN/owner before any persist."""

from __future__ import annotations

import csv
import io
import json
import sqlite3
import tempfile
from collections.abc import Iterator
from pathlib import Path
from typing import Any, TextIO

from .privacy import FORBIDDEN_KEYS, assert_no_pii

# Official RDW gekentekende_voertuigen / carrosserie column names.
_OFFICIAL = {
    "type": "type_code",
    "variant": "variant_code",
    "uitvoering": "version_code",
    "typegoedkeuringsnummer": "tan",
    "carrosserietype": "carrosserietype",
    "carrosserie_eu": "carrosserietype",
    "carrosserieeu": "carrosserietype",
    "inrichting": "inrichting",
    "eu_description": "eu_description",
    "carrosserie_voertuig_nummer_europees": "carrosserietype",
    "carrosserie_voertuig_nummer_code_europees": "carrosserietype",
    "merk": "make",
}

_INTERNAL = {
    "type_code",
    "variant_code",
    "version_code",
    "tan",
    "carrosserietype",
    "eu_description",
    "inrichting",
    "make",
}


def drop_forbidden(raw: dict[str, Any]) -> dict[str, Any]:
    return {
        key: value
        for key, value in raw.items()
        if str(key).strip().lower() not in FORBIDDEN_KEYS
    }


def project_rdw_row(raw: dict[str, Any]) -> dict[str, Any] | None:
    """Project official/internal RDW rows. Plate/VIN/owner never leave this function."""
    cleaned = drop_forbidden(raw)
    projected: dict[str, Any] = {}
    for key, value in cleaned.items():
        header = str(key).strip().lower().replace("\ufeff", "")
        if header in _OFFICIAL:
            projected[_OFFICIAL[header]] = value
        elif header in _INTERNAL:
            projected[header] = value
    assert_no_pii(projected, context="rdw")
    if not (
        projected.get("type_code")
        or projected.get("variant_code")
        or projected.get("version_code")
    ):
        return None
    return projected


def _dict_reader(handle: TextIO) -> csv.DictReader:
    sample = handle.read(8192)
    rewindable = True
    try:
        handle.seek(0)
    except (OSError, io.UnsupportedOperation):
        rewindable = False
    if not rewindable:
        handle = io.StringIO(sample + handle.read())
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters=",;\t|")
    except csv.Error:
        dialect = csv.excel
    return csv.DictReader(handle, dialect=dialect)


def _norm_header(name: str) -> str:
    return str(name).strip().lower().replace("\ufeff", "")


def iter_raw_rdw_rows(path: Path) -> Iterator[dict[str, Any]]:
    """Raw official rows. Caller must drop forbidden keys before persist."""
    suffix = path.suffix.lower()
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        if suffix == ".jsonl":
            for line in handle:
                if not line.strip():
                    continue
                raw = json.loads(line)
                if isinstance(raw, dict):
                    yield raw
            return
        reader = _dict_reader(handle)
        if not reader.fieldnames:
            return
        for raw in reader:
            yield raw


def _iter_csv(handle: TextIO) -> Iterator[dict[str, Any]]:
    reader = _dict_reader(handle)
    if not reader.fieldnames:
        return
    for raw in reader:
        row = project_rdw_row(raw)
        if row is not None:
            yield row


def _iter_jsonl(handle: TextIO) -> Iterator[dict[str, Any]]:
    for line in handle:
        if not line.strip():
            continue
        raw = json.loads(line)
        if not isinstance(raw, dict):
            continue
        row = project_rdw_row(raw)
        if row is not None:
            yield row


def _plate_value(raw: dict[str, Any]) -> str | None:
    for key, value in raw.items():
        if _norm_header(key) in {"kenteken", "license_plate", "licence_plate"}:
            text = str(value or "").strip().upper()
            return text or None
    return None


def _make_allowed(raw: dict[str, Any], make_keys: frozenset[str] | None) -> bool:
    if make_keys is None:
        return True
    from .normalize import normalize_make_key

    make = raw.get("make") or raw.get("merk")
    if make is None or str(make).strip() == "":
        return True
    key = normalize_make_key(str(make))
    return key in make_keys


def iter_rdw_records(
    path: Path,
    *,
    make_keys: frozenset[str] | None = None,
) -> Iterator[dict[str, Any]]:
    for raw in iter_raw_rdw_rows(path):
        if not _make_allowed(raw, make_keys):
            continue
        row = project_rdw_row(raw)
        if row is not None:
            yield row


def iter_rdw_joined(
    vehicles_path: Path,
    bodies_path: Path,
) -> Iterator[dict[str, Any]]:
    """Transient plate join. Plate never appears in yielded rows or leftover files."""
    tmp = tempfile.NamedTemporaryFile(prefix="carzon-rdw-join-", suffix=".sqlite", delete=True)
    conn = sqlite3.connect(tmp.name)
    try:
        conn.execute(
            "create table bodies (plate text primary key, carrosserietype text, inrichting text)"
        )
        for raw in iter_raw_rdw_rows(bodies_path):
            plate = _plate_value(raw)
            if not plate:
                continue
            projected = drop_forbidden(raw)
            carrosserie = None
            inrichting = None
            for key, value in projected.items():
                header = _norm_header(key)
                mapped = _OFFICIAL.get(header, header if header in _INTERNAL else None)
                if mapped == "carrosserietype" and value:
                    carrosserie = value
                elif mapped == "inrichting" and value:
                    inrichting = value
            conn.execute(
                "insert or replace into bodies(plate, carrosserietype, inrichting) values (?,?,?)",
                (plate, carrosserie, inrichting),
            )
        conn.commit()
        for raw in iter_raw_rdw_rows(vehicles_path):
            plate = _plate_value(raw)
            merged = drop_forbidden(raw)
            if plate:
                hit = conn.execute(
                    "select carrosserietype, inrichting from bodies where plate = ?",
                    (plate,),
                ).fetchone()
                if hit:
                    if hit[0] and "carrosserietype" not in merged:
                        merged["carrosserietype"] = hit[0]
                    if hit[1] and "inrichting" not in merged:
                        merged["inrichting"] = hit[1]
            row = project_rdw_row(merged)
            if row is not None:
                yield row
    finally:
        conn.close()
        tmp.close()
