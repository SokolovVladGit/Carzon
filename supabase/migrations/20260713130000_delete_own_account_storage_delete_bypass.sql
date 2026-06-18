-- Patch: allow storage.objects cleanup inside delete_own_account() on hosted Supabase.
--
-- storage.protect_delete() / protect_objects_delete blocks any SQL DELETE from
-- storage.objects unless session setting storage.allow_delete_query = 'true'.
-- Apply when 20260713120000 was deployed before this bypass existed.

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

    perform public.deactivate_my_push_tokens();

    perform set_config('storage.allow_delete_query', 'true', true);

    delete from storage.objects as o
     where o.bucket_id = 'listing-images'
       and o.name collate "C" like ('listings/' || v_uid::text || '/%');

    delete from storage.objects as o
     where o.bucket_id = 'seller-avatars'
       and o.name collate "C" like ('avatars/' || v_uid::text || '/%');

    delete from storage.objects as o
     where o.bucket_id = 'chat-attachments'
       and o.name collate "C" like ('conversations/%/' || v_uid::text || '/%');

    delete from public.listings
     where seller_id = v_uid;
end;
$$;
