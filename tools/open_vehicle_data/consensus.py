"""MMY consensus + single clarification. Mirrors resolve_vehicle_by_identity."""

from __future__ import annotations

from collections import Counter
from collections.abc import Iterable
from typing import Any

from .normalize import (
    MAPPING_VERSION,
    YEAR_TOLERANCE,
    cm3_to_liters,
    kw_to_hp,
    normalize_make_key,
    normalize_model_key,
)


def year_overlaps(
    year_min: int,
    year_max: int,
    seller_year: int,
    tolerance: int = YEAR_TOLERANCE,
) -> bool:
    return year_min - tolerance <= seller_year <= year_max + tolerance


def _consensus(values: list[Any]) -> Any | None:
    if not values:
        return None
    if any(v is None for v in values):
        return None
    unique = set(values)
    if len(unique) != 1:
        return None
    return values[0]


def _option_blob(counter: Counter[str]) -> list[dict[str, Any]]:
    return [
        {"value": value, "candidateCount": count}
        for value, count in sorted(counter.items(), key=lambda item: (-item[1], item[0]))
    ]


def resolved_body(
    *,
    nameplate_bodies: list[str],
    mmy_rdw_distinct: int,
    row_rdw_body: str | None,
) -> str | None:
    unique_nameplate = [b for b in nameplate_bodies if b]
    if len(set(unique_nameplate)) == 1:
        return unique_nameplate[0]
    if mmy_rdw_distinct >= 2:
        return row_rdw_body
    return None


def resolve_mmy(
    *,
    make: str,
    model: str,
    year: int,
    configurations: Iterable[dict[str, Any]],
    nameplate_bodies: list[str] | None = None,
    aliases: dict[tuple[str, str], tuple[str, str]] | None = None,
    answer: dict[str, str] | None = None,
) -> dict[str, Any]:
    empty = _payload(
        status="noData",
        make_key=None,
        model_key=None,
        year=year,
        count=0,
        body=None,
        fuel=None,
        displ=None,
        power=None,
        clarification=None,
        confidence="none",
    )
    if year < 1900 or year > 2100:
        return empty

    make_key = normalize_make_key(make)
    model_key = normalize_model_key(model)
    if make_key is None or model_key is None:
        return empty
    if aliases and (make_key, model_key) in aliases:
        make_key, model_key = aliases[(make_key, model_key)]

    nameplate = [b for b in (nameplate_bodies or []) if b]
    window = [
        row
        for row in configurations
        if row.get("make_key") == make_key
        and row.get("model_key") == model_key
        and year_overlaps(int(row["year_min"]), int(row["year_max"]), year)
    ]
    rdw_distinct = len(
        {row.get("body_type_rdw") for row in window if row.get("body_type_rdw")}
    )
    annotated = []
    for row in window:
        item = dict(row)
        item["resolved_body"] = resolved_body(
            nameplate_bodies=nameplate,
            mmy_rdw_distinct=rdw_distinct,
            row_rdw_body=row.get("body_type_rdw"),
        )
        annotated.append(item)

    attr = (answer or {}).get("attribute")
    value = (answer or {}).get("value")
    if attr in {"body", "fuel"} and value:
        annotated = [
            row
            for row in annotated
            if (attr == "fuel" and row.get("fuel_type") == value)
            or (attr == "body" and row.get("resolved_body") == value)
            or (
                attr == "body"
                and row.get("resolved_body") is None
                and value in nameplate
            )
        ]

    if not annotated:
        return _payload(
            status="noData",
            make_key=make_key,
            model_key=model_key,
            year=year,
            count=0,
            body=None,
            fuel=None,
            displ=None,
            power=None,
            clarification=None,
            confidence="none",
        )

    bodies = [row.get("resolved_body") for row in annotated]
    fuels = [row.get("fuel_type") for row in annotated]
    displs = [row.get("engine_displacement_cm3") for row in annotated]
    powers = [row.get("power_kw") for row in annotated]
    body_cons = _consensus(bodies)
    fuel_cons = _consensus(fuels)
    displ_cons = _consensus(displs)
    power_cons = _consensus(powers)
    if attr == "body" and value:
        body_cons = value
    elif attr == "fuel" and value:
        fuel_cons = value

    clarification = None
    if not (answer and answer.get("attribute") in {"body", "fuel"}):
        body_opts = _option_blob(Counter(b for b in bodies if b))
        if not body_opts and 2 <= len(set(nameplate)) <= 5:
            body_opts = [
                {"value": b, "candidateCount": None} for b in sorted(set(nameplate))
            ]
        fuel_opts = _option_blob(Counter(f for f in fuels if f))
        if body_cons is None and 2 <= len(body_opts) <= 5:
            clarification = {"attribute": "body", "options": body_opts}
        elif fuel_cons is None and 2 <= len(fuel_opts) <= 5:
            clarification = {"attribute": "fuel", "options": fuel_opts}

    if body_cons or fuel_cons or displ_cons or power_cons:
        confidence = "high" if clarification is None else "partial"
    elif clarification is not None:
        confidence = "partial"
    else:
        confidence = "low"

    return _payload(
        status="ok",
        make_key=make_key,
        model_key=model_key,
        year=year,
        count=len(annotated),
        body=body_cons,
        fuel=fuel_cons,
        displ=displ_cons,
        power=power_cons,
        clarification=clarification,
        confidence=confidence,
    )


def _payload(
    *,
    status: str,
    make_key: str | None,
    model_key: str | None,
    year: int,
    count: int,
    body: str | None,
    fuel: str | None,
    displ: int | None,
    power: int | None,
    clarification: dict[str, Any] | None,
    confidence: str,
) -> dict[str, Any]:
    return {
        "status": status,
        "mappingVersion": MAPPING_VERSION,
        "identity": {
            "makeKey": make_key,
            "modelKey": model_key,
            "year": year,
            "yearTolerance": YEAR_TOLERANCE,
            "yearEvidence": "registration_window",
        },
        "consensusSpecs": {
            "bodyType": body,
            "fuelType": fuel,
            "engineDisplacementLiters": cm3_to_liters(displ),
            "enginePowerHp": kw_to_hp(power),
            "transmissionType": None,
            "drivetrain": None,
        },
        "candidateCount": count,
        "clarification": clarification,
        "confidence": confidence,
    }
