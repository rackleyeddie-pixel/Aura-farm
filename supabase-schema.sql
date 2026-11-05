-- Aura Farm multiplayer foundation. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;
create table public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 display_name text not null check (char_length(display_name) between 1 and 40),
 created_at timestamptz not null default now()
);
create table public.leagues (
 id uuid primary key default gen_random_uuid(),
 name text not null check (char_length(name) between 1 and 70),
 invite_code text not null unique default upper(substr(encode(gen_random_bytes(8),'hex'),1,10)),
 owner_id uuid not null references auth.users(id),
 created_at timestamptz not null default now()
);
create table public.memberships (
 league_id uuid not null references public.leagues(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 joined_at timestamptz not null default now(),
 primary key(league_id,user_id)
);
create table public.aura_awards (
 id uuid primary key default gen_random_uuid(),
 league_id uuid not null references public.leagues(id) on delete cascade,
 player_id uuid not null references auth.users(id) on delete cascade,
 points integer not null check(points between 1 and 1000),
 reason text not null check(char_length(reason) between 1 and 200),
 created_at timestamptz not null default now()
);
create index on public.memberships(user_id);
create index on public.aura_awards(league_id);
alter table public.profiles enable row level security;
alter table public.leagues enable row level security;
alter table public.memberships enable row level security;
alter table public.aura_awards enable row level security;
create policy "profile own read" on public.profiles for select to authenticated using(id=auth.uid());
create policy "profile own insert" on public.profiles for insert to authenticated with check(id=auth.uid());
create policy "profile own update" on public.profiles for update to authenticated using(id=auth.uid()) with check(id=auth.uid());
create policy "league member read" on public.leagues for select to authenticated using(exists(select 1 from public.memberships m where m.league_id=id and m.user_id=auth.uid()));
create policy "membership own read" on public.memberships for select to authenticated using(user_id=auth.uid());
create policy "awards member read" on public.aura_awards for select to authenticated using(exists(select 1 from public.memberships m where m.league_id=aura_awards.league_id and m.user_id=auth.uid()));
-- Security-definer RPCs avoid exposing invite codes or bypassing membership checks.
create or replace function public.create_aura_league(p_name text) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if length(trim(p_name)) not between 1 and 70 then raise exception 'Invalid league name'; end if;
 insert into public.leagues(name,owner_id) values(trim(p_name),auth.uid()) returning id into v_id;
 insert into public.memberships(league_id,user_id) values(v_id,auth.uid());
 return v_id;
end $$;
create or replace function public.join_aura_league(p_code text) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$
declare v_id uuid;
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 select id into v_id from public.leagues where invite_code=upper(trim(p_code));
 if v_id is null then raise exception 'Invalid invitation code'; end if;
 insert into public.memberships(league_id,user_id) values(v_id,auth.uid()) on conflict do nothing;
 return v_id;
end $$;
revoke all on function public.create_aura_league(text) from public;
revoke all on function public.join_aura_league(text) from public;
grant execute on function public.create_aura_league(text) to authenticated;
grant execute on function public.join_aura_league(text) to authenticated;
-- No award insert policy yet: point awards must be validated by a future trusted voting workflow.
