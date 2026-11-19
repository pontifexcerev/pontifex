-- =====================================================================
-- PONTIFEX: Supabase update (run once in SQL Editor > New query > Run)
-- Safe to run again. It does not delete any existing data.
-- =====================================================================

-- 1) FIX: the app saves progress with an "updated_at" column that the first
--    setup did not create. Without it, cloud saving of progress failed.
alter table public.user_state add column if not exists updated_at timestamptz default now();

-- 2) PROFILE + BIO columns shown on leaderboards
alter table public.profiles add column if not exists av     text;
alter table public.profiles add column if not exists col    text;
alter table public.profiles add column if not exists frame  text;
alter table public.profiles add column if not exists title  text;
alter table public.profiles add column if not exists school text;
alter table public.profiles add column if not exists bio    text;
alter table public.profiles add column if not exists pic    text;
alter table public.profiles add column if not exists anon   boolean not null default false;

-- 3) LEADERBOARD: now returns profile details (anonymous users stay hidden)
drop function if exists public.get_leaderboard();
create or replace function public.get_leaderboard()
returns table(id uuid, nickname text, xp int, badges text, av text, col text,
              frame text, title text, school text, bio text, pic text, anon boolean)
language sql security definer set search_path = public stable as $$
  select p.id,
         case when p.anon then 'Anonymous' else p.nickname end,
         p.xp,
         case when p.anon then '' else coalesce(p.badges,'') end,
         case when p.anon then '?' else p.av end,
         case when p.anon then '#7f93b0' else p.col end,
         case when p.anon then 'plain' else p.frame end,
         case when p.anon then 'Hidden' else p.title end,
         case when p.anon then '' else left(coalesce(p.school,''),60) end,
         case when p.anon then '' else left(coalesce(p.bio,''),140) end,
         case when p.anon then '' else coalesce(p.pic,'') end,
         p.anon
  from public.profiles p
  where p.approved and p.show_on_board
  order by p.xp desc
  limit 100;
$$;
revoke execute on function public.get_leaderboard() from public, anon;
grant  execute on function public.get_leaderboard() to authenticated;

-- 4) 1 v 1 TIMED BATTLES
create table if not exists public.battles (
  id          uuid primary key default gen_random_uuid(),
  code        text unique,
  p1          uuid not null references public.profiles(id) on delete cascade,
  p2          uuid references public.profiles(id) on delete cascade,
  status      text not null default 'waiting',      -- waiting | active | done | cancelled
  qs          jsonb not null,                         -- [[subject, index], ...]
  p1_score    int not null default 0,  p2_score int not null default 0,
  p1_n        int not null default 0,  p2_n     int not null default 0,
  p1_ms       int,                     p2_ms    int,
  p1_fin      boolean not null default false,
  p2_fin      boolean not null default false,
  created_at  timestamptz not null default now(),
  started_at  timestamptz
);
alter table public.battles enable row level security;
-- No direct table access: everything goes through the functions below.
drop policy if exists "battles none" on public.battles;
create policy "battles none" on public.battles for select using (false);

create or replace function public.battle_json(b public.battles) returns jsonb
language sql security definer set search_path = public stable as $$
  select jsonb_build_object(
    'id', b.id, 'code', b.code, 'status', b.status, 'qs', b.qs,
    'p1', b.p1, 'p2', b.p2,
    'p1_name', case when a.anon then 'Anonymous' else coalesce(a.nickname,'Reviewee') end,
    'p2_name', case when c.anon then 'Anonymous' else coalesce(c.nickname,'Reviewee') end,
    'p1_av',   case when a.anon then '?' else coalesce(a.av,'◈') end,
    'p2_av',   case when c.anon then '?' else coalesce(c.av,'◈') end,
    'p1_col',  case when a.anon then '#7f93b0' else coalesce(a.col,'#A78BFA') end,
    'p2_col',  case when c.anon then '#7f93b0' else coalesce(c.col,'#A78BFA') end,
    'p1_score', b.p1_score, 'p2_score', b.p2_score,
    'p1_n', b.p1_n, 'p2_n', b.p2_n, 'p1_ms', b.p1_ms, 'p2_ms', b.p2_ms,
    'start_ms', case when b.started_at is null then null
                     else (extract(epoch from b.started_at)*1000)::bigint + 4000 end,
    'now_ms', (extract(epoch from clock_timestamp())*1000)::bigint)
  from (select 1) s
  left join public.profiles a on a.id = b.p1
  left join public.profiles c on c.id = b.p2;
$$;

create or replace function public.battle_state(p_id uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare b battles;
begin
  select * into b from battles where id = p_id and (p1 = auth.uid() or p2 = auth.uid()) for update;
  if not found then return null; end if;
  if b.status = 'active' and now() > b.started_at + interval '330 seconds' then
    update battles set status='done' where id=b.id returning * into b;
  end if;
  if b.status = 'waiting' and now() > b.created_at + interval '10 minutes' then
    update battles set status='cancelled' where id=b.id returning * into b;
  end if;
  return battle_json(b);
end $$;

create or replace function public.battle_find(p_qs jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare b battles; me profiles;
begin
  select * into me from profiles where id = auth.uid() and approved;
  if not found then raise exception 'not approved'; end if;
  -- leave any old unfinished matches of mine
  update battles set status='cancelled' where p1 = auth.uid() and status='waiting';
  select * into b from battles
   where status='waiting' and code is null and p1 <> auth.uid()
     and created_at > now() - interval '2 minutes'
   order by created_at limit 1 for update skip locked;
  if found then
    update battles set p2 = auth.uid(), status='active', started_at = now()
     where id = b.id returning * into b;
  else
    insert into battles(p1, qs) values (auth.uid(), p_qs) returning * into b;
  end if;
  return battle_json(b);
end $$;

create or replace function public.battle_create(p_qs jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare b battles; c text;
begin
  perform 1 from profiles where id = auth.uid() and approved;
  if not found then raise exception 'not approved'; end if;
  update battles set status='cancelled' where p1 = auth.uid() and status='waiting';
  loop
    c := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 5));
    exit when not exists(select 1 from battles where code = c);
  end loop;
  insert into battles(p1, qs, code) values (auth.uid(), p_qs, c) returning * into b;
  return battle_json(b);
end $$;

create or replace function public.battle_join(p_code text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare b battles;
begin
  perform 1 from profiles where id = auth.uid() and approved;
  if not found then raise exception 'not approved'; end if;
  select * into b from battles
   where code = upper(trim(p_code)) and status='waiting' and p1 <> auth.uid()
     and created_at > now() - interval '10 minutes' for update;
  if not found then return null; end if;
  update battles set p2 = auth.uid(), status='active', started_at = now()
   where id = b.id returning * into b;
  return battle_json(b);
end $$;

create or replace function public.battle_report(p_id uuid, p_score int, p_n int, p_ms int, p_fin boolean)
returns jsonb language plpgsql security definer set search_path = public as $$
declare b battles; s int; n int;
begin
  select * into b from battles where id = p_id and status = 'active'
     and (p1 = auth.uid() or p2 = auth.uid()) for update;
  if not found then return battle_state(p_id); end if;
  n := greatest(0, least(p_n, jsonb_array_length(b.qs)));
  s := greatest(0, least(p_score, n));
  if b.p1 = auth.uid() then
    update battles set p1_score=s, p1_n=n, p1_ms=coalesce(p_ms,p1_ms), p1_fin = p1_fin or p_fin where id=b.id;
  else
    update battles set p2_score=s, p2_n=n, p2_ms=coalesce(p_ms,p2_ms), p2_fin = p2_fin or p_fin where id=b.id;
  end if;
  update battles set status='done' where id=b.id and p1_fin and p2_fin;
  return battle_state(p_id);
end $$;

create or replace function public.battle_cancel(p_id uuid) returns void
language sql security definer set search_path = public as $$
  update battles set status='cancelled' where id = p_id and p1 = auth.uid() and status='waiting';
$$;

do $$ declare f text; begin
  foreach f in array array['battle_state(uuid)','battle_find(jsonb)','battle_create(jsonb)',
      'battle_join(text)','battle_report(uuid,int,int,int,boolean)','battle_cancel(uuid)'] loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

