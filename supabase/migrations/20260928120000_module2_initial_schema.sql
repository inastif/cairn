-- =====================================================================
-- Cairn, module 2 : schéma initial.
-- À exécuter une fois dans Supabase : SQL Editor > New query > coller > Run.
-- Idempotent : peut être relancé sans erreur.
--
-- Principes :
--  * chaque ligne appartient à un utilisateur (user_id) ;
--  * Row Level Security activé partout : un utilisateur ne voit et ne
--    modifie que ses propres lignes, même avec un client modifié ;
--  * montants en bigint d'unités mineures + devise ISO 4217 ;
--  * aucune donnée bancaire sensible (identifiants) n'est jamais stockée.
-- =====================================================================

-- ---------- Utilitaire : mise à jour automatique de updated_at ----------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------- Profils ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  reporting_currency char(3) not null default 'EUR' check (reporting_currency ~ '^[A-Z]{3}$'),
  target_amount_minor bigint not null default 100000000 check (target_amount_minor > 0),
  target_currency char(3) not null default 'EUR' check (target_currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Création automatique du profil à l'inscription.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id) on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- Actifs ----------
create table if not exists public.assets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  asset_class text not null check (asset_class in ('cash', 'investments', 'crypto', 'realEstate', 'other')),
  value_minor bigint not null,
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  subtype text check (subtype is null or char_length(subtype) <= 60),
  institution_name text check (institution_name is null or char_length(institution_name) <= 60),
  source text not null default 'manual' check (source in ('bankSync', 'manual', 'marketData')),
  valued_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Seul un compte de liquidités peut être négatif (découvert).
  constraint assets_negative_only_cash check (value_minor >= 0 or asset_class = 'cash')
);
create index if not exists assets_user_id_idx on public.assets (user_id);

-- ---------- Dettes ----------
create table if not exists public.liabilities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  liability_type text not null check (
    liability_type in ('mortgage', 'autoLoan', 'personalLoan', 'studentLoan', 'creditCard', 'other')
  ),
  outstanding_minor bigint not null check (outstanding_minor >= 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  institution_name text check (institution_name is null or char_length(institution_name) <= 60),
  secured_asset_id uuid references public.assets (id) on delete set null,
  source text not null default 'manual' check (source in ('bankSync', 'manual')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists liabilities_user_id_idx on public.liabilities (user_id);

-- ---------- Historique du patrimoine ----------
create table if not exists public.net_worth_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  snapshot_date date not null,
  gross_minor bigint not null check (gross_minor >= 0),
  liabilities_minor bigint not null check (liabilities_minor >= 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, snapshot_date)
);

-- ---------- Taux de change (référentiel partagé, lecture seule) ----------
create table if not exists public.fx_rates (
  base char(3) not null,
  quote char(3) not null,
  rate numeric(20, 8) not null check (rate > 0),
  rate_date date not null,
  source text not null,
  fetched_at timestamptz not null default now(),
  primary key (base, quote, rate_date)
);

-- ---------- Déclencheurs updated_at ----------
drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles
  for each row execute function public.set_updated_at();
drop trigger if exists assets_updated_at on public.assets;
create trigger assets_updated_at before update on public.assets
  for each row execute function public.set_updated_at();
drop trigger if exists liabilities_updated_at on public.liabilities;
create trigger liabilities_updated_at before update on public.liabilities
  for each row execute function public.set_updated_at();
drop trigger if exists snapshots_updated_at on public.net_worth_snapshots;
create trigger snapshots_updated_at before update on public.net_worth_snapshots
  for each row execute function public.set_updated_at();

-- ---------- Row Level Security ----------
alter table public.profiles enable row level security;
alter table public.assets enable row level security;
alter table public.liabilities enable row level security;
alter table public.net_worth_snapshots enable row level security;
alter table public.fx_rates enable row level security;

drop policy if exists "profil : lecture" on public.profiles;
create policy "profil : lecture" on public.profiles
  for select to authenticated using (id = (select auth.uid()));
drop policy if exists "profil : création" on public.profiles;
create policy "profil : création" on public.profiles
  for insert to authenticated with check (id = (select auth.uid()));
drop policy if exists "profil : modification" on public.profiles;
create policy "profil : modification" on public.profiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "actifs : propriétaire" on public.assets;
create policy "actifs : propriétaire" on public.assets
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists "dettes : propriétaire" on public.liabilities;
create policy "dettes : propriétaire" on public.liabilities
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (
    user_id = (select auth.uid())
    -- On ne peut rattacher une dette qu'à un de SES biens.
    and (
      secured_asset_id is null
      or exists (
        select 1 from public.assets a
        where a.id = secured_asset_id and a.user_id = (select auth.uid())
      )
    )
  );

drop policy if exists "historique : propriétaire" on public.net_worth_snapshots;
create policy "historique : propriétaire" on public.net_worth_snapshots
  for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Les taux sont publics en lecture pour les utilisateurs connectés ;
-- seule la fonction serveur (clé service_role, qui ignore RLS) écrit.
drop policy if exists "taux : lecture" on public.fx_rates;
create policy "taux : lecture" on public.fx_rates
  for select to authenticated using (true);

-- Aucun accès pour les visiteurs non connectés.
revoke all on public.profiles, public.assets, public.liabilities,
  public.net_worth_snapshots, public.fx_rates from anon;

-- ---------- Suppression du compte (RGPD, droit à l'effacement) ----------
-- Supprime l'utilisateur connecté ; les suppressions en cascade effacent
-- profil, actifs, dettes et historique.
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'not authenticated';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
