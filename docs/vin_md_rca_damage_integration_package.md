# Moldova RCA / BNM vehicle damage history — integration package (Phase 3B)

**Status:** specification and outreach only — **no implementation**, **no scraping**, **no assumed legal clearance**.

**Related docs:** `docs/vin_provider_architecture.md`, `docs/ops_vin_decode_jobs.md`.  
**Schema:** `listing_vin_source_results` (`20260623120000_vin_phase2e_listing_vin_source_results.sql` and follow-ons).

**Desk context:** Phase 3A audit (read-only) concluded that **VIN-based vehicle damage history** described on the public **RCA.BNM.MD** portal is high buyer value, but **no confirmed open third-party API** was found for marketplace automation; **unsanctioned portal automation is out of scope**. This package supports **authorized** next steps.

---

## A. Purpose

- **Carzon** wants to **enrich buyer VIN reports** with information that reflects **Moldova insurance-market damage / claim-file signals** tied to a vehicle, where such data is **lawfully obtainable** and **scoped** for display.
- Carzon **will not** scrape **RCA.BNM.MD** (or related portals), **bypass** CAPTCHA, **circumvent** rate limits, or **misuse** consumer flows as headless bots without **written** permission and technical contract terms.
- Carzon seeks either:
  - **read-only partner/API access** (or equivalent **data-sharing agreement**) for **server-side** queries, **or**
  - **written confirmation** that a specific integration pattern is **allowed**, together with **field-level** and **retention** rules.

**Out of scope for this source as “default public buyer data”:** applicant-specific RCA **certificates**, **bonus–malus** tied to natural persons, **RCA policy verification** flows that require **IDNV + plate** without a separate legal/product decision, and **ASP** detailed extracts (owner/consent-heavy). Those remain separate `source_id`s and **visibility** paths per architecture doc.

---

## B. Proposed Carzon `source_id`

| Field | Value |
|--------|--------|
| **`source_id`** | **`md_rca_damage`** (already reserved in taxonomy table in `docs/vin_provider_architecture.md`) |

**Rationale:** short, region-implicit, distinct from future `md_asp_*` or commercial sources.

---

## C. Proposed data category and taxonomy mapping

| Dimension | Proposed value | Notes |
|-----------|----------------|--------|
| **Product data category** | `damage_history` | Insurance-market claim / recorded-damage-style signals (exact legal label TBD with BNM/BNAA). |
| **`region` (DB)** | **`md`** | Matches `listing_vin_source_results.region` constraint. |
| **`confidence` (DB)** | **`unknown`** until written confirmation; then **`official`** *only if* BNM/BNAA (or named regulator) **explicitly** confirms regulatory/official provenance for the channel; otherwise use **`partner`**. | Schema allows `official` \| `partner` \| `commercial` \| `self_reported` \| `basic_decode` \| `unknown` — **no `semi_official`** value; use **`partner`** if the channel is contracted but not “official” in the strict sense. |
| **`access_mode` (DB) — target** | **`carzon_partner_api`** | **If and only if** a **written** agreement allows Carzon to call an **official** server-side endpoint. |
| **`access_mode` — interim (no API)** | **`manual_external_check`** | Product shows **deep link + instructions** only; **no** automated calls from Carzon servers. |
| **Pre-agreement posture** | Treat as **`partner_api_required`** conceptually: implementation blocked until **contract + DPA-style** clarity. Map operationally to **`access_mode = unknown`** or **`not_requested`** rows **not** written until policy exists — or use **`status = requires_partner_access`** on placeholder rows **only** if product intentionally records “awaiting partner”. |

**Statuses (align with DB `listing_vin_source_results.status` check):**  
`pending`, `succeeded`, `no_data`, `failed`, **`provider_unavailable`**, **`rate_limited`**, **`requires_partner_access`**, plus others already in schema (`partial`, `stale`, `quota_exceeded`, `requires_user_consent`, `requires_manual_action`, `not_requested`).  
**Note:** there is **no** `invalid_vin` in the schema today; represent as **`failed`** or **`no_data`** with a **normalized_summary** / **source_metadata** flag agreed at implementation time, or add a future migration — **Phase 3B does not change schema.**

---

## D. Data fields requested from BNM / BNAA / RCA operators

**Goal:** **minimal** fields for a **buyer-safe** summary, avoiding **personal data** unless operators state it is required and lawful to display to **anonymous buyers**.

### D.1 Query / outcome envelope

| Requested concept | Suggested key / semantics | Notes |
|-------------------|---------------------------|--------|
| Query result status | `result_kind`: `found_records` \| `no_records_found` \| `unavailable` \| `invalid_input` | Map to Carzon **`status`** + summary; **`invalid_input`** may replace “invalid VIN” until schema evolves. |
| Damage **record count** | `record_count` (integer, nullable) | Only if operator allows aggregation for buyer display. |
| **Event date** or **year** | `events[]` with `date` or `year` only | Avoid free-text PII; prefer coarse granularity if required by regulator. |
| **Category / severity** | `damage_category` / `severity_band` (enum agreed with source) | No guarantee of completeness. |
| **Insurer or source class** | `insurer_bucket` or `reporting_entity_type` | Avoid full free-text names if those imply third-party PII. |
| **Stable record / certificate reference** | `record_reference` or `verification_code` | Only if **explicitly** allowed for display or verification; may be **owner-only** or **internal**. |
| **Source timestamp** | `source_generated_at` | For display “as of” and TTL. |
| **Operator disclaimer text** | `mandatory_disclaimer` (short, versioned) | May be required verbatim in UI. |
| **Buyer display allowed?** | boolean + scope document | **Must** be explicit. |
| **“No records found” display allowed?** | boolean | **Critical** — absence of data is sensitive. |
| **Retention** | max **storage** duration for Carzon | Per agreement. |
| **Caching / TTL** | recommended **refresh** interval | Prevents abusive refresh. |
| **Rate limits** | per **API key**, **IP**, **VIN**, **listing**, **day** | For Edge worker design. |
| **Audit / logging** | what BNM/BNAA requires Carzon to log | **Must not** log full VIN in plaintext in Carzon logs; use **listing_id** + **job id** + **hashed correlation id** per Carzon policy. |

### D.2 Fields Carzon will **not** ask for in v1 unless operator mandates (and legal approves)

- Natural person **identifiers** (IDNP), **exact addresses**, **full free-text** claim narratives naming individuals.
- **Applicant-specific** certificate payloads intended for **named solicitants**.

---

## E. Buyer-safe display proposal (RU examples)

**Principles:** name **RCA/BNM** (exact branding per operator), state **date of check**, **never** imply full history or absence of accidents everywhere, **never** claim Moldova **“full verification”** of the listing.

### E.1 Allowed phrasing examples (RU)

- «По данным RCA/BNM найдены записи о повреждениях.»
- «По данным RCA/BNM записи о повреждениях не найдены.»
- «Источник: RCA/BNM.»
- «Дата проверки: …»
- «Некоторые случаи могли не попасть в источник. Перед покупкой рекомендуем осмотр автомобиля и проверку документов.»

Copy must stay consistent with existing buyer modal limitation patterns (no new “verified” semantics; see `vin_provider_architecture.md` Phase 2K/2J).

### E.2 Forbidden phrasing (examples)

- «Без ДТП»
- «Чистая история»
- «Автомобиль полностью проверен»
- «Официально подтверждено отсутствие повреждений»
- Any **guarantee** that the vehicle has **no** damage, **no** accidents, or **perfect** history.

### E.3 “No records found”

Only use operator-approved wording. If operator **forbids** stating “no records,” UI must fall back to **neutral** language (“не удалось подтвердить наличие записей” / “данные недоступны”) per their written guidance — **not invented here**.

---

## F. Privacy / legal questions for BNM / BNAA / Moldovan counsel

Use this as a checklist for email and counsel review:

1. **Buyer display:** Is displaying **aggregated** Moldova insurance-market damage signals to **anonymous** marketplace buyers **permitted** for this data product?
2. **Field allowlist:** Which **fields** may appear in a **`public_summary`** projection vs **owner-only** vs **must not store**?
3. **Storage:** May Carzon **persist** normalized results in `listing_vin_source_results.normalized_summary`? Any **encryption** or **location** requirement?
4. **Caching / TTL:** Maximum **cache** duration? Mandatory **re-fetch** rules on listing renewal?
5. **Negative results:** May Carzon show **“no records found”** publicly? If not, what **neutral** statement is required?
6. **Rate limits:** Official **quotas** and **burst** rules; penalties for violation?
7. **Consent:** Is **seller** or **buyer** consent required before display?
8. **Authentication:** Must buyers or sellers be **logged in** to Moldova government systems instead of Carzon-mediated API?
9. **Disclaimers:** **Mandatory** text, font, placement, language (RO/RU)?
10. **Sandbox:** Is a **test** environment or **static fixtures** available for integration development **without** production VINs?
11. **Official API:** Does an **official API** or **MOU-based** feed exist for **licensed** market participants?
12. **Automation policy:** Is **automated** access to the **consumer web portal** **prohibited** even when technically possible? (Assume **yes** until told otherwise — Carzon will not rely on scraping.)

---

## G. Technical integration design **if** approved

**Placement:** **Supabase Edge Function** (or other **server-side** worker) **only** — **no** provider secrets in Flutter; **no** direct browser scraping of RCA.BNM.MD.

**Storage:** existing **`listing_vin_source_results`**:

- **`source_id`:** `md_rca_damage`
- **`region`:** `md`
- **`access_mode`:** `carzon_partner_api` when contract exists; otherwise do **not** fake automated success — use `manual_external_check` at product layer only.
- **`visibility`:** **`public_summary`** **only** if legal + operator allow buyer projection; else **`owner`** or **`internal`** until toggled by migration/policy.
- **`normalized_summary`:** **small JSON** with agreed keys (e.g. `result_kind`, `record_count`, coarse `events`); **no** raw provider JSON.
- **`source_metadata`:** **non-sensitive** provenance only (API version, disclaimer version id); **no** full VIN, **no** raw payloads by default.
- **`limitation_codes`:** conservative set, e.g. `source_limited`, `not_full_accident_history`, `not_ownership_check`, `not_mileage_check`, `not_insurance_policy_status`, `not_registration_check`, `not_md_pmr_official_verification` (where still true for aspects **not** covered by this source), plus any operator-supplied codes mapped to **human-readable** bullets (pattern from Phase 2L).
- **`fetched_at` / `ttl_until`:** set per agreement.
- **Logging:** structured logs **without** plaintext VIN — correlate by **internal job id** and **listing_id**.

**Suggested `status` mapping (conceptual):**

| Operator / API outcome | Carzon `status` |
|------------------------|-----------------|
| Success with records | `succeeded` |
| Success, empty | `no_data` (only if operator allows interpreting as such) |
| Bad VIN / rejected input | `failed` or `partial` (until schema adds finer codes) |
| Upstream down | `provider_unavailable` |
| 429 / throttle | `rate_limited` |
| No contract / not enabled | `requires_partner_access` |

**Worker orchestration:** reuse existing **VIN job** patterns where applicable (`docs/ops_vin_decode_jobs.md`); **new provider adapter** `md_rca_damage` registered in provider factory — **future phase**, not Phase 3B.

---

## H. Outreach email draft (English)

**To:** (appropriate public contact for RCA Data / BNAA / BNM insurance supervision — obtain from official directories)  
**Subject:** Request for information — read-only API / data access for VIN-based vehicle damage history (marketplace integration)

Dear Sir or Madam,

We are building **Carzon**, a vehicle marketplace platform in Moldova. We would like to offer buyers **factual, source-attributed information** about **recorded damage / insurance claim-file signals** for vehicles **identified by VIN**, using data from Moldova’s RCA / RCA Data ecosystem, **without scraping** consumer web portals or bypassing access controls.

Could you please advise whether **authorised read-only technical access** exists (or could be established) for **licensed platforms**, for example:

- A **documented API** or **partner feed** for **VIN-based** vehicle damage history suitable for **buyer-facing summaries**;
- An official **data-sharing or cooperation process** (including any **sandbox** / test environment);
- A **field-level allowlist** for what may be shown to **anonymous buyers** vs **vehicle owners**;
- Rules **permitting or prohibiting** presentation of **“no records found”** outcomes;
- **Data protection** obligations, **mandatory disclaimers**, **retention limits**, and **caching** guidelines;
- **Rate limits**, audit requirements, and whether **seller or buyer consent** is required.

We do **not** request access to consumer flows that are intended for **named applicants** only (e.g. applicant-specific certificates) for our **default buyer report**. We are happy to sign appropriate **agreements** and comply with technical and legal constraints.

We would appreciate a short call or written guidance and the correct contact for technical onboarding.

Kind regards,  
[Name]  
[Title] — Carzon  
[Business contact email]  
[Phone — optional]

*(Do not include secrets, API keys, or real VINs.)*

---

## I. Recommended next actions

1. **Send** outreach (Section H); route through **Romanian or Russian** translation if required by recipient preference.
2. **Legal review** in Moldova: buyer **`public_summary`** for damage signals, **negative results**, and **insurance data** handling.
3. **Product decision:** whether any **interim UX** is acceptable (**deep link** to official RCA.BNM.MD tool only, no Carzon-stored result — aligns with **`manual_external_check`** posture).
4. **Only after written permission + technical specs:** design **migrations/RPC visibility** (if `public_summary` for `md_rca_damage` is new), implement **Edge provider**, **tests**, and **copy** aligned with Section E and operator disclaimers.
5. **Do not implement** unsanctioned portal automation regardless of technical ease.

---

## Appendix — alignment with existing schema (reference)

`listing_vin_source_results` constraints (Phase 2E) include:

- **`access_mode`:** `carzon_partner_api` | `user_delegated` | `seller_uploaded_document` | `manual_external_check` | `commercial_api` | `not_available` | `unknown`
- **`status`:** includes `provider_unavailable`, `rate_limited`, `requires_partner_access`, `no_data`, etc.
- **`visibility`:** `internal` | `owner` | `public_summary`
- **`confidence`:** `official` | `partner` | `commercial` | `self_reported` | `basic_decode` | `unknown`
- **`region`:** `md` | `pmr` | `both` | `international` | `unknown`

Any future **`invalid_vin`–style `status`** requires a **separate migration** and is **out of scope** for Phase 3B.
