"""Prepare reviewed batches for Supabase; preserve stricter remote publication gates."""
import json
from pathlib import Path
from tool.catalog_validation import validate_reviewed_record

ROOT=Path(__file__).resolve().parents[1]
BATCHES=['vegeats_20261015','topzcorn_20261015','protein_expansion_20261015']

def literal(value):
 return "'"+json.dumps(value,ensure_ascii=False,separators=(',',':')).replace("'","''")+"'::jsonb"

def main():
 reviewed=[];pending=[]
 for batch in BATCHES:
  rows=json.loads((ROOT/'docs'/batch/'reviewed.json').read_text(encoding='utf-8'))
  for r in rows:validate_reviewed_record(r)
  reviewed.extend(rows)
  for index,r in enumerate(json.loads((ROOT/'data/quarantine'/f'{batch}.json').read_text(encoding='utf-8')),1):
   pending.append(dict(batch=batch,submitted_row=index,record=r))
 assert len(reviewed)==30 and len(pending)==17
 assert len({(r['code'],r['category']) for r in reviewed})==len(reviewed)
 sql="""-- Reviewed source data only. No physical-label approval or expiry is fabricated.
begin;
alter table public.navilo_catalog add column if not exists catalogue_metadata jsonb not null default '{}'::jsonb;
alter table public.navilo_unverified_catalog add column if not exists metadata jsonb not null default '{}'::jsonb;
create temporary table sync_reviewed(record jsonb) on commit drop;
insert into sync_reviewed select value from jsonb_array_elements(PAYLOAD);
do $$ begin
 if exists (select 1 from sync_reviewed s join public.navilo_catalog c
  on c.barcode=s.record->>'code' and c.category=s.record->>'category'
  where (c.product_name,c.ingredients,c.source_url) is distinct from
   (s.record->>'name',s.record->>'ingredients',s.record->>'source_url')) then
  raise exception 'Existing catalogue conflict; no remote rows overwritten';
 end if;
end $$;
insert into public.navilo_catalog(barcode,category,product_name,ingredients,language,source_note,reviewed_at,
 source_type,source_url,verified_at,status,catalogue_metadata,label_verified,publication_status,valid_until)
select record->>'code',record->>'category',record->>'name',record->>'ingredients','tr',
 record->>'evidence_note',(record->>'checked_at')::timestamptz,record->>'source_type',record->>'source_url',
 (record->>'verified_at')::timestamptz,'verified',record,false,'draft',null from sync_reviewed
on conflict (barcode,category) do nothing;

insert into public.navilo_unverified_catalog(batch,submitted_row,barcode,product_name,ingredients,status,metadata)
select value->>'batch',(value->>'submitted_row')::int,coalesce(value->'record'->>'code',''),
 value->'record'->>'name',coalesce(value->'record'->>'ingredients',''),'unverified',value->'record'
from jsonb_array_elements(PENDING)
on conflict(batch,submitted_row) do update set metadata=excluded.metadata;

insert into public.navilo_catalog_exclusions(barcode) values
 ('8681982003115'),('8681982003139'),('8685080680070') on conflict do nothing;

-- Preserve the repaired raw submissions, including research and conflicting texts.
update public.navilo_unverified_catalog u set metadata=r
from jsonb_array_elements(MEAT) r
where u.batch='processed-meat-20261013' and u.submitted_row=(r->>'no')::int;
notify pgrst, 'reload schema';
commit;
"""
 sql=sql.replace('PAYLOAD',literal(reviewed)).replace('PENDING',literal(pending)).replace('MEAT',literal(json.loads((ROOT/'data/quarantine/processed_meat_150.json').read_text(encoding='utf-8'))))
 path=ROOT/'supabase/migrations/202610150005_reviewed_catalogue_batches.sql'
 path.write_text(sql,encoding='utf-8')
 print(json.dumps({'verified_records':len(reviewed),'pending_records':len(pending),'sql':str(path)}))

if __name__=='__main__':main()
