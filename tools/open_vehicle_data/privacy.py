"""Refuse plate / VIN / owner fields before any persist."""

from __future__ import annotations

FORBIDDEN_KEYS = frozenset(
    {
        "kenteken",
        "license_plate",
        "licence_plate",
        "number_plate",
        "vin",
        "chassisnummer",
        "chassis_number",
        "tenaamstelling",
        "tenaamstellen",
        "owner",
        "eigenaar",
    }
)


def forbidden_keys_present(record: dict) -> set[str]:
    found: set[str] = set()
    for key in record:
        lowered = str(key).strip().lower()
        if lowered in FORBIDDEN_KEYS:
            found.add(lowered)
    return found


def assert_no_pii(record: dict, *, context: str = "rdw") -> None:
    found = forbidden_keys_present(record)
    if found:
        raise ValueError(
            f"{context} record retains forbidden keys: {sorted(found)}"
        )
