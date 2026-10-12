begin;

-- Additive migration: no existing application tables are modified.
create table public.navilo_catalog (
  barcode text not null check (barcode ~ '^[0-9]{8,14}$'),
  category text not null check (category in ('food', 'cosmetic')),
  product_name text not null check (length(trim(product_name)) between 1 and 120),
  ingredients text not null check (length(trim(ingredients)) between 1 and 20000),
  language text not null default 'tr',
  source_note text not null,
  reviewed_at timestamptz not null default now(),
  revision integer not null default 1,
  primary key (barcode, category)
);
alter table public.navilo_catalog enable row level security;
revoke all on public.navilo_catalog from anon, authenticated;
grant select on public.navilo_catalog to anon, authenticated;
create policy navilo_catalog_read on public.navilo_catalog for select to anon, authenticated using (true);

create table public.navilo_submissions (
  id uuid primary key default gen_random_uuid(),
  contributor_id uuid not null references auth.users(id) on delete cascade,
  barcode text not null check (barcode ~ '^[0-9]{8,14}$'),
  category text not null check (category in ('food', 'cosmetic')),
  product_name text not null check (length(trim(product_name)) between 1 and 120),
  ingredients text not null check (length(trim(ingredients)) between 1 and 20000),
  language text not null default 'tr',
  source_note text not null check (length(trim(source_note)) between 1 and 2000),
  sharing_consent boolean not null check (sharing_consent),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now()
);
create index navilo_submissions_contributor_idx on public.navilo_submissions(contributor_id, created_at desc);
create unique index navilo_one_pending_per_product on public.navilo_submissions(contributor_id, barcode, category) where status = 'pending';
alter table public.navilo_submissions enable row level security;
revoke all on public.navilo_submissions from anon, authenticated;
grant select on public.navilo_submissions to authenticated;
grant insert (contributor_id, barcode, category, product_name, ingredients, language, source_note, sharing_consent) on public.navilo_submissions to authenticated;
create policy navilo_submissions_own_read on public.navilo_submissions for select to authenticated using (contributor_id = (select auth.uid()));
create policy navilo_submissions_own_insert on public.navilo_submissions for insert to authenticated with check (contributor_id = (select auth.uid()) and status = 'pending' and sharing_consent);

-- Only a trusted reviewer/backend can promote a pending contribution.
create function public.navilo_approve_submission(submission_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare submission public.navilo_submissions;
begin
  select * into submission from public.navilo_submissions where id = submission_id and status = 'pending' for update;
  if not found then raise exception 'Pending submission not found'; end if;
  insert into public.navilo_catalog(barcode, category, product_name, ingredients, language, source_note)
  values(submission.barcode, submission.category, submission.product_name, submission.ingredients, submission.language, submission.source_note)
  on conflict (barcode, category) do update set product_name = excluded.product_name, ingredients = excluded.ingredients, language = excluded.language, source_note = excluded.source_note, reviewed_at = now(), revision = public.navilo_catalog.revision + 1;
  update public.navilo_submissions set status = 'approved' where id = submission_id;
end;
$$;
revoke all on function public.navilo_approve_submission(uuid) from public, anon, authenticated;
grant execute on function public.navilo_approve_submission(uuid) to service_role;
grant all on public.navilo_catalog, public.navilo_submissions to service_role;

commit;
