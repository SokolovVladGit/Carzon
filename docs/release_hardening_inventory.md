# Carzon Release Hardening Inventory

## Current release hardening status (hosted Carzon — closed 2026-06)

| Area | Status | Evidence |
|------|--------|----------|
| **Seller contact exposure hardening** | **Closed** | Migration `20260630120000` applied; `check_contact_hardening.sql` → `overall_sql_metadata_result` PASS; simulator smoke PASS |
| **Hosted migration parity** | **Closed** | `check_hosted_migration_parity.sql` → 45/45 repo migrations recorded (`hosted_migration_parity_result` PASS) |
| **Hosted runtime contracts** | **Closed** | `check_hosted_runtime_contracts.sql` → `overall_runtime_contract_result` PASS (no STOP/WARN) |
| **Metadata reconciliation** | **Closed** | Resolved prior parity STOP (33 missing metadata rows) after runtime PASS — metadata inserts only, no migration re-apply |
| **Pagination failure UX** | **Implemented / tested** | `ListingsStatus.paginationFailure` + retry footer; not a release priority unless QA finds regression |

**Optional / not independently confirmed:** anon-only PostgREST contact curls (Phase 3 minimal) — extra API-layer proof; SQL metadata + app smoke are complete.

**Product decision (open):** `get_listing_public_contact` remains callable by **anon** — future rate limiting / auth / audit review if needed.

**Remaining release gates:** Auth Site URL (HTTPS), structured end-to-end release smoke, real-device QA (push if enabled, media picker, auth deep links). See §6 and §4 below.

---

## 1. Scope

This inventory covers the current working-tree hardening changes for:

- Seller contact exposure hardening.
- Supabase manual/staging verification documentation.
- Listings pagination failure UX.
- Create/edit listing media picker and upload reliability.
- Notifications permission, token registration, and tap-routing reliability.
- Auth deep-link, password reset, and session recovery reliability.
- Release readiness docs and manual QA checklists.

Hosted Supabase parity, runtime contracts, and contact hardening are **closed** on the current hosted project (see status table above). Re-run maintenance helpers before future releases or after any hosted SQL change.

## 2. Files To Commit By Area

### A. Seller Contact Exposure Hardening

Backend migration:

- `supabase/migrations/20260630120000_public_contact_projection_hardening.sql`

Listing data/domain/use cases:

- `lib/features/listings/data/datasources/listings_remote_datasource.dart`
- `lib/features/listings/data/models/listing_model.dart`
- `lib/features/listings/data/repositories/listings_repository_impl.dart`
- `lib/features/listings/di/listings_injection.dart`
- `lib/features/listings/domain/entities/listing_contact.dart`
- `lib/features/listings/domain/repositories/listings_repository.dart`
- `lib/features/listings/domain/usecases/get_listing_public_contact.dart`
- `lib/features/listings/presentation/bloc/listing_details_cubit.dart`
- `lib/features/listings/presentation/bloc/listing_details_state.dart`

Listing details UI/contact reveal:

- `lib/features/listings/presentation/pages/listing_details_page.dart`
- `lib/features/listings/presentation/utils/listing_details_uri_launcher.dart`
- `lib/features/listings/presentation/widgets/listing_details_body.dart`
- `lib/features/listings/presentation/widgets/listing_details_contact_bar.dart`
- `lib/features/listings/presentation/widgets/listing_details_content_panel.dart`
- `lib/features/listings/presentation/widgets/listing_details_hero.dart`

Owner edit RPC/client path:

- `lib/features/edit_listing/data/datasources/edit_listing_remote_datasource.dart`
- `lib/features/edit_listing/data/repositories/edit_listing_repository_impl.dart`
- `lib/features/edit_listing/di/edit_listing_injection.dart`
- `lib/features/edit_listing/domain/repositories/edit_listing_repository.dart`
- `lib/features/edit_listing/domain/usecases/get_owner_listing_for_edit.dart`
- `lib/features/edit_listing/domain/usecases/get_owner_listing_images_for_edit.dart`
- `lib/features/edit_listing/presentation/bloc/edit_listing_cubit.dart`
- `lib/features/edit_listing/presentation/bloc/edit_listing_state.dart`
- `lib/features/edit_listing/presentation/pages/edit_listing_page.dart`

Favorites/seller/compare projection or related UI/tests:

- `lib/features/favorites/data/datasources/favorites_remote_datasource.dart`
- `lib/features/favorites/presentation/pages/favorites_page.dart`
- `lib/features/sellers/presentation/bloc/seller_trust_state.dart`
- `lib/features/sellers/presentation/widgets/seller_profile_header_card.dart`
- `test/features/compare/compare_contact_persistence_contract_test.dart`
- `test/features/favorites/favorites_public_listing_projection_test.dart`

Contact hardening tests:

- `test/features/listings/public_listing_projection_contract_test.dart`
- `test/features/listings/listing_details_contact_reveal_test.dart`
- `test/features/listings/listing_details_cubit_test.dart`
- `test/features/listings/listing_model_contact_test.dart`
- `test/supabase/public_contact_projection_hardening_migration_test.dart`
- `test/features/listings/listing_details_body_type_specs_test.dart`
- `test/features/listings/listing_details_gallery_indicator_test.dart`
- `test/features/listings/listing_details_report_test.dart`
- `test/features/listings/listing_details_specs_overflow_test.dart`
- `test/features/listings/listing_details_specs_region_description_test.dart`

### B. Pagination Failure UX

**Status: implemented and tested** — not an open release priority unless manual QA finds a regression.

Bloc/state/page:

- `lib/features/listings/presentation/bloc/listings_bloc.dart`
- `lib/features/listings/presentation/bloc/listings_state.dart`
- `lib/features/listings/presentation/pages/listings_page.dart`

Feed UI components touched in the current tree:

- `lib/features/listings/presentation/widgets/listings_active_discovery_summary_strip.dart`
- `lib/features/listings/presentation/widgets/listings_brand_filter_row.dart`
- `lib/features/listings/presentation/widgets/listings_catalog_header.dart`
- `lib/features/listings/presentation/widgets/listings_search_filter_bar.dart`

Tests:

- `test/features/listings/feed_brand_quick_filter_test.dart`
- `test/features/listings/listings_bloc_discovery_filters_test.dart`
- `test/features/listings/active_discovery_chip_strip_test.dart`
- `test/features/listings/listing_card_test.dart`

Localization:

- `lib/l10n/app_ru.arb`
- `lib/l10n/app_ro.arb`
- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_ru.dart`
- `lib/l10n/app_localizations_ro.dart`

### C. Media Picker / Upload Hardening

Create listing:

- `lib/features/create_listing/presentation/pages/create_listing_page.dart`
- `lib/features/create_listing/presentation/widgets/compose_choice_card.dart`
- `lib/features/create_listing/presentation/widgets/listing_body_type_pick_sheet.dart`
- `lib/features/create_listing/presentation/widgets/listing_type_deal_selector.dart`
- `lib/features/create_listing/presentation/widgets/market_placement_selector.dart`
- `lib/features/create_listing/presentation/widgets/premium_listing_controls.dart`
- `test/features/create_listing/create_listing_page_phase3a_test.dart`

Edit listing:

- `lib/features/edit_listing/presentation/pages/edit_listing_page.dart`
- `lib/features/edit_listing/presentation/widgets/edit_listing_owner_vin_status_section.dart`
- `test/features/edit_listing/edit_listing_cubit_test.dart`
- `test/features/edit_listing/edit_listing_notice_test.dart`
- `test/features/edit_listing/edit_listing_page_phase4c_test.dart`

Manual QA:

- `docs/media_picker_upload_qa.md`

### D. Notifications Hardening

Platform config:

- `android/app/src/main/AndroidManifest.xml`

Notification services/cubit/UI:

- `lib/features/notifications/presentation/cubit/notification_settings_cubit.dart`
- `lib/features/notifications/presentation/pages/notification_settings_page.dart`
- `lib/features/notifications/presentation/widgets/notification_settings_section_card.dart`
- `lib/features/notifications/services/push_notification_registration_service.dart`

Tests:

- `test/features/notifications/notification_settings_cubit_test.dart`
- `test/features/notifications/notification_settings_page_test.dart`
- `test/features/notifications/push_notification_registration_service_test.dart`

Manual QA:

- `docs/notifications_qa.md`

### E. Auth / Deep-Link Hardening

Services/cubits:

- `lib/core/services/auth_deep_link_service.dart`
- `lib/features/auth/presentation/bloc/auth_cubit.dart`
- `lib/features/auth/presentation/bloc/forgot_password_cubit.dart`
- `lib/features/auth/presentation/bloc/reset_password_cubit.dart`

Tests:

- `test/core/services/auth_deep_link_service_test.dart`
- `test/features/auth/auth_cubit_test.dart`
- `test/features/auth/forgot_password_cubit_test.dart`
- `test/features/auth/reset_password_cubit_test.dart`

Manual QA:

- `docs/auth_deeplink_qa.md`

### F. Supabase Operational Docs

- `docs/manual_supabase_contact_hardening_apply.md`
- `docs/supabase_contact_hardening_verification.md`

No separate staging project setup document was found beyond the verification guide. Hosted staging remains deferred until the Supabase plan/project limit allows another project.

### G. Generated Localization Files

Changed ARB inputs:

- `lib/l10n/app_ru.arb`
- `lib/l10n/app_ro.arb`

Changed generated Dart outputs:

- `lib/l10n/app_localizations.dart`
- `lib/l10n/app_localizations_ru.dart`
- `lib/l10n/app_localizations_ro.dart`

Generation appears consistent: changed user-facing keys such as `listingsLoadMoreFailed`, notification settings strings, auth reset strings, and media upload strings are present in ARB and generated Dart outputs.

### H. Other / Unrelated Or Needs Review

These files are changed or untracked but do not map cleanly to one hardening phase above. Review before commit:

- `lib/core/widgets/auth_required_prompt.dart`
- `lib/features/compare/presentation/utils/compare_tray_layout.dart`
- `lib/features/compare/presentation/widgets/compare_empty_states.dart`
- `lib/features/filter_alerts/presentation/pages/filter_alert_settings_page.dart`
- `lib/features/messaging/presentation/pages/conversation_thread_page.dart`
- `lib/features/messaging/presentation/pages/messages_inbox_page.dart`
- `lib/features/messaging/presentation/widgets/messages_inbox_conversation_tile.dart`
- `lib/features/my_listings/presentation/pages/my_listings_page.dart`
- `lib/features/profile/presentation/pages/profile_page.dart`
- `lib/features/profile/presentation/widgets/profile_account_header_card.dart`
- `lib/features/profile/presentation/widgets/profile_activity_messages_row.dart`
- `lib/features/profile/presentation/widgets/profile_grouped_card.dart`
- `lib/features/profile/presentation/widgets/profile_seller_identity_section.dart`
- `lib/features/profile/presentation/widgets/profile_settings_navigation_row.dart`
- `lib/features/profile/presentation/widgets/profile_sign_in_required_prompt.dart`
- `lib/features/profile/presentation/widgets/profile_sign_out_button.dart`
- `test/app/carzon_app_locale_test.dart`
- `test/features/compare/compare_fly_to_tray_runner_test.dart`
- `test/features/compare/compare_tray_fly_cancel_test.dart`
- `test/features/compare/compare_tray_layout_test.dart`
- `test/features/messaging/listing_details_chat_test.dart`
- `test/features/messaging/messages_inbox_conversation_tile_test.dart`
- `test/features/messaging/messaging_dark_theme_test.dart`
- `test/features/messaging/messaging_pages_smoke_test.dart`
- `test/features/my_listings/my_listing_tile_visual_test.dart`
- `test/helpers/compare_cubit_test_helpers.dart`

## 3. Supabase Files / SQL Apply

### Contact hardening — **closed on hosted**

Migration file:

- `supabase/migrations/20260630120000_public_contact_projection_hardening.sql`

**Resolved (2026-06):** Applied on hosted Supabase. Direct public/client SELECT on protected contact columns and `listing_images.storage_path` is blocked. Contact reveal for active listings uses `get_listing_public_contact` RPC only. Verification:

- `supabase/maintenance/check_contact_hardening.sql` → `overall_sql_metadata_result` PASS
- Simulator smoke after apply: PASS
- Apply runbook (historical): `docs/manual_supabase_contact_hardening_apply.md`
- Verification runbook: `docs/supabase_contact_hardening_verification.md`
- Post-apply closure: `docs/supabase_contact_hardening_post_apply_checklist.md`

### Hosted migration parity — **closed on hosted**

**Resolved (2026-06):** `check_hosted_migration_parity.sql` → **45/45** repo migrations recorded. Prior STOP (33 missing metadata rows) was metadata drift; runtime contracts PASS; reconciliation completed without re-applying migration SQL.

Authoritative pre-release helpers (re-run after any hosted change):

- Parity: `supabase/maintenance/check_hosted_migration_parity.sql` — `docs/hosted_migration_parity_verification.md`
- Runtime contracts: `supabase/maintenance/check_hosted_runtime_contracts.sql`
- Metadata reconciliation (if parity STOP + runtime PASS): `docs/hosted_migration_metadata_reconciliation.md` + `generate_missing_migration_metadata_inserts.sql`

Staging preferred when a separate project exists; single-project read-only checks are safe.

Verification workflow (for **future** hosted changes):

## 4. Manual QA Required Before Release

### Contact hardening verification — **closed on hosted (2026-06)**

- [x] SQL Editor: **`check_contact_hardening.sql`** → `overall_sql_metadata_result` PASS
- [x] Migration `20260630120000` applied on hosted; simulator smoke PASS
- [x] Hosted migration parity 45/45; runtime contracts PASS
- [ ] **Optional:** anon-only PostgREST curls — `docs/supabase_contact_hardening_post_apply_checklist.md` § Minimal anon-only Phase 3 (independent API proof; not required if SQL + smoke accepted)

### Remaining manual QA before release

- [ ] Auth **Site URL** HTTPS (not localhost) — Supabase Dashboard; see **`docs/auth_site_url_redirect_configuration.md`**
- [ ] Feed pagination offline/throttled test: existing items stay visible and retry works (regression check; feature implemented)
- [ ] Run `docs/media_picker_upload_qa.md` on Android and iOS
- [ ] Run `docs/notifications_qa.md` on Android and iOS **if** `PUSH_NOTIFICATIONS_ENABLED=true`
- [ ] Run `docs/auth_deeplink_qa.md` on Android and iOS with a real reset email
- [ ] Structured end-to-end smoke: feed, details, create, edit, favorites, compare, messages, profile, notification settings, auth sign-in/sign-out

## 5. Validation Commands To Run Before Commit

```sh
flutter analyze
flutter test test/features/listings/
flutter test test/features/sellers/
flutter test test/features/favorites/
flutter test test/features/compare/
flutter test test/features/create_listing/
flutter test test/features/edit_listing/
flutter test test/features/messaging/
flutter test test/features/my_listings/
flutter test test/features/filter_alerts/
flutter test test/features/notifications/
flutter test test/features/profile/
flutter test test/features/menu/
flutter test test/features/auth/
flutter test test/core/services/auth_deep_link_service_test.dart
flutter test test/supabase/
```

## 6. Release Blockers

**Closed (2026-06 — do not re-open without new hosted evidence):**

- ~~Contact hardening unapplied~~ → applied; SQL metadata PASS; simulator smoke PASS
- ~~Hosted migration parity unknown~~ → 45/45 PASS; metadata reconciliation complete
- ~~Runtime backend contract gaps~~ → runtime helper PASS

**Still open before public release:**

- [ ] Auth **Site URL** set to real **HTTPS** (not `localhost`) — [mvp_release_checklist.md](mvp_release_checklist.md) §C
- [ ] Structured **end-to-end release smoke** on target project (device/simulator)
- [ ] Real-device QA: media picker/upload (`docs/media_picker_upload_qa.md`)
- [ ] Real-device QA: auth deep links / password reset (`docs/auth_deeplink_qa.md`)
- [ ] Real-device push QA **if** shipping with `PUSH_NOTIFICATIONS_ENABLED=true` (`docs/notifications_qa.md`)
- [ ] Working-tree files in section 2.H reviewed before commit (if still applicable)

**Product / optional (not code blockers):**

- Anon-callable `get_listing_public_contact` — accept or plan future rate limiting
- Optional anon-only PostgREST contact curls for independent API proof
- Separate **staging** Supabase project when plan slot available

## 7. Commit Strategy Recommendation

Do not commit everything as one review. Recommended small commits:

1. Contact hardening backend/client/tests/docs.
2. Listings pagination failure UX.
3. Media picker/upload reliability.
4. Notifications permission/token/tap reliability.
5. Auth deep-link/password reset/session reliability.
6. Release docs/inventory.

Before committing, review multi-area files such as `create_listing_page.dart`, `edit_listing_page.dart`, `listings_page.dart`, `notification_settings_page.dart`, and localization outputs so each commit contains only the intended area.
