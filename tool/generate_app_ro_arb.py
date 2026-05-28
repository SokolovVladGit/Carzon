#!/usr/bin/env python3
"""Generate lib/l10n/app_ro.arb from app_ru.arb with Romanian translations."""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RU_PATH = ROOT / "lib/l10n/app_ru.arb"
RO_PATH = ROOT / "lib/l10n/app_ro.arb"

# Keys with product-approved Romanian copy (not machine-translated).
RO_OVERRIDES: dict[str, str] = {
    "profileLanguageCurrentRomanian": "Română",
    "profileLanguageOptionRussian": "Русский",
    "profileLanguageOptionRomanian": "Română",
    "notificationMessageTitle": "Mesaj nou",
    "notificationMessageBody": "Ați primit un mesaj pentru anunțul din Carzon.",
    "notificationFilterAlertTitle": "Anunț nou",
    "notificationFilterAlertBody": (
        "Există un anunț pentru filtrul salvat. Deschideți pentru a-l vedea."
    ),
    "notificationAndroidChannelMessagesName": "Carzon — mesaje",
    "notificationAndroidChannelMessagesDescription": (
        "Notificări despre mesaje noi în chat"
    ),
    "notificationAndroidChannelFilterName": "Carzon — alerte filtru",
    "notificationAndroidChannelFilterDescription": (
        "Notificări despre anunțuri noi pentru filtrul salvat"
    ),
    "listingBuyerVinReportTitle": "Raport VIN",
    "listingBuyerVinReportBasicDecodeCatalogLine": (
        "Momentan este afișată doar decodarea de bază VIN din catalogul deschis NHTSA vPIC."
    ),
    "listingBuyerVinReportBasicDecodeNotOfficialLine": (
        "Nu este o verificare oficială a înmatriculării, proprietarului, "
        "istoricului de accidente, asigurării sau kilometrajului."
    ),
    "listingBuyerVinReportNhtsaCatalogSourceLine": (
        "Sursă: catalog deschis NHTSA vPIC."
    ),
    "listingBuyerVinReportNotVerifiedSectionTitle": (
        "Ce nu verifică încă acest raport"
    ),
    "listingVinTrustSheetTitle": "Informații VIN",
    "listingVinTrustSheetFooterNote": (
        "Momentan este doar o verificare de bază a formatului. "
        "Verificări extinse din surse oficiale și partenere vor fi adăugate ulterior."
    ),
    "editListingVinReportLimitationNote": (
        "Nu este o verificare oficială a înmatriculării, proprietarului, "
        "istoricului de accidente, asigurării sau kilometrajului."
    ),
    "listingBuyerVinReportNhtsaCatalogDecodeCaution": (
        "Catalogul a returnat date incomplete pentru VIN — "
        "folosiți informațiile ca orientare, nu ca confirmare."
    ),
    "listingBuyerVinReportManualSourcesIntro": (
        "Carzon nu primește încă aceste date automat. "
        "Mai jos sunt surse pe care le puteți verifica separat."
    ),
    "listingBuyerVinReportManualMdRcaBody": (
        "Datele despre daune pot fi verificate pe portalul oficial RCA/BNM după VIN. "
        "Carzon nu primește aceste date automat."
    ),
}

FORBIDDEN_RO = [
    "vin verificat",
    "verificat oficial",
    "istoric verificat",
    "fără accident",
    "istorie curată",
    "complet verificat",
    "juridic curat",
    "kilometraj confirmat",
    "fără restricții",
    "oficial confirmat",
]

CYRILLIC = re.compile(r"[А-Яа-яЁё]")

def is_message_key(key: str) -> bool:
    return not key.startswith("@") and key != "@@locale"


def translate_batch(texts: list[str], translator) -> list[str]:
    if not texts:
        return []
    try:
        return translator.translate_batch(texts)
    except Exception:
        out = []
        for t in texts:
            try:
                out.append(translator.translate(t))
                time.sleep(0.05)
            except Exception as e:
                print(f"translate failed: {t[:40]!r} -> {e}", file=sys.stderr)
                out.append(t)
        return out


def main() -> int:
    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("Install deep_translator: pip install deep-translator", file=sys.stderr)
        return 1

    ru_data = json.loads(RU_PATH.read_text(encoding="utf-8"))
    ro_data: dict = {"@@locale": "ro"}
    translator = GoogleTranslator(source="ru", target="ro")

    keys = [k for k in ru_data if is_message_key(k)]
    batch_size = 40
    for i in range(0, len(keys), batch_size):
        chunk_keys = keys[i : i + batch_size]
        chunk_vals = [ru_data[k] for k in chunk_keys]
        if i > 0:
            time.sleep(0.3)
        translated = translate_batch(chunk_vals, translator)
        for k, ro_val in zip(chunk_keys, translated, strict=True):
            if k in RO_OVERRIDES:
                ro_val = RO_OVERRIDES[k]
            elif isinstance(ro_val, str) and CYRILLIC.search(ro_val):
                # Retry single key if Cyrillic leaked through
                ro_val = translator.translate(ru_data[k])
            ro_data[k] = ro_val
        print(f"translated {min(i + batch_size, len(keys))}/{len(keys)}", file=sys.stderr)

    # Copy @metadata entries verbatim from RU
    for k, v in ru_data.items():
        if k.startswith("@") and k != "@@locale":
            ro_data[k] = v

    # Apply overrides again (in case keys were added only in overrides)
    for k, v in RO_OVERRIDES.items():
        if k in ru_data:
            ro_data[k] = v

    # Parity check
    ru_keys = {k for k in ru_data if is_message_key(k)}
    ro_keys = {k for k in ro_data if is_message_key(k)}
    if ru_keys != ro_keys:
        missing = ru_keys - ro_keys
        extra = ro_keys - ru_keys
        print(f"KEY MISMATCH missing={len(missing)} extra={len(extra)}", file=sys.stderr)
        if missing:
            print("missing:", sorted(missing)[:20], file=sys.stderr)
        return 1

    ro_json = json.dumps(ro_data, ensure_ascii=False, indent=2)
    ro_lower = ro_json.lower()
    for phrase in FORBIDDEN_RO:
        if phrase in ro_lower:
            print(f"FORBIDDEN phrase in RO arb: {phrase}", file=sys.stderr)
            return 1

    RO_PATH.write_text(ro_json + "\n", encoding="utf-8")
    print(f"Wrote {RO_PATH}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
