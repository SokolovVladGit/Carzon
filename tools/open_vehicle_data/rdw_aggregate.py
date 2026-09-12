"""RDW plate-level rows → TVV body aggregates. Plates discarded immediately."""

from __future__ import annotations

import json
from collections import Counter, defaultdict
from collections.abc import Iterable
from pathlib import Path
from typing import Any

from .normalize import configuration_key, normalize_rdw_body, normalize_tan_base
from .privacy import assert_no_pii

KEEP_KEYS = (
    "type_code",
    "variant_code",
    "version_code",
    "tan",
    "carrosserietype",
    "eu_description",
    "inrichting",
)


def sanitize_rdw_row(raw: dict[str, Any]) -> dict[str, Any]:
    assert_no_pii(raw, context="rdw")
    return {key: raw.get(key) for key in KEEP_KEYS}


def aggregate_rdw_rows(rows: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    grouped: dict[str, Counter[str]] = defaultdict(Counter)
    meta: dict[str, dict[str, Any]] = {}
    for raw in rows:
        clean = sanitize_rdw_row(raw)
        cfg = configuration_key(
            clean.get("type_code"),
            clean.get("variant_code"),
            clean.get("version_code"),
        )
        body = normalize_rdw_body(
            clean.get("carrosserietype"),
            clean.get("eu_description"),
            clean.get("inrichting"),
        )
        if cfg is None or body is None:
            continue
        grouped[cfg][body] += 1
        meta[cfg] = {
            "type_code": clean.get("type_code"),
            "variant_code": clean.get("variant_code"),
            "version_code": clean.get("version_code"),
            "tan_base": normalize_tan_base(clean.get("tan")),
        }
    out = []
    for cfg, counts in grouped.items():
        classes = sorted(counts)
        top = counts.most_common(1)[0][0] if len(classes) == 1 else None
        item = {
            **meta[cfg],
            "configuration_key": cfg,
            "body_type_rdw": top,
            "body_classes": classes,
            "body_class_count": len(classes),
            "carrosserietype": None,
            "eu_description": None,
            "inrichting": None,
        }
        if top:
            item["inrichting"] = top
        out.append(item)
    return out


def merge_payload(aggregated: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    payload = []
    for row in aggregated:
        for body in row.get("body_classes") or []:
            payload.append(
                {
                    "type_code": row.get("type_code"),
                    "variant_code": row.get("variant_code"),
                    "version_code": row.get("version_code"),
                    "inrichting": body,
                }
            )
    return payload


def aggregate_rdw_records(rows: Iterable[dict[str, Any]]) -> list[dict[str, Any]]:
    """Projected official/internal rows. Must already have PII dropped."""
    return aggregate_rdw_rows(rows)


def load_jsonl(path: Path) -> list[dict[str, Any]]:
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows
