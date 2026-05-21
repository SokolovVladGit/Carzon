#!/usr/bin/env bash
# Local debug run with client-safe compile-time config (no secrets in script).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

"${ROOT}/tools/validate_env_client.sh"
echo "Running: flutter run --dart-define-from-file=.env.client" >&2
exec flutter run --dart-define-from-file=.env.client "$@"
