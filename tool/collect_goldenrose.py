"""Collect selected Golden Rose shades with same-page GTIN and INCI evidence."""
import concurrent.futures
import json
import re
from pathlib import Path
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]
BASE = 'https://shop.goldenrose.com.tr'
ATTACHMENT = ROOT / 'docs/goldenrose/submitted.txt'
SEEDS = [
    (BASE + '/golden-rose-color-expert-nail-lacquer-clear-genis-fircali-oje', 'color-expert-nail-lacquer', {1,2,5,6,9,11,22,31,34,35,42,50,55,60,71,82,90,95,121,130}),
    (BASE + '/golden-rose-extreme-gel-shine-nail-color-34-jel-parlakliginda-oje', 'extreme-gel-shine-nail-color', {1,4,6,10,16,19,22,26,27,28,34,40,45,50,60}),
    (BASE + '/golden-rose-ice-color-nail-lacquer-158-mini-oje', 'ice-color-nail-lacquer', {101,105,106,112,118,124,128,132,139,144,150,162,168,1196,1120}),
]

def page(url):
    r = requests.get(url, timeout=35)
    r.raise_for_status()
    if urlparse(r.url).netloc != urlparse(BASE).netloc:
        raise ValueError('Unexpected redirect')
    return BeautifulSoup(r.content, 'html.parser'), r.url

def valid_gtin(code):
    return bool(re.fullmatch(r'\d{13}', code)) and (sum(int(n)*(1 if i%2==0 else 3) for i,n in enumerate(code[:-1]))+int(code[-1]))%10 == 0

def collect(url):
    soup, final_url = page(url)
    products = []
    for script in soup.find_all('script', type='application/ld+json'):
        document = json.loads(script.get_text())
        products += [p for p in document.get('@graph', []) if p.get('@type') == 'Product']
    if len(products) != 1:
        raise ValueError('Expected one product: '+url)
    p = products[0]
    code = p.get('gtin13', '')
    node = soup.select_one('#product-field4')
    title = soup.select_one('#product-title')
    if not valid_gtin(code) or not node or not title or title.get_text(' ', strip=True) != p['name']:
        raise ValueError('Incomplete product evidence: '+url)
    text = node.get_text(' ', strip=True)
    if not re.match(r'^INGREDIENTS\s*:', text, re.I):
        raise ValueError('Missing INCI: '+url)
    text = re.sub(r'^INGREDIENTS\s*:\s*', '', text, flags=re.I)
    parts = re.split(r'\[?\s*\+\s*/\s*-', text, maxsplit=1)
    ingredients = parts[0].strip().rstrip(',').strip()
    may_contain = ('+/- ' + parts[1].strip()) if len(parts) == 2 else ''
    return dict(code=code, category='cosmetic', name='Golden Rose ' + p['name'],
        ingredients=ingredients, may_contain=may_contain,
        source_name='Golden Rose · resmi ürün sayfası', source_url=final_url,
        checked_at='2026-10-13T00:00:00+03:00', evidence_status='manufacturer_product_page',
        allergens=[], traces=[], labels=[])

def main():
    urls = set()
    missing_shades = []
    for seed, token, desired in SEEDS:
        soup, _ = page(seed)
        found = set()
        urls.add(seed)
        seed_shade = re.search(re.escape(token)+r'-(\d+)-', seed)
        if seed_shade:
            found.add(int(seed_shade.group(1)))
        for a in soup.select('a[href]'):
            url = urljoin(BASE, a['href'])
            if urlparse(url).netloc != urlparse(BASE).netloc or re.search(r'\.(jpg|png|webp)$', url, re.I):
                continue
            match = re.search(re.escape(token)+r'-(\d+)-', url)
            if match:
                urls.add(url)
                found.add(int(match.group(1)))
        if 'clear' in seed:
            urls.add(seed)
        missing_shades += [dict(series=token, shade=s) for s in sorted(desired-found)]
    rows, errors = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(collect, u):u for u in sorted(urls)}
        for f in concurrent.futures.as_completed(futures):
            try:
                rows.append(f.result())
            except Exception as e:
                errors.append(dict(url=futures[f], error=str(e)))
    by_code = {}
    for row in rows:
        if row['code'] in by_code and row != by_code[row['code']]:
            raise ValueError('Conflicting duplicate GTIN '+row['code'])
        by_code[row['code']] = row
    assert by_code, 'No records collected; existing catalog preserved'
    existing = json.loads((ROOT/'assets/curated_cosmetics.json').read_text(encoding='utf-8'))
    preserved = [r for r in existing if not r['source_name'].startswith('Golden Rose')]
    assert not ({r['code'] for r in preserved} & by_code.keys()), 'Barcode collision'
    rows = sorted(by_code.values(), key=lambda r:r['code'])
    (ROOT/'assets/curated_cosmetics.json').write_text(json.dumps(preserved+rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    audit_dir = ROOT/'docs/goldenrose'
    audit_dir.mkdir(exist_ok=True)
    submitted = []
    for line in ATTACHMENT.read_text(encoding='utf-8').splitlines():
        m = re.match(r'(\d+)\s+(\d{13})\s+(.+?)\s+Base\s*(.*)$',line)
        if m:
            code = m.group(2)
            official = by_code.get(code)
            submitted.append(dict(index=int(m.group(1)),code=code,submitted_name=m.group(3),submitted_pigments=m.group(4),
                gtin_valid=valid_gtin(code),status='official_record_found' if official else 'unverified_not_imported',
                official_name=official['name'] if official else None,source_url=official['source_url'] if official else None))
    audit = dict(date='2026-10-13',imported=len(rows),submitted=submitted,missing_shades=missing_shades,errors=errors)
    (audit_dir/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(dict(imported=len(rows),matched_submitted=sum(r['status']=='official_record_found' for r in submitted),missing_shades=missing_shades,errors=errors),ensure_ascii=False))

if __name__ == '__main__':
    main()
