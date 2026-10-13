import concurrent.futures
import json
import re
from pathlib import Path
from urllib.parse import urljoin
import requests
from bs4 import BeautifulSoup
from research_sunscreens import fetch

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/sunscreens'

def valid(code):
    return bool(re.fullmatch(r'\d{13}',code)) and (sum(int(n)*(1 if i%2==0 else 3) for i,n in enumerate(code[:-1]))+int(code[-1]))%10==0

def product_nodes(schema):
    for node in schema:
        if node.get('@type')=='Product':
            yield node
        yield from product_nodes(node.get('@graph',[]))

def main():
    urls={'https://b2c.cosrx.com/products/aloe-soothing-sun-cream-spf50-pa'}
    for collection,part in [('https://thepurestsolutions.com/collections/gunes-kremi','/products/'),('https://www.maruderm.com/gunes-bakim-urunleri','/urunler/')]:
        soup=BeautifulSoup(requests.get(collection,timeout=35).content,'html.parser')
        for a in soup.select('a[href]'):
            href=a['href']
            if part not in href or any(s in href for s in ['1-sana','gunes-sonrasi','spf-0','spf-15','bronzlastirici']):
                continue
            if 'maruderm' in collection and not ('gunes' in href or 'spf' in href):
                continue
            urls.add(urljoin(collection,href))
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results=list(pool.map(fetch,sorted(urls)))
    rows,errors=[],[]
    for result in results:
        try:
            assert result['status']==200
            inci=set(result['ingredients_candidates'])
            assert len(inci)==1, 'Missing or conflicting full INCI'
            products=list(product_nodes(result['schema']))
            variants=result['variants']
            if variants:
                assert len(variants)==1, 'Multiple sizes need variant-specific evidence'
                code=variants[0]['barcode'] or ''
                name=result['product_title']
            else:
                assert products, 'No barcode evidence'
                code=products[0].get('gtin13','')
                name=products[0].get('name','')
            assert valid(code) and name, 'Invalid GTIN or missing name'
            brand='COSRX' if 'cosrx.com' in result['url'] else 'The Purest Solutions' if 'thepurestsolutions.com' in result['url'] else 'Maruderm'
            if not name.casefold().startswith(brand.casefold()):
                name=brand+' '+name
            rows.append(dict(code=code,category='cosmetic',name=name,ingredients=next(iter(inci)),may_contain='',
                source_name=brand+' · resmi ürün sayfası',source_url=result['url'],
                checked_at='2026-10-13T00:00:00+03:00',evidence_status='manufacturer_product_page',
                allergens=[],traces=[],labels=[],catalog_batch='sunscreens-20261013'))
        except (AssertionError,KeyError) as e:
            errors.append(dict(url=result['url'],reason=str(e)))
    by_code={}
    for r in rows:
        if r['code'] in by_code:
            assert by_code[r['code']]['ingredients']==r['ingredients'], 'Conflicting duplicate'
        by_code[r['code']]=r
    assert by_code, 'No imports; catalog preserved'
    existing=json.loads((ROOT/'assets/curated_cosmetics.json').read_text(encoding='utf-8'))
    preserved=[r for r in existing if r.get('catalog_batch')!='sunscreens-20261013']
    assert not ({r['code'] for r in preserved}&by_code.keys()), 'Existing barcode conflict'
    (ROOT/'assets/curated_cosmetics.json').write_text(json.dumps(preserved+list(by_code.values()),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'manufacturer_evidence.json').write_text(json.dumps(results,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'collection_errors.json').write_text(json.dumps(errors,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    text=(OUT/'submitted.txt').read_text(encoding='utf-8')
    submitted=[]
    for line in text.splitlines():
        if re.match(r'^\d+\t\d{13}\t',line):
            index,code,name,ingredients=re.split(r'\t+',line,maxsplit=3)
            submitted.append(dict(index=int(index),code=code,name=name,ingredients=ingredients,gtin_valid=valid(code),
                status='invalid_gtin_not_imported' if not valid(code) else 'no_exact_source_match_not_imported'))
    (OUT/'submitted_audit.json').write_text(json.dumps(submitted,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(imported=len(by_code),total=len(preserved)+len(by_code),invalid_submitted=sum(not r['gtin_valid'] for r in submitted),errors=errors),ensure_ascii=False))

if __name__=='__main__':
    main()
