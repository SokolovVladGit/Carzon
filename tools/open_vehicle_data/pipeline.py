"""Production ingest orchestration. VehiclesDB → EEA → RDW. No silent complete-on-fail."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from .eea_aggregate import EeaStats, aggregate_eea_paths, upsert_payload
from .loader import ServiceRoleLoader
from .rdw_aggregate import aggregate_rdw_rows, merge_payload
from .rdw_source import iter_rdw_joined, iter_rdw_records
from .vehiclesdb_source import load_open_identity

DEFAULT_EEA_DATASET = "co2cars"
DEFAULT_RDW_DATASET = "gekentekende_voertuigen"
DEFAULT_VDB_DATASET = "vehiclesdb_open_identity"


def iter_rdw_source(
    path: Path,
    *,
    bodies_path: Path | None = None,
    make_keys: frozenset[str] | None = None,
):
    if bodies_path is not None:
        return iter_rdw_joined(path, bodies_path)
    return iter_rdw_records(path, make_keys=make_keys)


def run_pipeline(
    *,
    loader: ServiceRoleLoader,
    eea_paths: list[Path] | None = None,
    rdw_path: Path | None = None,
    rdw_bodies_path: Path | None = None,
    vehiclesdb_path: Path | None = None,
    source_version: str,
    make_keys: frozenset[str] | None = None,
    vehiclesdb_version: str = "unknown",
    start_chunk: int = 0,
) -> dict[str, Any]:
    """
    Order:
    1. VehiclesDB identity — aliases used by EEA upsert
    2. EEA configurations
    3. RDW body merge — updates existing TVV rows only
    A failed phase marks its batch failed and raises. Later phases do not run.
    """
    report: dict[str, Any] = {
        "dry_run": loader.dry_run,
        "eea": None,
        "rdw": None,
        "vehiclesdb": None,
        "chunks": [],
        "would_mutate_hosted": not loader.dry_run,
    }
    if vehiclesdb_path is not None:
        payload = load_open_identity(
            vehiclesdb_path,
            source_version=vehiclesdb_version,
            make_keys=make_keys,
        )
        batch_id = loader.begin_batch("vehiclesdb", DEFAULT_VDB_DATASET, source_version)
        try:
            alias_stats = loader.send_chunks(
                "carzon_open_data_upsert_aliases",
                payload["aliases"],
                start_chunk=start_chunk,
            )
            name_stats = loader.send_chunks(
                "carzon_open_data_upsert_nameplates",
                payload["nameplates"],
            )
            loader.complete_batch(
                batch_id,
                alias_stats["rows"] + name_stats["rows"],
                True,
            )
        except Exception:
            loader.complete_batch(batch_id, 0, False)
            raise
        report["vehiclesdb"] = {
            "aliases": len(payload["aliases"]),
            "nameplates": len(payload["nameplates"]),
            "attribution": payload["attribution"],
            "source_version": payload["source_version"],
            "chunks": [alias_stats, name_stats],
        }
        report["chunks"].extend([alias_stats, name_stats])

    if eea_paths:
        stats = EeaStats()
        aggregated = aggregate_eea_paths(
            eea_paths,
            make_keys=make_keys,
            stats=stats,
        )
        rows = upsert_payload(aggregated)
        batch_id = loader.begin_batch("eea", DEFAULT_EEA_DATASET, source_version)
        try:
            extra = {"p_batch_id": batch_id} if batch_id else {}
            sent = loader.send_chunks(
                "carzon_open_data_upsert_configurations",
                rows,
                extra=extra,
                start_chunk=start_chunk,
            )
            loader.complete_batch(batch_id, sent["rows"], True)
        except Exception:
            loader.complete_batch(batch_id, 0, False)
            raise
        report["eea"] = {
            **stats.as_dict(),
            "normalized_configurations": len(rows),
            "chunks": sent,
        }
        report["chunks"].append(sent)

    if rdw_path is not None:
        aggregated = aggregate_rdw_rows(
            iter_rdw_source(rdw_path, bodies_path=rdw_bodies_path, make_keys=make_keys)
        )
        rows = merge_payload(aggregated)
        batch_id = loader.begin_batch("rdw", DEFAULT_RDW_DATASET, source_version)
        try:
            extra = {"p_batch_id": batch_id} if batch_id else {}
            sent = loader.send_chunks(
                "carzon_open_data_merge_rdw_body",
                rows,
                extra=extra,
                start_chunk=start_chunk,
            )
            loader.complete_batch(batch_id, sent["rows"], True)
        except Exception:
            loader.complete_batch(batch_id, 0, False)
            raise
        report["rdw"] = {
            "body_aggregates": len(aggregated),
            "merge_rows": len(rows),
            "chunks": sent,
        }
        report["chunks"].append(sent)

    return report
