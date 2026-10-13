import json
import time
from pathlib import Path
import requests

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/breakfast_sauces'
CODES=['8690635260393','8690508004246','8696027016913','8690575171513','8690575171520','8690103131347','8680395186828','8680395182059']

def main():
    rows=[]
    for code in CODES:
        p=OUT/'sources'/(code+'.json')
        if p.exists():
            row=json.loads(p.read_text(encoding='utf-8'))
        else:
            r=requests.get('https://world.openfoodfacts.org/api/v0/product/'+code+'.json',headers={'User-Agent':'Mozilla/5.0 NaviloCatalog/0.1 (product research)'},timeout=25)
            if r.status_code==429:
                print('RATE_LIMIT; stopping')
                break
            if r.status_code==404:
                row={'code':code,'status':0,'product':{}}
            else:
                r.raise_for_status()
                row=r.json()
            p.write_text(json.dumps(row,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
            time.sleep(3)
        rows.append(row)
        data=row.get('product',{})
        print(json.dumps(dict(code=code,status=row.get('status'),name=data.get('product_name_tr') or data.get('product_name'),quantity=data.get('quantity'),ingredients=data.get('ingredients_text_tr') or data.get('ingredients_text'),image=data.get('image_ingredients_url')),ensure_ascii=False),flush=True)
    (OUT/'corrected_off_evidence.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

if __name__=='__main__':
    main()
