"""FREE VehiclesDB identity layer. Paid configuration specs are ignored."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from .normalize import normalize_make_key
from .vehiclesdb_identity import nameplate_rows, split_payloads

PAID_KEYS = frozenset(
    {
        "engines",
        "trims",
        "specs",
        "specifications",
        "configurations",
        "pricing",
        "prices",
        "msrp",
    }
)


def extract_attribution(doc: Any) -> dict[str, Any] | None:
    if not isinstance(doc, dict):
        return None
    raw = doc.get("attribution") or doc.get("ATTRIBUTION")
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str) and raw.strip():
        return {"notice": raw.strip()}
    return None


def load_open_identity(
    path: Path,
    *,
    source_version: str,
    make_keys: frozenset[str] | None = None,
    makes_path: Path | None = None,
) -> dict[str, Any]:
    doc = json.loads(path.read_text(encoding="utf-8"))
    attribution = extract_attribution(doc)
    make_names: dict[str, str] = {}

    def _index_makes(raw_makes: object) -> None:
        if not isinstance(raw_makes, list):
            return
        for item in raw_makes:
            if isinstance(item, dict) and item.get("id") and item.get("name"):
                make_names[str(item["id"])] = str(item["name"])

    if makes_path is not None and makes_path.exists():
        _index_makes(json.loads(makes_path.read_text(encoding="utf-8")))
    if isinstance(doc, dict):
        _index_makes(doc.get("makes"))
        version = (
            source_version
            if source_version != "unknown"
            else str(doc.get("source_version") or doc.get("version") or "unknown")
        )
        models = doc.get("models") or doc.get("data") or []
        if attribution is None:
            attribution = extract_attribution(doc.get("manifest") or {})
    else:
        version = source_version
        models = doc
    identity_models = []
    for model in models:
        if not isinstance(model, dict):
            continue
        make = model.get("make") or make_names.get(str(model.get("make_id") or "")) or model.get("make_id")
        cleaned = {key: value for key, value in model.items() if key not in PAID_KEYS}
        cleaned["make"] = make
        if make_keys is not None and normalize_make_key(str(make) if make else None) not in make_keys:
            continue
        identity_models.append(cleaned)
    rows = nameplate_rows(identity_models, source_version=version)
    nameplates, aliases = split_payloads(rows)
    return {
        "nameplates": nameplates,
        "aliases": aliases,
        "attribution": attribution,
        "source_version": version,
        "paid_fields_ignored": True,
    }
