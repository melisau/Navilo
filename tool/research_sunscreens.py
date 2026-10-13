import concurrent.futures
import json
from pathlib import Path
import requests
from bs4 import BeautifulSoup

URLS = [
'https://b2c.cosrx.com/products/aloe-soothing-sun-cream-spf50-pa',
'https://thepurestsolutions.com/products/nemlendirici-etkili-invisible-gunes-koruyucu-krem-50ml',
'https://www.maruderm.com/maruderm-leke-karsiti-gunes-kremi-spf-50-pa-yeni-nesil-kore-filtreli-50-ml',
'https://beautyofjoseon.com/products/relief-sun-rice-probiotics-spf50-pa-uk',
'https://www.skin1004.com/products/hyalu-cica-water-fit-sun-serum',
]
ROOT=Path(__file__).resolve().parents[1]

def fetch(url):
    r=requests.get(url,timeout=35)
    s=BeautifulSoup(r.content,'html.parser')
    texts=s.get_text(' ',strip=True)
    evidence=[]
    for node in s.find_all(string=lambda t:t and any(k in t.lower() for k in ['water,','aqua,','aqua (water),'])):
        if len(str(node))>140 and node.parent.name not in ['script','style']:
            evidence.append(str(node).strip())
    variants=[]
    product_title=''
    try:
        j=requests.get(url+'.json',timeout=20).json()['product']
        variants=[{k:v.get(k) for k in ['title','barcode','sku']} for v in j['variants']]
        product_title=j.get('title','')
    except Exception:
        pass
    codes=[]
    for node in s.find_all('script',type='application/ld+json'):
        try:
            codes.append(json.loads(node.get_text()))
        except Exception:
            pass
    record=dict(url=url,status=r.status_code,variants=variants,product_title=product_title,ingredients_candidates=evidence,schema=codes,text=texts)
    return record

if __name__=='__main__':
    target=ROOT/'docs/sunscreens'
    target.mkdir(exist_ok=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        records=list(pool.map(fetch,URLS))
    (target/'research.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
    for r in records:
        print(r['url'],r['status'],r['variants'])
        print('INCI',r['ingredients_candidates'])
        print('SCHEMA',str(r['schema'])[:500])
