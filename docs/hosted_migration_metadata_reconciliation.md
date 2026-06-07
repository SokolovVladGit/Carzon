# Hosted migration metadata reconciliation

## Completed reconciliation — **hosted Carzon (2026-06)**

**Resolved:** Parity was STOP (33 missing `schema_migrations` rows) while runtime contracts were PASS. Owner approved metadata INSERTs only (no migration SQL re-apply). Final parity: **45/45 PASS**.

This runbook remains for **future** drift if parity STOP recurs with runtime PASS.

---

## When to use this runbook

Use when **both** of the following are true on the hosted Supabase project:

| Check | File | Required result |
|-------|------|-----------------|
| Migration parity | `supabase/maintenance/check_hosted_migration_parity.sql` | `hosted_migration_parity_result` = **STOP** |
| Runtime contracts | `supabase/maintenance/check_hosted_runtime_contracts.sql` | `overall_runtime_contract_result` = **PASS** (no STOP) |

That combination means **metadata drift**: SQL objects the app needs are already present, but `supabase_migrations.schema_migrations` does not list all repo migration versions. Common causes:

- Migrations applied manually in SQL Editor without recording metadata
- Early project setup before migration tracking was consistent
- Partial metadata insert (e.g. only contact hardening row added later)

**Do not re-run migration `.sql` files** in this situation. Re-applying 33 migrations when runtime objects already exist risks errors, duplicate objects, or destructive `DROP`/`CREATE` side effects.

---

## What reconciliation does

Reconciliation **only** inserts rows into `supabase_migrations.schema_migrations`:

```sql
insert into supabase_migrations.schema_migrations (version, name)
values ('20260503120000', 'create_listing_rpc')
on conflict (version) do nothing;
```

### Does

- Records which repo migration versions are considered applied on hosted
- Aligns Supabase CLI / parity tooling with actual backend state
- Uses `ON CONFLICT DO NOTHING` so re-running is idempotent

### Does not

- Change app data (listings, messages, users, etc.)
- Create or alter tables, columns, indexes, triggers
- Change RLS policies, RPC bodies, grants, or revokes
- Run any migration SQL from `supabase/migrations/`

It is still a **hosted database write** (metadata table only) and requires **explicit owner approval**.

---

## Repo migration inventory (45 versions)

Expected versions are embedded in:

- `supabase/maintenance/check_hosted_migration_parity.sql`
- `supabase/maintenance/generate_missing_migration_metadata_inserts.sql`

Keep these in sync when adding new migrations to the repo.

### Owner-reported state (2026-06) — **resolved**

- ~~**Missing (33):** `20260503120000` … `20260629120000`~~ → metadata reconciliation completed
- **Final:** 45/45 PASS on `check_hosted_migration_parity.sql`

The generator helper computes the **exact** missing set on hosted at run time — use it if parity STOP recurs.

---

## Step 1 — Confirm gates (read-only)

Already completed per owner report:

1. Parity STOP (33 missing metadata rows)
2. Runtime PASS (all app-critical objects present)

If re-checking:

```text
supabase/maintenance/check_hosted_runtime_contracts.sql  → must be PASS, no STOP
```

**Do not proceed** if runtime reports **STOP** or unresolved **WARN** you care about (cron/push/VIN workers). Fix missing objects first via targeted migration apply — not metadata inserts.

---

## Step 2 — Generate INSERT statements (read-only)

1. Supabase Dashboard → SQL Editor
2. Paste **entire** file: **`supabase/maintenance/generate_missing_migration_metadata_inserts.sql`**
3. Run once
4. Copy output table (especially `all_missing_metadata_inserts` combined row)

Output columns:

| Column | Meaning |
|--------|---------|
| `version` | Repo migration version, or `gate` / `combined` / `summary` |
| `migration_name` | Repo filename suffix |
| `category` | Area label |
| `status` | `MISSING`, `INFO`, `COPY`, `PENDING`, etc. |
| `metadata_insert_sql` | Single INSERT statement, or combined block |

The generator **does not execute** INSERTs — it only returns text.

---

## Step 3 — Owner review and approval

Before running any generated SQL:

1. Review each `MISSING` row — version and name must match repo filenames under `supabase/migrations/`
2. Confirm runtime contracts PASS is still current
3. Confirm you are **not** trying to fix missing objects (only metadata)
4. **Explicit owner approval required** — see approval gate below

---

## Step 4 — Apply metadata (owner-approved write)

> **RUN ONLY AFTER runtime contracts PASS and owner approval.**

1. Open a **new** SQL Editor tab (do not mix with generator script)
2. Paste the **`all_missing_metadata_inserts`** combined block from Step 2
3. Run once
4. Expect one row inserted per missing version (or zero rows if conflict — idempotent)

Do **not** run migration files from `supabase/migrations/` in the same session.

---

## Step 5 — Verify (read-only)

Re-run:

**`supabase/maintenance/check_hosted_migration_parity.sql`**

Expected:

- `hosted_migration_parity_result` = **PASS**
- 45/45 repo migrations recorded

Optional follow-ups:

- `supabase/maintenance/check_contact_hardening.sql` (if not recently PASS)
- Manual release smoke

---

## Owner approval gate

**Do not run metadata INSERT statements until the owner explicitly approves metadata reconciliation for the hosted Carzon Supabase project.**

Approval confirms:

- Runtime contract audit PASS is accepted
- Generated INSERT list was reviewed
- Owner accepts writing to `supabase_migrations.schema_migrations` only
- Owner will not re-run migration SQL as part of this step

---

## Example combined block shape

The generator produces text like (exact versions depend on hosted state):

```sql
-- RUN ONLY AFTER runtime contracts PASS and owner approval.
insert into supabase_migrations.schema_migrations (version, name) values ('20260503120000', 'create_listing_rpc') on conflict (version) do nothing;
insert into supabase_migrations.schema_migrations (version, name) values ('20260504180000', 'create_listing_v2_foundation') on conflict (version) do nothing;
-- ... one line per missing version ...
insert into supabase_migrations.schema_migrations (version, name) values ('20260629120000', 'vin_report_v2b_nhtsa_expanded_summary') on conflict (version) do nothing;
```

---

## Related docs

- Parity verification: `docs/hosted_migration_parity_verification.md`
- Runtime triage: `supabase/maintenance/check_hosted_runtime_contracts.sql`
- Contact hardening manual apply (metadata insert pattern): `docs/manual_supabase_contact_hardening_apply.md` §4B
- Release inventory: `docs/release_hardening_inventory.md`

---

## When NOT to use metadata reconciliation

| Situation | Action |
|-----------|--------|
| Runtime contracts **STOP** | Targeted migration apply for missing groups — not metadata inserts |
| Runtime **WARN** on cron/push/VIN and you need those features live | Fix background objects first; then revisit metadata |
| Parity STOP but objects clearly missing in app | Apply missing migration SQL (one group at a time), then insert metadata for that version |
| Uncertain whether SQL was applied | Re-run runtime helper; do not guess |
