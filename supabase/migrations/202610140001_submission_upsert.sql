begin;

-- Replace the contributor's pending version so rescans update the shared queue.
create or replace function public.navilo_submit_submission(
  p_barcode text,
  p_category text,
  p_product_name text,
  p_ingredients text,
  p_language text,
  p_source_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  delete from public.navilo_submissions
  where contributor_id = auth.uid()
    and barcode = p_barcode
    and category = p_category
    and status = 'pending';

  insert into public.navilo_submissions(
    contributor_id, barcode, category, product_name, ingredients, language,
    source_note, sharing_consent
  )
  values (
    auth.uid(), p_barcode, p_category, p_product_name, p_ingredients,
    coalesce(nullif(trim(p_language), ''), 'tr'), p_source_note, true
  );
end;
$$;

revoke all on function public.navilo_submit_submission(
  text, text, text, text, text, text
) from public, anon;
grant execute on function public.navilo_submit_submission(
  text, text, text, text, text, text
) to authenticated;

commit;
