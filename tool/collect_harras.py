import json
import re
import time
from pathlib import Path
import requests
try:
    from .catalog_validation import valid_gtin
except ImportError:
    from catalog_validation import valid_gtin

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/harras'
FIELDS=['code','product_name','product_name_tr','brands','quantity','ingredients_text','ingredients_text_tr','lang','last_modified_t','allergens_tags','traces_tags','labels_tags','image_ingredients_url','image_ingredients_small_url','image_front_url','images']

def valid(code):
    return valid_gtin(code)

def collect(row):
    if not valid(row['code']):
        row['status']='invalid_gtin_not_imported'
        return row
    url='https://world.openfoodfacts.org/api/v0/product/'+row['code']+'.json'
    cache=OUT/'sources'/(row['code']+'.json')
    try:
        cache.parent.mkdir(parents=True, exist_ok=True)
        if cache.exists():
            payload=json.loads(cache.read_text(encoding='utf-8'))
        else:
            response=requests.get(url,headers={'User-Agent':'Mozilla/5.0 NaviloCatalog/0.1 (product research)'},timeout=25)
            if response.status_code==429:
                row['retry_after']=response.headers.get('Retry-After','provider reset')
                raise RuntimeError('RATE_LIMIT: stop requests; retry after '+response.headers.get('Retry-After','provider reset'))
            if response.status_code==404:
                payload={'status':0,'code':row['code'],'product':{}}
            else:
                response.raise_for_status()
                payload=response.json()
            if not isinstance(payload, dict) or payload.get('status') not in (0, 1):
                raise ValueError('SOURCE_SCHEMA: missing status 0/1')
            if not isinstance(payload.get('product', {}), dict):
                raise ValueError('SOURCE_SCHEMA: product must be an object')
            payload={'status':payload.get('status'),'code':payload.get('code'),'product':{k:payload.get('product',{}).get(k) for k in FIELDS}}
            cache.write_text(json.dumps(payload,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
        if not isinstance(payload, dict) or payload.get('status') not in (0, 1) or not isinstance(payload.get('product', {}), dict):
            raise ValueError('SOURCE_SCHEMA: invalid cached payload')
        p=payload.get('product',{})
        if payload.get('status') == 1 and (p.get('code') or payload.get('code')) != row['code']:
            raise ValueError('SOURCE_IDENTITY: returned barcode does not match requested barcode')
        row['source_url']=url
        row['source_product']=p
        row['source_status']=payload.get('status')
        row['status']='source_candidate_pending_review' if payload.get('status')==1 else 'not_found_not_imported'
    except Exception as e:
        row['status']='source_unavailable_not_imported'
        row['error']=str(e)
    return row

def main():
    OUT.mkdir(exist_ok=True)
    (OUT/'sources').mkdir(exist_ok=True)
    rows=[]
    for line in (OUT/'submitted.txt').read_text(encoding='utf-8').splitlines():
        if re.match(r'^\d+\t[0-9]+\t',line):
            index,code,name,ingredients=re.split(r'\t+',line,maxsplit=3)
            rows.append(dict(index=int(index),code=code,name=name,submitted_ingredients=ingredients,gtin_valid=valid(code)))
    results=[]
    stopped=False
    for row in rows:
        if stopped:
            row['status']='deferred_after_rate_limit_not_imported'
            results.append(row)
            continue
        cached=(OUT/'sources'/(row['code']+'.json')).exists()
        result=collect(row)
        results.append(result)
        if 'RATE_LIMIT:' in result.get('error',''):
            stopped=True
        if not cached:
            time.sleep(3)
    (OUT/'audit.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for r in results:
        p=r.get('source_product',{})
        if r.get('source_status')==1:
            print(json.dumps({'index':r['index'],'code':r['code'],'submitted':r['name'],'name':p.get('product_name_tr') or p.get('product_name'),'brands':p.get('brands'),'quantity':p.get('quantity'),'ingredients':p.get('ingredients_text_tr') or p.get('ingredients_text')},ensure_ascii=False))
    print('TOTAL',len(rows))

if __name__=='__main__':
    main()
