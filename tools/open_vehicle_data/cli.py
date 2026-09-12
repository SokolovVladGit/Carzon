#!/usr/bin/env python3
"""Local open-data import CLI. Writes aggregates outside git. Does not deploy."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .acquire import DEFAULT_CACHE, stream_copy, stream_http
from .eea_aggregate import EeaStats, aggregate_eea_paths, upsert_payload, write_jsonl
from .loader import DEFAULT_CHUNK_SIZE, loader_from_env
from .makes import parse_makes_arg
from .pipeline import run_pipeline
from .rdw_aggregate import aggregate_rdw_rows, merge_payload
from .rdw_source import iter_rdw_joined, iter_rdw_records
from .tgk_transmission import (
    TGK_MAPPING_VERSION,
    aggregate_tgk_rows,
    fetch_catalog_tvv_keys,
    ingest_tgk_transmissions,
    iter_tgk_pages,
    join_catalog,
    load_aggregate_cache,
    sanity_gate,
    summarize,
    write_aggregate_cache,
)
from .vehiclesdb_source import load_open_identity


def _makes(args: argparse.Namespace) -> frozenset[str] | None:
    return parse_makes_arg(getattr(args, "makes", None), preset=getattr(args, "makes_preset", None))


def _cmd_eea(args: argparse.Namespace) -> None:
    stats = EeaStats()
    paths = [Path(item) for item in args.inputs] if getattr(args, "inputs", None) else [Path(args.input)]
    aggregated = aggregate_eea_paths(paths, make_keys=_makes(args), stats=stats)
    write_jsonl(Path(args.output), upsert_payload(aggregated))
    print(
        f"eea configurations={len(aggregated)} {stats.as_dict()}",
        file=sys.stderr,
    )


def _cmd_rdw(args: argparse.Namespace) -> None:
    if args.bodies:
        rows = iter_rdw_joined(Path(args.input), Path(args.bodies))
    else:
        rows = iter_rdw_records(Path(args.input))
    aggregated = aggregate_rdw_rows(rows)
    write_jsonl(Path(args.output), merge_payload(aggregated))
    print(f"rdw tvv bodies={len(aggregated)}", file=sys.stderr)


def _cmd_vehiclesdb(args: argparse.Namespace) -> None:
    payload = load_open_identity(Path(args.input), source_version=args.version)
    out = Path(args.output)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps(
            {
                "nameplates": payload["nameplates"],
                "aliases": payload["aliases"],
                "attribution": payload["attribution"],
                "source_version": payload["source_version"],
            },
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )
    print(
        f"vehiclesdb nameplates={len(payload['nameplates'])} "
        f"aliases={len(payload['aliases'])} version={payload['source_version']}",
        file=sys.stderr,
    )


def _cmd_acquire(args: argparse.Namespace) -> None:
    dest = Path(args.output)
    if args.url:
        stream_http(args.url, dest)
        print(f"downloaded host-ok -> {dest}", file=sys.stderr)
        return
    stream_copy(Path(args.input), dest)
    print(f"copied -> {dest}", file=sys.stderr)


def _cmd_tgk_transmission(args: argparse.Namespace) -> None:
    logs: list[str] = []

    def log(message: str) -> None:
        logs.append(message)
        print(message, file=sys.stderr)

    cache = Path(args.cache)
    if args.from_cache:
        agg, decisions = load_aggregate_cache(cache)
        log(f"loaded cached TGK decisions={len(decisions)} rows_read={agg.rows_read} from {cache}")
    else:
        rows = iter_tgk_pages(
            page_size=args.page_size,
            max_rows=args.max_rows,
            base_url=args.url_tgk,
            log=log,
        )
        agg = aggregate_tgk_rows(rows)
        decisions = agg.decisions()
        write_aggregate_cache(cache, agg, decisions)
        log(f"cached TGK decisions={len(decisions)} -> {cache}")
    tgk_report = summarize(agg, decisions)
    print(json.dumps({"tgk": tgk_report}, ensure_ascii=False, indent=2, default=str))
    if args.ingest and args.dry_run:
        raise SystemExit("tgk-transmission: use either --dry-run or --ingest")
    catalog_keys = None
    matched = None
    loader = None
    if args.with_catalog or args.ingest:
        loader = loader_from_env(
            url=args.url,
            chunk_size=args.chunk_size,
            dry_run=False,
            log=log,
        )
        catalog_keys = fetch_catalog_tvv_keys(loader)
        matched = join_catalog(decisions, catalog_keys)
        log(f"catalog tvv={len(catalog_keys)} matched={len(matched)}")
    report = summarize(agg, decisions, catalog_keys=catalog_keys, matched=matched)
    blockers = sanity_gate(report)
    report["sanity_blockers"] = blockers
    print(json.dumps(report, ensure_ascii=False, indent=2, default=str))
    if blockers:
        print("SANITY GATE FAILED: " + "; ".join(blockers), file=sys.stderr)
        raise SystemExit(2)
    if args.ingest:
        if loader is None or matched is None:
            raise SystemExit("ingest requires catalog join")
        ingest_report = ingest_tgk_transmissions(
            loader,
            matched,
            source_version=args.source_version,
            start_chunk=args.start_chunk,
        )
        print(json.dumps({"ingest": ingest_report, "mapping_version": TGK_MAPPING_VERSION}, indent=2))


def _cmd_ingest(args: argparse.Namespace) -> None:
    logs: list[str] = []

    def log(message: str) -> None:
        logs.append(message)
        print(message, file=sys.stderr)

    loader = loader_from_env(
        url=args.url,
        chunk_size=args.chunk_size,
        dry_run=args.dry_run,
        log=log,
    )
    eea_paths = [Path(item) for item in (args.eea or [])]
    report = run_pipeline(
        loader=loader,
        eea_paths=eea_paths or None,
        rdw_path=Path(args.rdw) if args.rdw else None,
        rdw_bodies_path=Path(args.rdw_bodies) if args.rdw_bodies else None,
        vehiclesdb_path=Path(args.vehiclesdb) if args.vehiclesdb else None,
        source_version=args.source_version,
        make_keys=_makes(args),
        vehiclesdb_version=args.vehiclesdb_version,
        start_chunk=args.start_chunk,
    )
    print(json.dumps(report, ensure_ascii=False, indent=2, default=str))


def _add_make_flags(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--makes", help="Comma-separated include list. Not a permanent catalog.")
    parser.add_argument(
        "--makes-preset",
        choices=("first", "first-rollout"),
        help="Controlled first-rollout include list.",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    eea = sub.add_parser("eea-aggregate", help="Official EEA CSV/JSONL/ZIP → upsert payload")
    eea.add_argument("--input", help="Single official EEA file")
    eea.add_argument("--inputs", nargs="+", help="Multiple official year/status files")
    eea.add_argument("--output", required=True)
    _add_make_flags(eea)
    eea.set_defaults(func=_cmd_eea)

    rdw = sub.add_parser("rdw-aggregate", help="Official RDW CSV/JSONL → TVV body payload")
    rdw.add_argument("--input", required=True, help="Vehicles export or combined TVV+body file")
    rdw.add_argument("--bodies", help="Optional official carrosserie file; plate join is transient")
    rdw.add_argument("--output", required=True)
    rdw.set_defaults(func=_cmd_rdw)

    vdb = sub.add_parser("vehiclesdb-identity", help="Extract VehiclesDB free identity layer")
    vdb.add_argument("--input", required=True, help="Free models.json")
    vdb.add_argument("--output", required=True)
    vdb.add_argument("--version", default="unknown")
    vdb.set_defaults(func=_cmd_vehiclesdb)

    acquire = sub.add_parser("acquire", help="Stream official source to gitignored cache")
    acquire.add_argument("--input", help="Local official file")
    acquire.add_argument("--url", help="Official host only. Never used by unit tests.")
    acquire.add_argument(
        "--output",
        default=str(DEFAULT_CACHE / "source.bin"),
        help="Destination under tools/open_vehicle_data/.cache/",
    )
    acquire.set_defaults(func=_cmd_acquire)

    ingest = sub.add_parser("ingest", help="Chunked service_role ingest. Dry-run by default? No — flag required for no-write.")
    ingest.add_argument("--eea", nargs="+", help="Official EEA files")
    ingest.add_argument("--rdw", help="Official RDW vehicles/combined file")
    ingest.add_argument("--rdw-bodies", help="Optional RDW carrosserie file")
    ingest.add_argument("--vehiclesdb", help="Free VehiclesDB models.json")
    ingest.add_argument("--source-version", required=True)
    ingest.add_argument("--vehiclesdb-version", default="unknown")
    ingest.add_argument("--chunk-size", type=int, default=DEFAULT_CHUNK_SIZE)
    ingest.add_argument("--start-chunk", type=int, default=0)
    ingest.add_argument("--url", help="Supabase URL. Defaults to SUPABASE_URL. Not hardcoded.")
    ingest.add_argument("--dry-run", action="store_true")
    _add_make_flags(ingest)
    ingest.set_defaults(func=_cmd_ingest)

    tgk = sub.add_parser(
        "tgk-transmission",
        help="Stream RDW TGK 7rjk-eycs and merge transmission into existing configs.",
    )
    tgk.add_argument(
        "--url-tgk",
        default="https://opendata.rdw.nl/resource/7rjk-eycs.json",
        help="Official Socrata TGK Versnelling dataset.",
    )
    tgk.add_argument("--page-size", type=int, default=20000)
    tgk.add_argument("--max-rows", type=int, help="Bound for tests / smoke only")
    tgk.add_argument("--source-version", default=TGK_MAPPING_VERSION)
    tgk.add_argument("--chunk-size", type=int, default=DEFAULT_CHUNK_SIZE)
    tgk.add_argument("--start-chunk", type=int, default=0)
    tgk.add_argument("--url", help="Supabase URL. Defaults to SUPABASE_URL.")
    tgk.add_argument("--dry-run", action="store_true")
    tgk.add_argument(
        "--with-catalog",
        action="store_true",
        help="Fetch hosted TVV keys and compute exact-match stats.",
    )
    tgk.add_argument(
        "--ingest",
        action="store_true",
        help="Write transmission merge. Requires service_role. Refuses if sanity gate fails.",
    )
    tgk.add_argument(
        "--cache",
        default=str(Path("tools/open_vehicle_data/.cache/tgk_transmission_decisions.jsonl")),
    )
    tgk.add_argument("--from-cache", action="store_true")
    tgk.set_defaults(func=_cmd_tgk_transmission)

    args = parser.parse_args(argv)
    if args.cmd == "eea-aggregate" and not args.input and not args.inputs:
        parser.error("eea-aggregate requires --input or --inputs")
    if args.cmd == "acquire" and not args.input and not args.url:
        parser.error("acquire requires --input or --url")
    args.func(args)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
