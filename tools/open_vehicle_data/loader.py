"""Chunked service_role RPC loader. Never logs secrets. Hosted ingest is opt-in."""

from __future__ import annotations

import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
from collections.abc import Callable, Iterable, Sequence
from typing import Any
from urllib.parse import urlparse

from .eea_aggregate import iter_chunked

DEFAULT_CHUNK_SIZE = 250
MAX_RETRIES = 3


def _redact_secret(value: str | None) -> str:
    if not value:
        return ""
    if len(value) <= 8:
        return "***"
    return f"{value[:4]}…{value[-2:]}"


def env_supabase_url(explicit: str | None = None) -> str:
    return (explicit or os.environ.get("SUPABASE_URL") or "").rstrip("/")


def env_service_role_key() -> str:
    return os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get(
        "SERVICE_ROLE_KEY", ""
    )


class SecretError(RuntimeError):
    pass


class LoaderError(RuntimeError):
    def __init__(self, message: str, *, chunk_index: int | None = None) -> None:
        super().__init__(message)
        self.chunk_index = chunk_index


class ServiceRoleLoader:
    def __init__(
        self,
        *,
        url: str,
        service_role_key: str,
        chunk_size: int = DEFAULT_CHUNK_SIZE,
        dry_run: bool = False,
        sleep: Callable[[float], None] = time.sleep,
        transport: Callable[[str, dict[str, Any]], Any] | None = None,
        log: Callable[[str], None] | None = None,
    ) -> None:
        if chunk_size <= 0:
            raise ValueError("chunk_size must be positive")
        self.url = url.rstrip("/")
        self._key = service_role_key
        self.chunk_size = chunk_size
        self.dry_run = dry_run
        self._sleep = sleep
        self._transport = transport
        self._log = log or (lambda message: None)
        if not dry_run:
            if not self.url:
                raise SecretError("SUPABASE_URL is required")
            if not self._key:
                raise SecretError("SUPABASE_SERVICE_ROLE_KEY is required")
            host = urlparse(self.url).hostname or ""
            if "localhost" not in host and "127.0.0.1" not in host:
                self._log(f"loader target host={host} key={_redact_secret(self._key)}")

    def rpc(self, name: str, payload: dict[str, Any]) -> Any:
        if self.dry_run:
            self._log(f"dry-run rpc {name} keys={sorted(payload)}")
            return None
        if self._transport is not None:
            return self._transport(name, payload)
        body = json.dumps(payload).encode("utf-8")
        request = urllib.request.Request(
            f"{self.url}/rest/v1/rpc/{name}",
            data=body,
            method="POST",
            headers={
                "apikey": self._key,
                "Authorization": f"Bearer {self._key}",
                "Content-Type": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                raw = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:400]
            raise LoaderError(f"{name} HTTP {exc.code}: {detail}") from exc
        if not raw:
            return None
        return json.loads(raw)

    def rest_get(self, table: str, params: dict[str, str]) -> list[dict[str, Any]]:
        if self._transport is not None:
            result = self._transport(f"GET {table}", params)
            return result if isinstance(result, list) else []
        query = urllib.parse.urlencode(params)
        request = urllib.request.Request(
            f"{self.url}/rest/v1/{table}?{query}",
            method="GET",
            headers={
                "apikey": self._key,
                "Authorization": f"Bearer {self._key}",
                "Accept": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                raw = response.read().decode("utf-8")
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")[:400]
            raise LoaderError(f"GET {table} HTTP {exc.code}: {detail}") from exc
        if not raw:
            return []
        payload = json.loads(raw)
        if not isinstance(payload, list):
            raise LoaderError(f"GET {table} expected JSON array")
        return payload

    def begin_batch(self, source: str, dataset: str, version: str) -> str | None:
        result = self.rpc(
            "carzon_open_data_begin_import_batch",
            {
                "p_source": source,
                "p_source_dataset": dataset,
                "p_source_version": version,
            },
        )
        if self.dry_run:
            return None
        if isinstance(result, str):
            return result
        if isinstance(result, dict) and result.get("id"):
            return str(result["id"])
        return None if result is None else str(result).strip('"')

    def complete_batch(self, batch_id: str | None, row_count: int, ok: bool) -> None:
        if self.dry_run:
            self._log(f"dry-run complete rows={row_count} ok={ok}")
            return
        if not batch_id:
            raise LoaderError("missing batch_id")
        self.rpc(
            "carzon_open_data_complete_import_batch",
            {
                "p_batch_id": batch_id,
                "p_row_count": row_count,
                "p_ok": ok,
            },
        )

    def send_chunks(
        self,
        rpc_name: str,
        rows: Sequence[dict[str, Any]] | Iterable[dict[str, Any]],
        *,
        extra: dict[str, Any] | None = None,
        rows_key: str = "p_rows",
        start_chunk: int = 0,
    ) -> dict[str, int]:
        sent = 0
        chunks = 0
        skipped = 0
        materialized = list(rows) if not isinstance(rows, Sequence) else rows
        for index, chunk in enumerate(iter_chunked(materialized, self.chunk_size)):
            if index < start_chunk:
                skipped += 1
                continue
            chunks += 1
            payload = {**(extra or {}), rows_key: list(chunk)}
            self._invoke_chunk(rpc_name, payload, index)
            sent += len(chunk)
            self._log(f"{rpc_name} chunk={index} rows={len(chunk)} total={sent}")
        return {"chunks": chunks, "rows": sent, "skipped": skipped}

    def _invoke_chunk(
        self,
        rpc_name: str,
        payload: dict[str, Any],
        index: int,
    ) -> None:
        delay = 0.4
        last: Exception | None = None
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                self.rpc(rpc_name, payload)
                return
            except LoaderError as exc:
                last = exc
                if attempt == MAX_RETRIES:
                    raise LoaderError(
                        f"{rpc_name} chunk {index} failed: {exc}",
                        chunk_index=index,
                    ) from exc
                self._log(
                    f"{rpc_name} chunk={index} retry={attempt} key={_redact_secret(self._key)}"
                )
                self._sleep(delay)
                delay *= 2
        if last:
            raise last


def loader_from_env(
    *,
    url: str | None = None,
    chunk_size: int = DEFAULT_CHUNK_SIZE,
    dry_run: bool = False,
    log: Callable[[str], None] | None = None,
) -> ServiceRoleLoader:
    return ServiceRoleLoader(
        url=env_supabase_url(url),
        service_role_key="" if dry_run else env_service_role_key(),
        chunk_size=chunk_size,
        dry_run=dry_run,
        log=log,
    )
