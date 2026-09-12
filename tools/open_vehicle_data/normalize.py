"""Open-data field normalization. Mirrors SQL helpers in
`20260912180000_manual_smart_fill_open_data.sql`. Keep both in lockstep.
"""

from __future__ import annotations

import re
import unicodedata

MAPPING_VERSION = "m1.0"
YEAR_TOLERANCE = 1

_DIACRITICS = str.maketrans(
    "áàäâãåéèëêíìïîóòöôõúùüûýÿčćšžñř",
    "aaaaaaeeeeiiiiooooouuuuyyccsznr",
)

_TAN_REV = re.compile(r"\*[0-9]{1,3}$")
_WS = re.compile(r"\s+")
_TRAIL_PUNCT = re.compile(r"[.,;:]+$")


def fold_ascii(raw: str | None) -> str | None:
    if raw is None:
        return None
    text = raw.strip().lower()
    if not text:
        return None
    text = unicodedata.normalize("NFKD", text)
    text = "".join(ch for ch in text if not unicodedata.combining(ch))
    text = text.translate(_DIACRITICS)
    return text or None


def normalize_make_key(raw: str | None) -> str | None:
    folded = fold_ascii(raw)
    if folded is None:
        return None
    key = _WS.sub("", folded).replace("-", "").replace("–", "").replace("&", "")
    return apply_make_alias(key) if key else None


def normalize_model_key(raw: str | None) -> str | None:
    folded = fold_ascii(raw)
    if folded is None:
        return None
    key = _WS.sub(" ", folded)
    key = _TRAIL_PUNCT.sub("", key)
    return key or None


def apply_make_alias(make_key: str | None) -> str | None:
    if make_key is None:
        return None
    return {
        "vw": "volkswagen",
        "volkswag": "volkswagen",
        "mb": "mercedesbenz",
        "mercedes": "mercedesbenz",
        "mercedesbenz": "mercedesbenz",
        "chevy": "chevrolet",
    }.get(make_key, make_key)


def normalize_tan_base(tan: str | None) -> str | None:
    if tan is None:
        return None
    compact = _WS.sub("", tan.strip().lower())
    if not compact:
        return None
    return _TAN_REV.sub("", compact) or None


def configuration_key(
    type_code: str | None,
    variant: str | None,
    version: str | None,
) -> str | None:
    key = "|".join(
        [
            (type_code or "").strip().lower(),
            (variant or "").strip().lower(),
            (version or "").strip().lower(),
        ]
    )
    if key == "||":
        return None
    return key


def normalize_fuel(ft: str | None, fm: str | None) -> str | None:
    fuel = (ft or "").strip().lower()
    mode = (fm or "").strip().lower()
    if fuel == "electric" and mode in {"e", "m", ""}:
        return "electric"
    if fuel in {"petrol/electric", "diesel/electric"} and mode == "p":
        return "plug_in_hybrid"
    if fuel in {"petrol", "diesel"} and mode == "h":
        return "hybrid"
    if fuel == "petrol" and mode == "m":
        return "petrol"
    if fuel == "diesel" and mode == "m":
        return "diesel"
    if fuel == "lpg" and mode == "m":
        return "lpg"
    if fuel in {"cng", "ng"} and mode == "m":
        return "cng"
    return None


def normalize_rdw_body(
    carrosserietype: str | None = None,
    eu_description: str | None = None,
    inrichting: str | None = None,
) -> str | None:
    code = (carrosserietype or "").strip().lower()
    desc = (eu_description or "").strip().lower()
    inl = (inrichting or "").strip().lower()
    by_code = {
        "aa": "sedan",
        "ab": "hatchback",
        "ac": "wagon",
        "ad": "coupe",
        "ae": "convertible",
        "ag": "convertible",
        "af": "minivan",
        "sa": "minivan",
    }.get(code)
    if by_code:
        return by_code
    by_inl = {
        "sedan": "sedan",
        "limousine": "sedan",
        "hatchback": "hatchback",
        "wagon": "wagon",
        "stationwagen": "wagon",
        "stationwagen/combi": "wagon",
        "suv": "suv",
        "coupe": "coupe",
        "coupé": "coupe",
        "cabriolet": "convertible",
        "cabrio": "convertible",
        "convertible": "convertible",
        "roadster": "convertible",
        "mpv": "minivan",
        "minivan": "minivan",
        "pick-up": "pickup",
        "pickup": "pickup",
        "van": "van",
    }.get(inl)
    if by_inl:
        return by_inl
    return {
        "sedan": "sedan",
        "hatchback": "hatchback",
        "stationwagen": "wagon",
        "coupe": "coupe",
        "coupé": "coupe",
        "cabriolet": "convertible",
    }.get(desc)


def normalize_nameplate_body(raw: str | None) -> str | None:
    return {
        "sedan": "sedan",
        "hatchback": "hatchback",
        "wagon": "wagon",
        "suv": "suv",
        "coupe": "coupe",
        "convertible": "convertible",
        "roadster": "convertible",
        "mpv": "minivan",
        "minivan": "minivan",
        "pickup": "pickup",
        "van": "van",
    }.get((raw or "").strip().lower())


def kw_to_hp(power_kw: int | None) -> int | None:
    if power_kw is None or power_kw <= 0:
        return None
    return int(round(power_kw * 1.35962))


def cm3_to_liters(cm3: int | None) -> float | None:
    if cm3 is None or cm3 <= 0:
        return None
    return cm3 / 1000.0
