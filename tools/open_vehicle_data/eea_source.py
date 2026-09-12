"""Official EEA CO2 cars adapter. Streams CSV/JSONL/ZIP. No full dump in git."""

from __future__ import annotations

import csv
import io
import json
import zipfile
from collections.abc import Iterator
from pathlib import Path
from typing import Any, BinaryIO, TextIO

# Official EEA monitoring column names (case-insensitive).
_OFFICIAL = {
    "mk": "make",
    "cn": "model",
    "year": "year",
    "r": "year",
    "tan": "tan",
    "t": "type_code",
    "va": "variant_code",
    "ve": "version_code",
    "ft": "ft",
    "fm": "fm",
    "ec": "ec_cm3",
    "ep": "ep_kw",
    "status": "status",
    "cnt": "observation_count",
    "observation_count": "observation_count",
}

_INTERNAL = {
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
    "observation_count",
}


def _norm_header(name: str) -> str:
    text = name.strip().lower().replace("\ufeff", "")
    if "(" in text:
        text = text.split("(", 1)[0].strip()
    return text


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


def project_eea_row(
    raw: dict[str, Any],
    *,
    status_override: str | None = None,
) -> dict[str, Any] | None:
    if not raw:
        return None
    projected: dict[str, Any] = {}
    for key, value in raw.items():
        header = _norm_header(str(key))
        if header in _OFFICIAL:
            projected[_OFFICIAL[header]] = value
        elif header in _INTERNAL:
            projected[header] = value
    if status_override:
        projected["status"] = status_override
    if not projected.get("make") and not projected.get("model"):
        return None
    return projected


def _iter_csv(handle: TextIO, *, status_override: str | None) -> Iterator[dict[str, Any]]:
    reader = _dict_reader(handle)
    if not reader.fieldnames:
        return
    for raw in reader:
        row = project_eea_row(raw, status_override=status_override)
        if row is not None:
            yield row


def _iter_jsonl(handle: TextIO, *, status_override: str | None) -> Iterator[dict[str, Any]]:
    for line in handle:
        if not line.strip():
            continue
        raw = json.loads(line)
        if not isinstance(raw, dict):
            continue
        row = project_eea_row(raw, status_override=status_override)
        if row is not None:
            yield row


def infer_status_from_name(name: str) -> str | None:
    lowered = name.lower().replace("\\", "/")
    finalized = ("_f.csv", "_f.jsonl", "_f.txt", "_f.zip", "/f/")
    provisional = ("_p.csv", "_p.jsonl", "_p.txt", "_p.zip", "/p/")
    if any(token in lowered for token in finalized):
        return "F"
    if any(token in lowered for token in provisional):
        return "P"
    return None


def iter_eea_records(
    path: Path,
    *,
    status_override: str | None = None,
) -> Iterator[dict[str, Any]]:
    """Stream official EEA CSV/JSONL/ZIP. Does not load the file into a list."""
    archive_hint = infer_status_from_name(path.name)
    suffix = path.suffix.lower()
    if suffix == ".zip":
        with zipfile.ZipFile(path) as archive:
            names = [
                name
                for name in archive.namelist()
                if name.lower().endswith((".csv", ".jsonl", ".txt"))
                and not name.startswith("__")
            ]
            for member in names:
                member_override = (
                    status_override
                    or infer_status_from_name(member)
                    or archive_hint
                )
                with archive.open(member) as binary:
                    text = io.TextIOWrapper(binary, encoding="utf-8-sig", newline="")
                    if member.lower().endswith(".jsonl"):
                        yield from _iter_jsonl(text, status_override=member_override)
                    else:
                        yield from _iter_csv(text, status_override=member_override)
        return
    override = status_override or archive_hint
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        if suffix == ".jsonl":
            yield from _iter_jsonl(handle, status_override=override)
        else:
            yield from _iter_csv(handle, status_override=override)


def open_binary_as_text(buffer: BinaryIO) -> TextIO:
    return io.TextIOWrapper(buffer, encoding="utf-8-sig", newline="")
