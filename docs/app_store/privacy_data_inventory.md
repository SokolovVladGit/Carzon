# CARZON privacy and data inventory

Verified against the repository and the hosted Supabase project (read-only) on
24 August 2026. Hosted migration `20260826120000` was present. This inventory
describes the current release implementation, not every category Apple offers.

## Data inventory

| Category | Collected/transmitted and purpose | Linked | Retention and deletion | Tracking |
|---|---|---:|---|---:|
| Account email | Supabase Auth receives email for signup, login, recovery and account administration. It is not a public listing contact. | Yes | Active until account deletion; auth user is deleted by `delete-own-account`. Provider backup/log cycles may lag active deletion. | No |
| Display name and avatar | Public seller identity and profile image/path. | Yes | Deleted with the auth user; avatar object is explicitly removed from Storage. | No |
| Phone, Telegram, WhatsApp flag | Optional listing contacts, retrieved through explicit contact/owner RPCs and disclosed to listing viewers. | Yes | Stored with the listing; removed with listing/account deletion. | No |
| Supabase UUID | Joins the account to listings, profiles, messages, preferences and moderation operations. | Yes | Active relationships cascade or are cleared on deletion. Original UUID snapshots can remain in pseudonymized moderation evidence. | No |
| FCM/APNs/install identifiers | FCM token, platform, optional device ID, app version, locale and activity timestamps support push. Firebase associates the APNs token with a Firebase installation/FCM registration token and processes device/app technical fields. | Yes in CARZON token table; Firebase installation data is device/app scoped | Token records cascade on account deletion and can be deactivated. Firebase/Apple apply their operational retention. | No |
| Anonymous listing-view identifier | A random UUID is created in local preferences. CARZON sends it to `record_listing_view`; the database stores only a SHA-256 viewer hash scoped to daily deduplication. Signed-in views use a hash derived from the account UUID. | Guest: No; signed-in: derived from account ID | Daily dedupe rows are listing-scoped and removed when the listing is deleted. The local guest ID remains until app data is cleared/reinstalled. | No |
| Listing and vehicle content | Title, description, make/model/year, price, mileage, city/market, registration, specifications, status and contact fields operate the marketplace. | Yes | Stored while the listing/account is active; deleted with the listing/account. A limited title/description/vehicle snapshot can remain if the listing was reported. | No |
| Listing photos | Public URLs and owner storage paths for listing galleries. | Yes | Removed when the listing/account is deleted, including owner-prefixed Storage objects. | No |
| VIN | Full normalized VIN is stored in the owner-only vehicle identity row and sent server-side to NHTSA vPIC for decoding. Public listing data exposes only a status/safe normalized summary. | Yes while listing exists | Listing-linked identity is deleted with the listing. VIN hash and normalized provider/cache results can survive without an active account/profile where database relationships intentionally allow it. | No |
| Messages and chat images | Buyer/seller and support message text, conversation membership, previews, read/mute state and image attachment metadata/objects. | Yes | Conversation/message rows cascade with account/listing relationships; owner-prefixed chat objects are explicitly removed on account deletion. A report retains only its own note/reason/IDs, not the conversation history or attachment. | No |
| Support conversations | Support chat content and attachments; public email support is also available when configured. | Yes | Same deletion behavior as messages. Email provider handling is outside the repository and requires the owner-selected mailbox. | No |
| Reports and moderation evidence | Report reason/note, status and limited snapshots; live reporter/subject/listing/conversation references plus immutable original UUID snapshots. | Yes at submission; pseudonymized after referenced deletion | Intentionally retained for safety, abuse investigation and dispute handling. Live foreign keys use `ON DELETE SET NULL`; retained evidence is not an active profile/contact record. No fixed period is defined. | No |
| Favorites | User-to-listing relationship for saved vehicles and price-drop functionality. | Yes | Cascades on account or listing deletion. | No |
| Saved searches/filter alerts | User name, structured criteria, enablement and notification timestamps. | Yes | Cascades on account deletion; a search can be deleted in-app. | No |
| Notification preferences | Global, message, filter-alert and price-drop enablement. | Yes | Cascades on account deletion; editable in-app. | No |
| Listing views/counters | Per-listing aggregate/daily counters and hashed per-day dedupe identifiers provide visible counts and limited operational analytics. | Aggregate: No; dedupe may derive from account ID | Listing-scoped and removed with listing deletion. | No |
| User blocks | Blocker and blocked UUIDs enforce messaging safety. | Yes | Cascades when either account is deleted; manageable in-app. | No |
| User-entered location | Listing city, marketplace region and vehicle registration region are content/filter fields. | Yes when submitted with listing | Follows listing/account retention. | No |
| Device location | No GPS, precise location, geolocation SDK or device-derived location collection found. | No | Not collected. | No |
| Firebase/SDK diagnostics | FirebaseCore declares no collection; FirebaseMessaging, FirebaseInstallations and GoogleDataTransport process installation/push fields and limited SDK performance metadata described in Firebase's Apple disclosure guide. No Firebase Analytics or Crashlytics dependency was found. | Primarily device/app scoped; not deliberately joined to a CARZON profile except the CARZON FCM-token row | Provider operational retention applies; CARZON token row is deleted/deactivated as above. | No |

## External processing and reference requests

- **Supabase:** Auth, Postgres, Storage, Realtime, Data API and Edge Functions
  host CARZON-controlled account and marketplace data in the configured project.
- **Firebase/Google and Apple APNs:** receive push identifiers, device/app
  delivery metadata and notification payloads when push is enabled.
- **NHTSA vPIC:** receives the full normalized VIN. NHTSA recall requests receive
  make, model and year.
- **EPA/FuelEconomy.gov:** receives make, model and year candidates.
- **ANRE and Sheriff:** server-side requests read public fuel information. No
  CARZON user identity fields are included in these request builders.
- External endpoints can still receive ordinary server network metadata such as
  the CARZON worker IP address, HTTP headers and request time.

## Evidence

- `supabase/functions/delete-own-account/index.ts`
- `supabase/migrations/20260701120000_listing_view_counting.sql`
- `supabase/migrations/20260713120000_delete_own_account.sql`
- `supabase/migrations/20260823120000_retain_pseudonymized_moderation_reports.sql`
- `supabase/migrations/20260826120000_app_store_content_moderation_foundation.sql`
- `supabase/functions/process-vin-decode-jobs/providers/nhtsa_provider.ts`
- `supabase/functions/process-model-data-jobs/providers/epa_provider.ts`
- `supabase/functions/process-recall-data-jobs/providers/nhtsa_provider.ts`
- `lib/features/listings/data/local/anonymous_viewer_id_repository.dart`
- `lib/features/notifications/services/firebase_push_messaging_client.dart`
- hosted `information_schema` and migration-history read-only queries, 24 August 2026
