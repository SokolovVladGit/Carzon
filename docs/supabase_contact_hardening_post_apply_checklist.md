# Contact Hardening — Post-Apply Verification Checklist

## Hosted status — **closed (2026-06)**

SQL metadata PASS and simulator smoke PASS on hosted Carzon. Use this checklist for **re-verification** after future hosted changes or optional anon-only PostgREST proof.

---

Use after `supabase/maintenance/check_contact_hardening.sql` reports `overall_sql_metadata_result` = **PASS**.

Single hosted project (no staging). Read-only PostgREST checks + manual Flutter smoke. No service-role key.

Prepare **outside the repo**: `<SUPABASE_URL>`, `<ANON_KEY>`, `<ACTIVE_LISTING_ID>`, `<INACTIVE_OR_DRAFT_LISTING_ID>`, `<OWNER_JWT>` (optional), `<NON_OWNER_LISTING_ID>` (optional).

Carzon has no `draft` status — use hidden, sold, or archived for inactive.

---

## Minimal anon-only Phase 3

**For non-technical owners.** No JWT. No service-role key. Only:

- `<SUPABASE_URL>` — from Supabase Dashboard → Project Settings → API
- `<ANON_KEY>` — same page (anon / public key); keep local, never commit
- `<ACTIVE_LISTING_ID>` — UUID of a listing that is **active** in the app
- `<INACTIVE_OR_DRAFT_LISTING_ID>` — optional; hidden, sold, or archived listing

Run in Terminal (macOS/Linux). Replace placeholders, then press Enter.

### How to find an active listing ID

- Open any **active** listing in the Carzon app and copy its ID from the detail URL or from Supabase Dashboard → Table Editor → `listings` → `id` column.
- Use an listing you already have — **do not create** test data just for this check.
- Redact `<ANON_KEY>` in screenshots or notes shared with others.

### A) Protected listing contact — direct select must fail

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/listings?select=id,contact_phone,telegram_username,whatsapp_enabled&limit=1' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

**PASS:** HTTP error about inaccessible columns / permission denied, **or** response has no `contact_phone`, `telegram_username`, `whatsapp_enabled` values.  
**STOP:** JSON array includes any of those contact fields with real values.

### B) Protected image `storage_path` — direct select must fail

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/listing_images?select=id,storage_path&limit=1' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

**PASS:** HTTP error / permission denied, **or** no `storage_path` in the response.  
**STOP:** JSON array includes `storage_path` values.

### C) Active listing — public contact RPC must work

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<ACTIVE_LISTING_ID>"}'
```

**PASS:** HTTP 200. Body is a contact object or array; fields may be null if the listing has no contact data — the call itself is allowed for an active listing.  
**STOP:** RPC fails for a known active listing that should have contact, or returns full listing fields beyond contact.

### D) Optional — inactive listing contact RPC must not expose

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<INACTIVE_OR_DRAFT_LISTING_ID>"}'
```

**PASS:** Empty array `[]`, empty object, or no contact values.  
**STOP:** Real `contact_phone`, `telegram_username`, or usable WhatsApp data for inactive/hidden/sold/archived/deleted listing.

Skip D if you have no inactive listing ID — note **PARTIAL** and rely on SQL metadata PASS.

### Close without JWT

If **all** of the following are true, you may close **public direct exposure** hardening without owner JWT checks:

1. SQL helper: `overall_sql_metadata_result` = **PASS** (already done).
2. Minimal anon-only checks **A–C** = **PASS** (and **D** if you ran it).
3. Phase 4 Flutter smoke (below) = **PASS**.

Owner edit RPC with `<OWNER_JWT>` is **optional** — opening **Edit listing** in the app and seeing contact/gallery prefill covers owner access for closure purposes.

---

## A) Full Phase 3 — PostgREST / API checks (optional advanced)

Run from terminal; replace placeholders. Do not commit keys or IDs.

### 1. Anon — forbidden listing contact columns

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/listings?id=eq.<ACTIVE_LISTING_ID>&select=id,contact_phone,telegram_username,whatsapp_enabled' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

**PASS:** HTTP error (400/401/403) or empty body — no contact values.  
**STOP:** HTTP 200 with `contact_phone`, `telegram_username`, or `whatsapp_enabled`.

### 2. Anon — forbidden `listing_images.storage_path`

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/listing_images?listing_id=eq.<ACTIVE_LISTING_ID>&select=id,storage_path' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

**PASS:** Error or no `storage_path` values.  
**STOP:** HTTP 200 with `storage_path`.

### 3. Anon — contact RPC for active listing

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<ACTIVE_LISTING_ID>"}'
```

**PASS:** HTTP 200; response is contact fields only (`contact_phone`, `telegram_username`, `whatsapp_enabled`) — values may be null if listing has no contact data.  
**STOP:** RPC fails for a known active listing with contact data, or returns extra listing fields.

### 4. Anon — contact RPC for inactive listing

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<INACTIVE_OR_DRAFT_LISTING_ID>"}'
```

**PASS:** HTTP 200 with `[]`, `{}`, or null-equivalent — no contact values.  
**STOP:** Any contact values returned.

Optional — deleted / nonexistent:

```bash
--data '{"p_listing_id":"00000000-0000-0000-0000-000000000000"}'
```

Expect same as inactive (no contact).

### 5. Optional — owner edit RPC

Owner:

```bash
curl -sS -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <OWNER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<ACTIVE_LISTING_ID>"}'
```

**PASS:** HTTP 200; row includes `contact_phone`, `telegram_username`, `whatsapp_enabled` (owner prefill).

Non-owner (optional):

```bash
--data '{"p_listing_id":"<NON_OWNER_LISTING_ID>"}'
```

**PASS:** Error / no usable row. **STOP:** Full listing row for non-owner.

---

## B) Phase 4 — Flutter smoke checks

App pointed at same hosted project (`SUPABASE_URL` + `SUPABASE_ANON_KEY` only). Inspect network if possible.

| # | Check | PASS |
|---|---|---|
| 1 | Feed loads | Listings visible |
| 2 | Listing detail opens | Detail screen loads |
| 3 | Detail initial payload | No `contact_phone`, `telegram_username`, `whatsapp_enabled` before reveal |
| 4 | Contact reveal | Tap show phone / contact → RPC succeeds; phone/Telegram/WhatsApp work |
| 5 | Listing images | Gallery / cover images display |
| 6 | Owner edit | Opens; pre-fills contact + gallery for owned listing |
| 7 | Seller profile | Opens; no actual phone/Telegram/WhatsApp/email values |
| 8 | Messaging | Inbox and thread open |

---

## C) PASS / STOP criteria

### PASS (close hardening item)

**Minimal path (recommended):**

- SQL metadata: `overall_sql_metadata_result` = **PASS** (done).
- Minimal anon-only Phase 3: checks **A–C** PASS (**D** if inactive ID available).
- Phase 4 smoke: all rows PASS.
- Owner JWT check **not required** if owner edit smoke (row 6) passes.

**Full path (optional):** all items in Full Phase 3 section below, plus Phase 4 smoke.

### STOP (do not close)

- Anon direct select returns protected column values.
- Active listing contact reveal broken.
- Owner edit or gallery prefill broken.
- Listing images broken.
- Inactive listing contact exposed via RPC or direct select.

On STOP: capture HTTP status + sanitized response shape (no secrets); escalate to tech lead. Do not re-grant broad contact SELECT without owner decision.

---

## D) Final closure

**Can mark closed:**

> Seller contact direct data exposure hardening closed at hosted metadata + API + smoke level.

**Remains separate (not blockers for this closure):**

- Product decision: anon-callable `get_listing_public_contact` (by design today).
- Rate limiting / audit logging on contact RPC.
- Dedicated staging project when a Supabase slot is available.

**Suggested one-line release note:**

> Applied contact hardening on hosted Supabase: public listing reads no longer expose contact columns or image storage paths; contact reveal uses explicit RPC for active listings only; verified via SQL metadata, PostgREST, and app smoke.
