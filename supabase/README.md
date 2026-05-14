# Supabase

SQL contracts for the Carzon backend.

## Layout
- `migrations/` — ordered, append-only SQL migrations (timestamp-prefixed).
- `config.toml` — includes `verify_jwt = false` for **`process-message-notifications`** only.
- `../docs/ops_message_notifications.md` — runbook for Phase 3E Vault + cron worker.
- `seed.sql` — synthetic local/demo data for Carzon. Safe to re-run.
- `demo/` — temporary UI-development-only data kept strictly
  separate from the production seed flow. See
  [`demo/README.md`](demo/README.md). Never applied automatically.

## Apply manually (no Supabase CLI required)
1. Open the Supabase Dashboard → SQL Editor for the project.
2. Run the files in `migrations/` in chronological order.
3. (Optional, local/dev only) Run `seed.sql` to insert the demo listings.
4. If the chain includes **`20260529120000_schedule_process_message_notifications_cron.sql`**, create the two **Vault** secrets documented in **[`../docs/ops_message_notifications.md`](../docs/ops_message_notifications.md)** so pg_cron can invoke **`process-message-notifications`** (nothing sensitive belongs in git).

## Apply via Supabase CLI (when connected)
```bash
supabase link --project-ref <ref>
supabase db push
supabase db reset    # also runs seed.sql
```

## Demo / seed data

`seed.sql` is designed for local and demo use only. It is **not**
applied automatically to production — `supabase db push` does not run
the seed file. It only runs as part of `supabase db reset` (local
stacks) or when you execute `seed.sql` explicitly in the SQL Editor.

Properties of the seed dataset:

- **Synthetic**: all rows are fake. No real people, no real phone
  numbers, no real seller identities.
- **Phone pattern**: every row uses `+373 000 000 XXX`, which is an
  obviously-non-personal placeholder.
- **Telegram usernames**: where present, they use the `carzon_demo_NN`
  pattern.
- **Stable UUIDs**: each row has a deterministic `uuid`, and every
  insert uses `on conflict (id) do update` so re-running `seed.sql`
  converges on the latest values without duplicating rows.
- **Coverage**: at least 12 active Transnistria listings, at least 4
  active Moldova listings, and a handful of non-active rows
  (`hidden` / `sold` / `archived`) to help reason about status
  visibility while browsing the database directly. The public feed
  RLS policy hides non-active rows from the app.
- **No `seller_id`**: seed rows are inserted with `seller_id = null`.
  They are publicly readable because the public-read policy filters
  only on `status = 'active'`, but they are intentionally un-owned
  and therefore **not editable** through the mobile app. Owner flows
  (create / edit / change status / delete) must still be exercised
  with real authenticated users creating listings through the UI.
- **No RLS / schema changes**: `seed.sql` contains no
  `create policy`, `alter policy`, `drop policy`, `alter table`, or
  migration-like statements. It only inserts data.

### How the seed is loaded

`seed.sql` is executed by the Supabase CLI as a superuser during
`supabase db reset`, which bypasses row-level security. This lets the
seed insert rows with `seller_id = null` even though
`listings_insert_own` would forbid that for a normal authenticated
user. This is a deliberate dev-ergonomics tradeoff and is safe because
the file is never part of a production deploy.

### Refreshing the demo data

To get a clean slate locally:

```bash
supabase db reset
```

This rebuilds the local schema from `migrations/` and then re-applies
`seed.sql`. The seed is idempotent, so you can also just re-run it
against an existing local DB without resetting.
