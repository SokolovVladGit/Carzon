#!/usr/bin/env python3
"""Download curated, full-color car-brand SVG logos from Wikimedia Commons.

Source list: tools/brand_assets/brands_list.json
Output:      assets/brands/svg/<slug>.svg

Usage:
    python download_brands.py

No external dependencies. Standard library only.
"""

from __future__ import annotations

import json
import random
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

USER_AGENT = "carzon-brand-downloader/1.0 (Flutter asset build)"
TIMEOUT_SECONDS = 20

# Politeness pause between successful requests. Uniform jitter within
# this window keeps Wikimedia's rate limiter happy for small batches.
PER_REQUEST_SLEEP_RANGE = (0.8, 1.5)

# Backoff schedule (seconds) used when the server returns HTTP 429.
# Index = attempt number (1-based). MAX_ATTEMPTS = len(RETRY_BACKOFF).
RETRY_BACKOFF = (2, 5, 10)
MAX_ATTEMPTS = len(RETRY_BACKOFF)

DEFAULT_SVG = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" role="img" aria-label="brand">
  <circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="1.5"/>
  <circle cx="12" cy="12" r="3" fill="currentColor"/>
</svg>
"""


def load_brands(path: Path) -> dict[str, str]:
    try:
        raw = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise SystemExit(f"cannot read {path}: {exc}") from exc
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid JSON in {path}: {exc}") from exc
    if not isinstance(data, dict) or not data:
        raise SystemExit(f"{path} must be a non-empty JSON object")
    cleaned: dict[str, str] = {}
    for slug, url in data.items():
        if not isinstance(slug, str) or not isinstance(url, str):
            print(f"[warn] skipping non-string entry: {slug!r}", file=sys.stderr)
            continue
        slug = slug.strip().lower()
        url = url.strip()
        if not slug or not url:
            continue
        cleaned[slug] = url
    return cleaned


def _fetch_once(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=TIMEOUT_SECONDS) as resp:
        if resp.status != 200:
            raise urllib.error.HTTPError(
                url, resp.status, f"HTTP {resp.status}", resp.headers, None
            )
        return resp.read()


def fetch_svg(url: str, slug: str) -> bytes:
    """Fetch an SVG, retrying on HTTP 429 with a fixed backoff schedule.

    Any non-429 error propagates to the caller (handled as a regular
    download failure in the main loop).
    """
    last_error: Exception | None = None
    for attempt in range(1, MAX_ATTEMPTS + 1):
        try:
            return _fetch_once(url)
        except urllib.error.HTTPError as exc:
            if exc.code != 429:
                raise
            last_error = exc
            if attempt == MAX_ATTEMPTS:
                break
            delay = RETRY_BACKOFF[attempt - 1]
            print(
                f"[retry] {slug:<18} attempt {attempt + 1} after {delay}s "
                f"(HTTP 429)",
                file=sys.stderr,
            )
            time.sleep(delay)
    assert last_error is not None
    raise last_error


def looks_like_svg(data: bytes) -> bool:
    # Basic sanity check: must contain "<svg" near the top of the payload.
    head = data[:2048].lower()
    return b"<svg" in head


def save(data: bytes, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)


def _polite_sleep(is_last: bool) -> None:
    """Sleep between requests with a small random jitter.

    Skipped after the final request to avoid pointless end-of-run delay.
    """
    if is_last:
        return
    low, high = PER_REQUEST_SLEEP_RANGE
    time.sleep(random.uniform(low, high))


def write_fallback(dest: Path) -> None:
    if dest.exists():
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(DEFAULT_SVG, encoding="utf-8")


def main() -> int:
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parents[1]
    brands_file = script_dir / "brands_list.json"
    out_dir = project_root / "assets" / "brands" / "svg"

    brands = load_brands(brands_file)

    out_dir.mkdir(parents=True, exist_ok=True)

    ok: list[str] = []
    failed: list[tuple[str, str]] = []

    items = list(brands.items())
    for index, (slug, url) in enumerate(items):
        dest = out_dir / f"{slug}.svg"
        try:
            data = fetch_svg(url, slug)
        except Exception as exc:  # noqa: BLE001 - requirement: keep going
            failed.append((slug, f"{type(exc).__name__}: {exc}"))
            print(f"[warn] {slug:<18} download failed: {exc}", file=sys.stderr)
            _polite_sleep(is_last=(index == len(items) - 1))
            continue

        if not looks_like_svg(data):
            failed.append((slug, "response is not an SVG"))
            print(f"[warn] {slug:<18} invalid (not an SVG)", file=sys.stderr)
            _polite_sleep(is_last=(index == len(items) - 1))
            continue

        try:
            save(data, dest)
        except OSError as exc:
            failed.append((slug, f"write failed: {exc}"))
            print(f"[warn] {slug:<18} write failed: {exc}", file=sys.stderr)
            _polite_sleep(is_last=(index == len(items) - 1))
            continue

        ok.append(slug)
        print(f"[ok]   {slug:<18} -> {dest.name} ({len(data)} bytes)")
        _polite_sleep(is_last=(index == len(items) - 1))

    write_fallback(out_dir / "default.svg")

    total = len(brands)
    print()
    print("=" * 56)
    print(f"Output directory : {out_dir}")
    print(f"Brands in list   : {total}")
    print(f"Downloaded       : {len(ok)}")
    print(f"Failed           : {len(failed)}")
    for slug, reason in failed:
        print(f"  - {slug}: {reason}")
    print("=" * 56)

    return 0 if not failed else 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\naborted", file=sys.stderr)
        sys.exit(130)
