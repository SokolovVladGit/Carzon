"""VehiclesDB open identity layer only. Specs/paid fields are ignored."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any

from .normalize import normalize_make_key, normalize_model_key, normalize_nameplate_body, normalize_tan_base


def nameplate_rows(models: Iterable[dict[str, Any]], *, source_version: str) -> list[dict[str, Any]]:
    out = []
    for model in models:
        make = model.get("make") or model.get("make_id")
        name = model.get("name") or model.get("model")
        if not make or not name:
            continue
        bodies = [
            body
            for body in (
                normalize_nameplate_body(raw) for raw in (model.get("body_types") or [])
            )
            if body
        ]
        tans = []
        xrefs = model.get("xrefs") or {}
        for raw in xrefs.get("tan") or []:
            base = normalize_tan_base(str(raw))
            if base:
                tans.append(base)
        out.append(
            {
                "make": make,
                "model": name,
                "display_make": make,
                "display_model": name,
                "body_types": sorted(set(bodies)),
                "tan_bases": sorted(set(tans)),
                "source": "vehiclesdb",
                "source_version": source_version,
            }
        )
        for alias in model.get("aliases") or []:
            if normalize_model_key(alias) == normalize_model_key(name):
                continue
            out.append(
                {
                    "make": make,
                    "model": name,
                    "alias_make": make,
                    "alias_model": alias,
                    "source": "vehiclesdb",
                    "source_version": source_version,
                }
            )
    return out


def split_payloads(
    rows: Iterable[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    nameplates = []
    aliases = []
    for row in rows:
        if "alias_model" in row:
            aliases.append(row)
        else:
            nameplates.append(row)
    return nameplates, aliases


def make_aliases_from_catalog(makes: Iterable[dict[str, Any]], *, source_version: str) -> list[dict[str, Any]]:
    """Exact published VehiclesDB make aliases only. No invented mappings."""
    out = []
    for make in makes:
        name = make.get("name")
        if not name:
            continue
        canon = normalize_make_key(name)
        for alias in make.get("aliases") or []:
            alias_key = normalize_make_key(alias)
            if not canon or not alias_key or alias_key == canon:
                continue
            # Make-only aliases are stored against empty-model sentinel never used
            # for MMY lookup. Skip — make aliases already live in SQL apply_make_alias.
            continue
    return out
