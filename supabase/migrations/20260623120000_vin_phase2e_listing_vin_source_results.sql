-- Carzon — VIN Phase 2E: source-scoped provider result taxonomy (schema only).
--
-- * No external HTTP calls, provider URLs, scraping, or third-party credentials.
-- * No plaintext full VIN, vin_hash, or raw provider payloads in this table.
-- * anon/authenticated have no table access; RLS on; workers use service_role only.
-- * Rows are keyed by listing + source_id (e.g. nhtsa_vpic, md_rca_damage).
--
-- user_delegated: Carzon MUST NOT auto-register users on third-party sites.
-- Delegation requires provider-supported flows and explicit recorded consent.
-- manual_external_check: product may link/instruct only; no automated provider calls.

------------------------------------------------------------------------------
-- 1 — listing_vin_source_results (internal sidecar)
------------------------------------------------------------------------------

create table if not exists public.listing_vin_source_results (
    id uuid primary key default gen_random_uuid(),
    listing_id uuid not null references public.listings(id) on delete cascade,
    source_id text not null,
    region text not null default 'unknown',
    access_mode text not null default 'unknown',
    status text not null default 'not_requested',
    visibility text not null default 'internal',
    confidence text not null default 'unknown',
    normalized_summary jsonb not null default '{}'::jsonb,
    source_metadata jsonb not null default '{}'::jsonb,
    limitation_codes text[] not null default '{}'::text[],
    requires_user_consent boolean not null default false,
    consent_required_reason text,
    fetched_at timestamptz,
    ttl_until timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint listing_vin_source_results_source_id_chk
        check (
            source_id ~ '^[a-z][a-z0-9_]{0,63}$'
            and length(source_id) >= 1
        ),
    constraint listing_vin_source_results_region_chk
        check (region in ('md', 'pmr', 'both', 'international', 'unknown')),
    constraint listing_vin_source_results_access_mode_chk
        check (
            access_mode in (
                'carzon_partner_api',
                'user_delegated',
                'seller_uploaded_document',
                'manual_external_check',
                'commercial_api',
                'not_available',
                'unknown'
            )
        ),
    constraint listing_vin_source_results_status_chk
        check (
            status in (
                'not_requested',
                'pending',
                'succeeded',
                'no_data',
                'partial',
                'failed',
                'stale',
                'provider_unavailable',
                'requires_user_consent',
                'requires_partner_access',
                'requires_manual_action',
                'rate_limited',
                'quota_exceeded'
            )
        ),
    constraint listing_vin_source_results_visibility_chk
        check (visibility in ('internal', 'owner', 'public_summary')),
    constraint listing_vin_source_results_confidence_chk
        check (
            confidence in (
                'official',
                'partner',
                'commercial',
                'self_reported',
                'basic_decode',
                'unknown'
            )
        ),
    constraint listing_vin_source_results_normalized_object_chk
        check (jsonb_typeof(normalized_summary) = 'object'),
    constraint listing_vin_source_results_source_meta_object_chk
        check (jsonb_typeof(source_metadata) = 'object'),
    constraint listing_vin_source_results_listing_source_uni
        unique (listing_id, source_id)
);

create index if not exists listing_vin_source_results_listing_id_idx
    on public.listing_vin_source_results (listing_id);

create index if not exists listing_vin_source_results_source_status_idx
    on public.listing_vin_source_results (source_id, status);

create index if not exists listing_vin_source_results_ttl_until_idx
    on public.listing_vin_source_results (ttl_until)
    where ttl_until is not null;

comment on table public.listing_vin_source_results is
    'Internal per-listing, per-source normalized VIN provider outcomes. '
    'Never stores full VIN, vin_hash, raw provider payloads, credentials, tokens, '
    'or provider request URLs. Not readable by anon/authenticated directly. '
    'Carzon must not auto-register users on third-party services; '
    'access_mode=user_delegated implies explicit consent and a provider-supported '
    'delegation flow. manual_external_check means no server-side provider automation.';

comment on column public.listing_vin_source_results.source_id is
    'Stable source key, e.g. nhtsa_vpic, md_rca_damage, md_asp_registration, '
    'md_asp_owner_extract, pmr_customs, commercial_history, seller_uploaded_document.';

comment on column public.listing_vin_source_results.access_mode is
    'How data may be obtained: partner API, user delegation (consent + provider flow), '
    'seller upload, instructions-only, commercial API, not_available, or unknown.';

comment on column public.listing_vin_source_results.normalized_summary is
    'Small sanitized JSON for worker/UI projections only; never substitute for raw payloads.';

comment on column public.listing_vin_source_results.source_metadata is
    'Non-secret provenance only (e.g. schema version, provider family). '
    'Must not contain URLs, auth material, or full VIN-related secrets.';

------------------------------------------------------------------------------
-- 2 — updated_at trigger
------------------------------------------------------------------------------

drop trigger if exists listing_vin_source_results_set_updated_at
    on public.listing_vin_source_results;

create trigger listing_vin_source_results_set_updated_at
    before update on public.listing_vin_source_results
    for each row
    execute function public.set_listings_updated_at();

------------------------------------------------------------------------------
-- 3 — Clear sidecar when private VIN identity row is removed (listing may remain)
------------------------------------------------------------------------------

create or replace function public.carzon_after_listing_vehicle_identity_deleted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    update public.vin_processing_jobs
       set status = 'cancelled',
           updated_at = now(),
           locked_at = null,
           locked_by = null
     where listing_id = old.listing_id
       and job_type = 'decode'
       and status in ('pending', 'processing');

    delete from public.listing_vin_source_results
     where listing_id = old.listing_id;

    delete from public.listing_vin_report_snapshot
     where listing_id = old.listing_id;

    return old;
end;
$$;

------------------------------------------------------------------------------
-- 4 — RLS + revoke client roles (service_role / table owner only)
------------------------------------------------------------------------------

alter table public.listing_vin_source_results enable row level security;

revoke all on table public.listing_vin_source_results from public;
revoke all on table public.listing_vin_source_results from anon;
revoke all on table public.listing_vin_source_results from authenticated;
