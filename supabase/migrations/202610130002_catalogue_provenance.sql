begin;

create or replace function public.navilo_valid_gtin(code text)
returns boolean language sql immutable strict set search_path = '' as $$
 select case when code ~ '^([0-9]{8}|[0-9]{12}|[0-9]{13}|[0-9]{14})$' then
   (select (10 - sum(substring(code, i, 1)::int *
    case when (length(code) - i) % 2 = 1 then 3 else 1 end) % 10) % 10
    = right(code, 1)::int from generate_series(1, length(code)-1) as g(i))
 else false end;
$$;

create table if not exists public.navilo_unverified_catalog (
 batch text not null, submitted_row integer not null,
 barcode text not null, product_name text not null, ingredients text not null,
 ingredients_original text, text_corrections jsonb not null default '[]'::jsonb,
 source_type text, source_url text, verified_at timestamptz,
 status text not null default 'unverified' check (status = 'unverified'),
 primary key (batch, submitted_row)
);
alter table public.navilo_unverified_catalog enable row level security;
revoke all on public.navilo_unverified_catalog from public, anon, authenticated;
grant all on public.navilo_unverified_catalog to service_role;

create table if not exists public.navilo_catalog_exclusions (barcode text primary key);
alter table public.navilo_catalog_exclusions enable row level security;
revoke all on public.navilo_catalog_exclusions from public, anon, authenticated;
grant all on public.navilo_catalog_exclusions to service_role;

alter table public.navilo_catalog
 add column if not exists source_type text,
 add column if not exists source_url text,
 add column if not exists verified_at timestamptz,
 add column if not exists status text not null default 'unverified';

-- Existing rows remain unverified until a reviewer supplies actual evidence.
alter table public.navilo_catalog add constraint navilo_provenance_state check (
 status in ('verified', 'unverified') and
 (status <> 'verified' or (
   source_type in ('label_photo','manufacturer','retailer','open_food_facts')
   and source_type is not null and source_url is not null
   and source_url ~ '^https://[^/[:space:]]+'
   and verified_at is not null and public.navilo_valid_gtin(barcode)
 ))
);
alter table public.navilo_catalog add constraint navilo_catalog_gtin_checksum
 check (public.navilo_valid_gtin(barcode)) not valid;
alter table public.navilo_submissions add constraint navilo_submission_gtin_checksum
 check (public.navilo_valid_gtin(barcode)) not valid;

create policy navilo_verified_source_guard on public.navilo_catalog as restrictive
 for select to anon, authenticated using (
 status = 'verified' and source_type is not null and source_url is not null
 and verified_at <= now() and public.navilo_valid_gtin(barcode)
 );
grant select (source_type, source_url, verified_at, status) on public.navilo_catalog to anon, authenticated;

create or replace function public.navilo_guard_source_review()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
 if exists (select 1 from public.navilo_catalog_exclusions e where e.barcode = new.barcode) then
   raise exception 'Quarantined catalogue barcode';
 end if;
 if TG_OP = 'UPDATE' and
   (new.barcode,new.category,new.product_name,new.ingredients,new.source_type,new.source_url)
   is distinct from
   (old.barcode,old.category,old.product_name,old.ingredients,old.source_type,old.source_url) then
   new.status := 'unverified';
   new.verified_at := null;
 end if;
 if new.status = 'verified' and (new.verified_at is null or new.verified_at > now()) then
   raise exception 'An actual source review date is required';
 end if;
 return new;
end;
$$;
create trigger navilo_catalog_source_guard before insert or update on public.navilo_catalog
 for each row execute function public.navilo_guard_source_review();

-- The old text-only approval must not masquerade as source verification.
create or replace function public.navilo_approve_submission(submission_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
 raise exception 'Source evidence required; review provenance before publishing';
end;
$$;
revoke all on function public.navilo_approve_submission(uuid) from public, anon, authenticated;

notify pgrst, 'reload schema';
commit;
