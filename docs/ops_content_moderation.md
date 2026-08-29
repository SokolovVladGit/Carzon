# Content moderation operations

## Scope and response target

CARZON accepts reports for:

- public vehicle listings, including their text and images;
- the other participant in a buyer/seller conversation, including relevant
  buyer/seller messages and image attachments.

Support conversations provide a direct support/operator context. They are not
submitted through `report_user(...)`, which deliberately rejects support
conversations.

Review every new abuse report within **24 hours**. Threats, suspected fraud,
illegal content, child-safety concerns, or repeated abuse must be escalated to
the product owner immediately rather than waiting for the routine queue.

There is no automated image moderation. Images are investigated by a human
operator from the listing or conversation context attached to the report.

## Storage and access boundaries

- `public.user_reports` stores conversation/user reports.
- `public.listing_reports` stores structured listing reports.
- Both tables have RLS enabled and no `anon` or `authenticated` table access.
- `report_user(...)` and `report_listing(...)` derive reporter/subject IDs on
  the server. Clients cannot spoof reporter IDs or update report status.
- `moderation_list_pending_reports(...)` and
  `moderation_update_report_status(...)` are granted only to `service_role`.
  Never place a service-role key in the mobile client or a committed file.

The listing snapshot intentionally contains only title, a capped description,
make/model/year, and pseudonymous UUID context. It excludes contact fields,
full VIN, image URLs, and storage paths.

## Inspect the pending queue

Run as a trusted operator in the Supabase SQL Editor, or through an equivalent
server-side service-role session:

```sql
select jsonb_pretty(report)
from public.moderation_list_pending_reports(100) as report;
```

Oldest reports are returned first. For a listing report, compare its immutable
snapshot with the current listing when `listing_id` still exists. For a user
report, inspect the validated conversation and listing UUID context. Review
message attachments only from trusted operator tooling; do not copy private
chat text into general-purpose logs.

## Investigation and enforcement

1. Confirm the reported content and whether the source still exists.
2. Check earlier reports for the same listing/user UUID and identify repeated
   behavior.
3. For violating listing content, set the listing to `hidden` using trusted
   operator SQL or have the owner remove it through the existing owner flow.
4. For a violating seller profile, a trusted operator can set
   `seller_profiles.moderation_status` to `hidden` or `suspended`. Account-level
   suspension or deletion is performed by the owner through supported Supabase
   Auth administration, never from the mobile client.
5. For message/image abuse, preserve only the evidence needed for the report.
   Users can block peers in-app; a block prevents new listing conversations,
   messages, and notifications in both directions.
6. Record a concise moderation note and transition the report status.

Example status transitions:

```sql
select public.moderation_update_report_status(
  'listing',
  '<REPORT_UUID>'::uuid,
  'resolved',
  'Listing hidden after operator review.'
);

select public.moderation_update_report_status(
  'user',
  '<REPORT_UUID>'::uuid,
  'dismissed',
  'No policy violation found.'
);
```

Allowed operator statuses are `reviewed`, `dismissed`, and `resolved`.
`reviewed_at` is set on the first transition; `resolved_at` is set for
`dismissed` or `resolved`.

## Text filtering

Server-side triggers filter changed user-authored text in listings, seller
display names, and buyer/seller and support messages. Private report notes are
not filtered because reporters may need to quote the material being reported;
their existing length limits still apply. The private
`carzon_private.moderation_text_rules` table holds the small RU/RO/EN baseline.
Rules normalize case, whitespace, punctuation/separator evasion, Romanian
diacritics, and common numeric substitutions. Rejections use the stable code
`carzon_content_rejected` and do not log the rejected raw text.

Only a trusted database operator may alter the rules. Test normal text and
false-positive cases before enabling a new rule. Monitor rejection patterns and
tune lexical rules for false positives and newly observed evasion patterns.

## Retention after account or content deletion

Moderation reports remain for safety, abuse investigation, duplicate detection,
and escalation. Live foreign keys may become null; pseudonymized original UUIDs,
reason/note, minimal listing snapshot, status, and timestamps remain immutable.
Profile/contact data, full VIN, listing image URLs, conversation history, and
attachments are not copied into listing-report snapshots.

Account deletion may separately leave a VIN hash/normalized vehicle cache and
generic model, recall, or fuel caches. These are not active account/profile
records. The in-app deletion warning and legal copy disclose these categories.

## Deployment order and smoke check

Apply `20260826120000_app_store_content_moderation_foundation.sql` manually to
the target project before shipping a client that calls `report_listing`.
No Edge Function deployment is required.

After application:

1. Submit one report from a disposable authenticated account.
2. Confirm a second immediate submission returns the existing pending report.
3. Confirm `anon` and `authenticated` cannot select/update report tables.
4. Confirm the service-role queue returns the report.
5. Transition it to `resolved` and confirm both timestamps.
6. Submit separated/case-varied objectionable test text in staging and confirm
   `carzon_content_rejected`; confirm ordinary RU/RO vehicle text persists.
