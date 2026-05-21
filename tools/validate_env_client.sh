#!/usr/bin/env bash
# Validates .env.client before local Flutter runs (no secret values printed).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.env.client"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing .env.client — copy .env.client.example to .env.client and fill client-safe values." >&2
  exit 1
fi

forbidden_patterns=(
  SERVICE_ROLE
  SUPABASE_SERVICE_ROLE_KEY
  FCM_SERVICE_ACCOUNT_JSON
  FCM_PRIVATE_KEY
  FCM_CLIENT_EMAIL
  FCM_PROJECT_ID
  CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET
  CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET
  CARZON_PROCESS_VIN_DECODE_JOBS_SECRET
  PRIVATE_KEY
  'BEGIN PRIVATE KEY'
  VIN_PROVIDER
  INTERNAL_SECRET
)

while IFS= read -r line || [[ -n "${line}" ]]; do
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ -z "${trimmed}" ]] && continue
  [[ "${trimmed}" == \#* ]] && continue
  if [[ "${trimmed}" != *=* ]]; then
    echo "Invalid line in .env.client (expected KEY=value)." >&2
    exit 1
  fi
  key="${trimmed%%=*}"
  key="${key%"${key##*[![:space:]]}"}"
  key="${key#"${key%%[![:space:]]*}"}"
  value="${trimmed#*=}"
  upper_key="$(printf '%s' "${key}" | tr '[:lower:]' '[:upper:]')"

  for pattern in "${forbidden_patterns[@]}"; do
    if [[ "${upper_key}" == *"${pattern}"* ]]; then
      echo "Forbidden key in .env.client: ${key}" >&2
      exit 1
    fi
  done

  if [[ "${key}" == "SUPABASE_URL" || "${key}" == "SUPABASE_ANON_KEY" ]]; then
    stripped_value="${value#"${value%%[![:space:]]*}"}"
    stripped_value="${stripped_value%"${stripped_value##*[![:space:]]}"}"
    if [[ -z "${stripped_value}" ]]; then
      echo "Missing or empty required key: ${key}" >&2
      exit 1
    fi
  fi
done < "${ENV_FILE}"

# Ensure required keys exist at least once.
for required in SUPABASE_URL SUPABASE_ANON_KEY; do
  if ! grep -qE "^[[:space:]]*${required}=" "${ENV_FILE}"; then
    echo "Missing required key: ${required}" >&2
    exit 1
  fi
done

exit 0
