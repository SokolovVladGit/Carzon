"""Make include-filters for controlled first ingest. Not a permanent catalog."""

from __future__ import annotations

from collections.abc import Iterable

from .normalize import normalize_make_key

FIRST_ROLLOUT_MAKES = (
    "Skoda",
    "Volkswagen",
    "BMW",
    "Mercedes-Benz",
    "Hyundai",
    "Kia",
    "Toyota",
    "Dacia",
    "Tesla",
    "BYD",
)


def make_key_set(raw_makes: Iterable[str] | None) -> frozenset[str] | None:
    if raw_makes is None:
        return None
    keys = {normalize_make_key(item) for item in raw_makes}
    keys.discard(None)
    return frozenset(keys) or None


def parse_makes_arg(raw: str | None, *, preset: str | None) -> frozenset[str] | None:
    if preset in {"first", "first-rollout"}:
        return make_key_set(FIRST_ROLLOUT_MAKES)
    if raw is None or not raw.strip():
        return None
    return make_key_set(part.strip() for part in raw.split(",") if part.strip())
