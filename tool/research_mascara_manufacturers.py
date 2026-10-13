"""Collect source-backed mascara label facts, without changing application data."""
import json,re,concurrent.futures
from pathlib import Path
from urllib.parse import urljoin
import requests
from bs4 import BeautifulSoup
from tool.catalog_validation import valid_gtin

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/mascara_research_20261013'

def walk(x):
    if isinstance(x,dict):
        yield x
        for v in x.values():yield from walk(v)
    elif isinstance(x,list):
        for v in x:yield from walk(v)

def fetch(url):
    try:
        response=requests.get(url,timeout=25)
        response.raise_for_status()
        soup=BeautifulSoup(response.content.decode('utf8'),'html.parser')
        products=[]
        for script in soup.find_all('script',type='application/ld+json'):
            try:products.extend(p for p in walk(json.loads(script.get_text())) if p.get('@type')=='Product')
            except (ValueError,TypeError):pass
        product=products[0] if products else {}
        code=str(product.get('gtin13') or product.get('gtin') or '')
        if not code and 'flormar.com.tr' in url:
            m=re.search(r'(\d{13})/$',url)
            if m and m[1] in response.text:code=m[1]
        name=product.get('name') or (soup.h1.get_text(' ',strip=True) if soup.h1 else '')
        if re.search(r'eyebrow|\bkaş\b|primer|maskara baz',name,re.I):return {'source_url':url,'name':name,'reason':'not_lash_mascara'}
        tab=soup.select_one('pz-tab-content-item[tab="ingredients"]')
        if tab:
            ingredient=tab.get_text(' ',strip=True)
        else:
            nodes=soup.find_all(string=lambda x:x and re.search(r'INGREDIENTS\s*:',str(x),re.I) and len(str(x))>100)
            texts=[str(n).strip() for n in nodes if n.parent.name not in ['script','style']]
            ingredient=min(texts,key=len) if texts else ''
        ingredient=re.sub(r'^INGREDIENTS\s*:\s*','',ingredient,flags=re.I)
        row={'code':code,'name':name,'brand':'Flormar' if 'flormar.com.tr' in url else 'Golden Rose',
             'ingredients':ingredient,'source_url':response.url,'barcode_source_url':response.url,
             'ingredients_source_url':response.url,'turkey_listing_url':response.url,
             'source_type':'manufacturer','status':'source_fields_matched',
             'snapshot_text':ingredient}
        if not valid_gtin(code):row['reason']='missing_or_invalid_gtin'
        elif len(ingredient)<80:row['reason']='full_inci_missing'
        return row
    except requests.RequestException as e:return {'source_url':url,'reason':type(e).__name__}

def main():
    urls=set()
    text=(OUT/'flormar.html').read_text(encoding='utf8')
    soup=BeautifulSoup(text,'html.parser')
    for a in soup.find_all('a',href=True):
        if re.search(r'\d{13}/$',a['href']) and re.search('maskara|mascara',a['href'],re.I):urls.add(urljoin('https://www.flormar.com.tr',a['href']))
    for file in ['golden_color_links.json','golden_black_links.json']:
        for url in json.loads((OUT/file).read_text(encoding='utf8')):
            if url.startswith('/') and re.search('mascara|maskara',url,re.I):urls.add(urljoin('https://shop.goldenrose.com.tr',url))
    rows=[]
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for row in pool.map(fetch,sorted(urls)):
            rows.append(row)
            print(row.get('code'),row.get('name'),row.get('reason','matched'),flush=True)
    (OUT/'manufacturer_records.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
    print('matched',sum('reason' not in r for r in rows),'total',len(rows),flush=True)

if __name__=='__main__':main()
