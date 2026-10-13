import json
import re
import time
from pathlib import Path
try:
    from . import collect_harras
except ImportError:
    import collect_harras

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/breakfast_sauces'

def main():
    OUT.mkdir(exist_ok=True)
    (OUT/'sources').mkdir(exist_ok=True)
    collect_harras.OUT=OUT
    results=[]
    stopped=False
    for line in (OUT/'submitted.txt').read_text(encoding='utf-8').splitlines():
        if not re.match(r'^\d+\t[0-9]+\t',line):
            continue
        index,code,name,ingredients=re.split(r'\t+',line,maxsplit=3)
        row=dict(index=int(index),code=code,name=name,submitted_ingredients=ingredients,gtin_valid=collect_harras.valid(code))
        if not row['gtin_valid']:
            row['status']='invalid_gtin_not_imported'
        elif stopped:
            row['status']='deferred_after_rate_limit_not_imported'
        else:
            cached=(OUT/'sources'/(code+'.json')).exists()
            row=collect_harras.collect(row)
            if 'RATE_LIMIT:' in row.get('error',''):
                stopped=True
            if not cached:
                time.sleep(3)
        results.append(row)
    (OUT/'audit.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    for r in results:
        p=r.get('source_product',{})
        if r.get('source_status')==1:
            print(json.dumps(dict(index=r['index'],code=r['code'],submitted=r['name'],name=p.get('product_name_tr') or p.get('product_name'),brands=p.get('brands'),ingredients=p.get('ingredients_text_tr') or p.get('ingredients_text')),ensure_ascii=False))
    print('TOTAL',len(results),'INVALID',sum(not r['gtin_valid'] for r in results))

if __name__=='__main__':
    main()
