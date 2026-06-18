-- Carzon — authenticated self-service account deletion (public data cleanup).
--
-- Removes owned listings (avoiding listings.seller_id ON DELETE SET NULL orphans),
-- user-scoped Storage objects, and relies on auth user deletion (Edge Function
-- `delete-own-account` via auth.admin.deleteUser) to CASCADE remaining user rows:
-- favorites, filter_alert_settings, notification_preferences, user_push_tokens,
-- seller_profiles, conversations/messages, VIN owner rows, etc.
--
-- Does NOT delete auth.users here — GoTrue requires service_role (Edge Function).

create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public, pg_temp, storage
as $$
declare
    v_uid uuid := auth.uid();
    v_support_email constant text := 'admin@carzon.com';
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if exists (
        select 1
          from auth.users as u
         where u.id = v_uid
           and lower(trim(u.email)) = lower(trim(v_support_email))
    ) then
        raise exception 'account cannot be self-deleted'
            using errcode = '42501';
    end if;

    -- Best-effort push token deactivation while JWT is still valid.
    perform public.deactivate_my_push_tokens();

    -- Hosted Supabase blocks direct DELETE from storage.objects via
    -- storage.protect_delete() (statement-level) unless this session flag is set.
    perform set_config('storage.allow_delete_query', 'true', true);

    -- Storage has no FK cascade; remove user-scoped prefixes.
    delete from storage.objects as o
     where o.bucket_id = 'listing-images'
       and o.name collate "C" like ('listings/' || v_uid::text || '/%');

    delete from storage.objects as o
     where o.bucket_id = 'seller-avatars'
       and o.name collate "C" like ('avatars/' || v_uid::text || '/%');

    delete from storage.objects as o
     where o.bucket_id = 'chat-attachments'
       and o.name collate "C" like ('conversations/%/' || v_uid::text || '/%');

    -- Permanent owner delete: cascades listing_images, listing-scoped conversations,
    -- favorites on those listings, VIN sidecars, view analytics, etc.
    delete from public.listings
     where seller_id = v_uid;
end;
$$;

comment on function public.delete_own_account() is
    'Authenticated caller removes owned marketplace listings and user-scoped Storage '
    'objects before auth user deletion. Does not delete auth.users.';

revoke all on function public.delete_own_account() from public;
revoke all on function public.delete_own_account() from anon;
grant execute on function public.delete_own_account() to authenticated;
