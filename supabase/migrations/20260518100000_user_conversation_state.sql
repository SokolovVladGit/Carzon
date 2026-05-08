-- Carzon — per-user conversation read state + unread RPCs (minimal foundation).
--
-- Adds user_conversation_state for last_read_at per (user_id, conversation_id).
-- SECURITY DEFINER RPCs for mark read + unread counts; participant checks enforced.

-- ---------------------------------------------------------------------------
-- TABLE
-- ---------------------------------------------------------------------------

create table if not exists public.user_conversation_state (
    user_id uuid not null
        references auth.users (id) on delete cascade,
    conversation_id uuid not null
        references public.conversations (id) on delete cascade,
    last_read_at timestamptz,
    muted boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint user_conversation_state_pkey primary key (user_id, conversation_id)
);

create index if not exists user_conversation_state_conv_idx
    on public.user_conversation_state (conversation_id);

comment on table public.user_conversation_state is
    'Per-user messaging state per conversation (read receipts, mute).';

alter table public.user_conversation_state enable row level security;

-- No direct INSERT/UPDATE/DELETE for authenticated role — mutations via RPC only.
revoke insert, update, delete on public.user_conversation_state from anon;
revoke insert, update, delete on public.user_conversation_state from authenticated;
revoke insert, update, delete on public.user_conversation_state from public;

drop policy if exists "user_conversation_state_participant_select" on public.user_conversation_state;

create policy "user_conversation_state_participant_select"
    on public.user_conversation_state
    for select
    to authenticated
    using (
        user_id = auth.uid()
        and exists (
            select 1
              from public.conversations c
             where c.id = user_conversation_state.conversation_id
               and (
                   c.buyer_id = auth.uid()
                   or c.seller_id = auth.uid()
               )
        )
    );

grant select on public.user_conversation_state to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: mark_conversation_read(p_conversation_id uuid) -> void
-- ---------------------------------------------------------------------------

create or replace function public.mark_conversation_read(
    p_conversation_id uuid
) returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if not exists (
        select 1
          from public.conversations c
         where c.id = p_conversation_id
           and (c.buyer_id = v_uid or c.seller_id = v_uid)
    ) then
        raise exception 'not a participant'
            using errcode = '42501';
    end if;

    insert into public.user_conversation_state (
        user_id,
        conversation_id,
        last_read_at,
        created_at,
        updated_at,
        muted
    ) values (
        v_uid,
        p_conversation_id,
        now(),
        now(),
        now(),
        false
    )
    on conflict (user_id, conversation_id) do update
        set last_read_at = now(),
            updated_at = now();
end;
$$;

revoke all on function public.mark_conversation_read(uuid) from public;
revoke all on function public.mark_conversation_read(uuid) from anon;
grant execute on function public.mark_conversation_read(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: get_unread_conversation_count() -> integer
-- ---------------------------------------------------------------------------

create or replace function public.get_unread_conversation_count()
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_cnt integer;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    select coalesce(count(distinct m.conversation_id), 0)::integer
      into v_cnt
      from public.messages m
     inner join public.conversations c on c.id = m.conversation_id
      left join public.user_conversation_state ucs
             on ucs.conversation_id = c.id
            and ucs.user_id = v_uid
     where (c.buyer_id = v_uid or c.seller_id = v_uid)
       and m.sender_id is distinct from v_uid
       and m.created_at > coalesce(
               ucs.last_read_at,
               '-infinity'::timestamptz
           );

    return coalesce(v_cnt, 0);
end;
$$;

revoke all on function public.get_unread_conversation_count() from public;
revoke all on function public.get_unread_conversation_count() from anon;
grant execute on function public.get_unread_conversation_count() to authenticated;
