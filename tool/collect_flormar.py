import concurrent.futures
import json
import re
from pathlib import Path
import requests
from bs4 import BeautifulSoup

ROOT = Path(r'C:\Users\melisa uyar\Desktop\Navilo')
BASE = 'https://www.flormar.com.tr'
START = BASE + '/nail-enamel-yuksek-pigmentli-parlak-bitisli-oje-beyaz-8682536035880/'

def page(url):
    r = requests.get(url, timeout=35)
    r.raise_for_status()
    return BeautifulSoup(r.content.decode('utf-8'), 'html.parser')

def gtin(code):
    return len(code) == 13 and (sum(int(x) * (1 if i % 2 == 0 else 3) for i, x in enumerate(code[:-1])) + int(code[-1])) % 10 == 0

def collect(url):
    soup = page(url)
    code = re.search(r'(\d{13})/$', url).group(1)
    scripts = ' '.join(s.get_text() for s in soup.select('.analytics-data'))
    match = re.search(r'"products"\s*:\s*(\[.*?\])', scripts, re.S)
    products = json.loads(match.group(1)) if match else []
    product = next((p for p in products if p.get('id') == code), None)
    node = soup.select_one('pz-tab-content-item[tab="ingredients"]')
    if not gtin(code) or not product or not node:
        raise ValueError('Missing exact product or ingredient evidence: ' + url)
    text = node.get_text(' ', strip=True)
    if not text.startswith('INGREDIENTS:') or '+/-' not in text:
        raise ValueError('Incomplete INCI: ' + url)
    base, pigments = text.removeprefix('INGREDIENTS:').split('+/-', 1)
    selected = soup.select_one('option[selected][label]')
    shade = selected.get('label') if selected else product['variant']
    return dict(code=code, category='cosmetic', name='Flormar Nail Enamel ' + shade + ' 11 ml',
                ingredients=base.strip(), may_contain=pigments.strip(),
                source_name='Flormar · resmi ürün sayfası', source_url=url,
                checked_at='2026-10-13T00:00:00+03:00',
                evidence_status='manufacturer_product_page',
                allergens=[], traces=[], labels=[])

if __name__ == '__main__':
    soup = page(START)
    urls = sorted({BASE + o['url'] for o in soup.select('option[url]') if '/nail-enamel-' in o['url']})
    rows, errors = [], []
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
        futures = {pool.submit(collect, url): url for url in urls}
        for future in concurrent.futures.as_completed(futures):
            try:
                rows.append(future.result())
            except Exception as e:
                errors.append(str(e))
    rows.sort(key=lambda x: x['code'])
    assert len({r['code'] for r in rows}) == len(rows)
    output = ROOT / 'assets/curated_cosmetics.json'
    assert rows, 'No Flormar records; existing catalog preserved'
    existing = json.loads(output.read_text(encoding='utf-8')) if output.exists() else []
    preserved = [r for r in existing if not r['source_name'].startswith('Flormar')]
    assert not ({r['code'] for r in preserved} & {r['code'] for r in rows}), 'Barcode collision'
    output.write_text(json.dumps(preserved + rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    target = ROOT / 'docs/flormar'
    target.mkdir(parents=True, exist_ok=True)
    (target / 'flormar_verified.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (target / 'flormar_collection_errors.json').write_text(json.dumps(errors, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'products': len(rows), 'errors': errors}, ensure_ascii=False))
