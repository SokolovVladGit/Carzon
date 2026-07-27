# Hosted migration parity verification

## Hosted status — **closed (27 July 2026)**

**Confirmed on hosted Carzon:**

- **71/71** local migrations applied and recorded through
  `20260823120000_retain_pseudonymized_moderation_reports.sql`
- Moderation-report retention verified: all four `public.user_reports` foreign
  keys use `ON DELETE SET NULL`; original-evidence snapshot columns and
  `protect_user_report_original_evidence_before_update` exist; affected
  functions have the expected security/search path configuration
- No additional SQL is pending from the current local migration chain
- Fuel Prices trilogy applied hosted: `20260822120000_fuel_prices_foundation`, `20260822123000_schedule_process_fuel_price_jobs_cron`, `20260822130000_fix_fuel_price_job_reenqueue`
- **`process-fuel-price-jobs`** Edge Function deployed **ACTIVE v3**; cron **`carzon_process_fuel_price_jobs_6h`** active; Vault secrets synced — see **`docs/ops_fuel_price_jobs.md`**
- `check_hosted_runtime_contracts.sql` → PASS (no STOP/WARN) at last full audit; re-run after hosted changes
- Prior parity STOP (33 missing metadata rows, 2026-06) resolved via **metadata reconciliation** — not migration re-apply

Re-run helpers before future releases or after any hosted SQL change.

---

## Purpose

Confirm that the **hosted Supabase project** has every migration from `supabase/migrations/` recorded in `supabase_migrations.schema_migrations`.

Static migration tests in the repo and a green `flutter analyze` **do not** prove the hosted database matches the app binary. Missing migration metadata is a **release blocker** because the app may call RPCs, columns, or policies that do not exist on hosted.

This check is **read-only** and does **not** apply migrations.

## When to run

- Before any release or staging promotion.
- After manual SQL apply (e.g. contact hardening) to confirm metadata was inserted.
- When investigating runtime PostgREST/RPC failures that suggest partial backend apply.

**Staging preferred:** run on a staging project first when one exists.

**Single project:** safe on the only hosted project — the helper uses **SELECT only** (no DDL/DML/grants).

## How to run

1. Open **Supabase Dashboard → SQL Editor** on the target project.
2. Paste the **entire** file:
   **`supabase/maintenance/check_hosted_migration_parity.sql`**
3. Run once.
4. Copy or screenshot the **full** result table.

### Output columns

| Column | Meaning |
|--------|---------|
| `version` | Migration timestamp from repo filename, or `info` / `overall` for summary rows |
| `migration_name` | Repo migration name (filename suffix) |
| `category` | Rough area: listings, messaging, VIN, contact hardening, etc. |
| `status` | `PASS`, `STOP`, or `INFO` |
| `details` | Human-readable explanation |

## Interpreting results

### `hosted_migration_parity_result` = **PASS**

All **71** repo migrations in the parity helper inventory are recorded in
hosted `schema_migrations` by **version**. As verified **27 July 2026**, the
latest applied migration is
`20260823120000_retain_pseudonymized_moderation_reports.sql`. A PASS requires
full inventory match — update `check_hosted_migration_parity.sql` when adding
new migration files.

**Next steps (do not skip):**

- Run feature-specific verification as needed (e.g. `supabase/maintenance/check_contact_hardening.sql` for contact exposure).
- Confirm Auth **Site URL** and other release config (`docs/RELEASE.md`, `docs/project_milestones.md`).
- Run manual release smoke on device/simulator.

**Limitation:** PASS means **metadata parity only**. It does not prove every RPC, cron job, Edge Function, or Vault secret works at runtime.

### `hosted_migration_parity_result` = **STOP**

One or more repo migration **versions** are missing from hosted `schema_migrations`.

**Important:** STOP here means **metadata is missing**, not necessarily that SQL objects are missing. Manual applies (especially contact hardening) often update the database without inserting `schema_migrations` rows. If the app works in simulator, run the runtime contract helper next.

**Do not:**

- Auto-apply missing migrations from this runbook.
- Bulk-apply all missing versions because parity says STOP.
- Assume missing metadata means objects are missing (or present).

**Do:**

1. Note the missing `version` values from rows with `status = STOP`.
2. Run **`supabase/maintenance/check_hosted_runtime_contracts.sql`** (read-only runtime triage).
3. Use the decision rules below before any apply planning.

### Runtime triage after parity STOP

When parity is **STOP** but the app appears to work, run:

**`supabase/maintenance/check_hosted_runtime_contracts.sql`**

Output: `area | check_name | status | details` plus `overall_runtime_contract_result`.

| Parity | Runtime overall | Meaning | Next step |
|--------|-----------------|---------|-----------|
| STOP | **PASS** | Objects exist; metadata drift only | **Metadata reconciliation** — `docs/hosted_migration_metadata_reconciliation.md` + `generate_missing_migration_metadata_inserts.sql` (do **not** re-run migration SQL) |
| STOP | **STOP** | App-critical objects actually missing | Plan **targeted apply by group** (listings, messaging, VIN, etc.) — one group at a time |
| STOP | **WARN** only | Core client contracts OK; cron/background gaps | Manual review; may ship MVP without live push/VIN decode workers |
| PASS | any | Metadata matches repo | Feature verification + manual smoke still required |

**Do not bulk-apply 33 migrations blindly** when runtime PASS suggests metadata-only drift.

### `INFO` rows

- **`parity_check_scope`** — explains what the helper checks.
- **`hosted_only_migrations`** — hosted versions not in repo inventory (manual review; does not fail overall).

## Version vs name

The helper compares **`version` only** (e.g. `20260630120000`). Hosted `schema_migrations.name` may differ slightly from the repo filename suffix; that is acceptable if the version matches.

After manual SQL Editor apply, always insert the matching metadata row (see contact hardening apply guide § metadata insert).

## Related docs

- Release checklist: `docs/RELEASE.md` (§3 migration order — note June 2026 migrations may not be fully listed there yet).
- **Metadata reconciliation (parity STOP + runtime PASS):** `docs/hosted_migration_metadata_reconciliation.md`
- **Generate metadata INSERT text:** `supabase/maintenance/generate_missing_migration_metadata_inserts.sql`
- **Runtime contract triage:** `supabase/maintenance/check_hosted_runtime_contracts.sql` (run after parity STOP).
- Contact hardening verification: `docs/supabase_contact_hardening_verification.md`
- Contact hardening SQL helper: `supabase/maintenance/check_contact_hardening.sql`
- Fuel Prices worker: `docs/ops_fuel_price_jobs.md`
- Release inventory: `docs/release_hardening_inventory.md`

## Inventory source

Expected migrations are embedded in `check_hosted_migration_parity.sql` from filenames under `supabase/migrations/`. When new migrations are added to the repo, update that helper in the same commit as the new migration file.
