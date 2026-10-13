"""Match missing images to barcode, then exact product name on evidence pages."""
import concurrent.futures
import json
import re
import unicodedata
from pathlib import Path
from datetime import datetime, timezone
from urllib.parse import urljoin, urlparse
import requests
from bs4 import BeautifulSoup

ROOT = Path(__file__).resolve().parents[1]

def normalized(value):
    return re.sub(r'\W+', ' ', unicodedata.normalize('NFKC', str(value)).casefold()).strip()

def objects(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from objects(child)
    elif isinstance(value, list):
        for child in value:
            yield from objects(child)

def lookup(row):
    if row.get('image_url'):
        return None
    source = row['source_url']
    try:
        response = requests.get(source, timeout=25)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')
        products = []
        for script in soup.find_all('script', type='application/ld+json'):
            try:
                products.extend(p for p in objects(json.loads(script.get_text()))
                                if 'Product' in p.get('@type', []))
            except (ValueError, TypeError):
                pass
        candidates = []
        # Prefer structured barcode evidence. Reject explicitly different GTINs.
        for product in products:
            codes = {str(product[k]) for k in ('gtin', 'gtin8', 'gtin12', 'gtin13', 'gtin14') if product.get(k)}
            if codes and row['code'] not in codes:
                continue
            method = ('barcode' if row['code'] in codes else
                      'name' if normalized(product.get('name')) == normalized(row['name']) else None)
            if method:
                value = product.get('image')
                if isinstance(value, list):
                    value = value[0] if value else None
                if isinstance(value, dict):
                    value = value.get('url') or value.get('contentUrl')
                if isinstance(value, str):
                    candidates.append((method, value))
        # Existing catalogue source URLs are evidence for this exact product.
        # Only accept page-level images when the barcode is in the final URL,
        # or the page heading/title exactly matches the catalogue name.
        titles = [n.get_text(' ', strip=True) for n in soup.find_all('h1')]
        titles += [n.get('content', '') for n in soup.find_all('meta', property='og:title')]
        method = ('barcode' if re.search(r'(?<!\d)' + re.escape(row['code']) + r'(?!\d)', response.url)
                  else 'name' if normalized(row['name']) in [normalized(t) for t in titles] else None)
        if method:
            for node in soup.find_all('meta', property='og:image'):
                if node.get('content'):
                    candidates.append((method, node['content']))
        candidates.sort(key=lambda c: c[0] != 'barcode')
        for method, value in candidates:
            image = urljoin(response.url, value)
            if urlparse(image).scheme != 'https':
                continue
            with requests.get(image, stream=True, timeout=20) as check:
                if check.status_code != 200 or not check.headers.get('Content-Type', '').startswith('image/'):
                    continue
            return dict(image_url=image, image_source_url=response.url,
                        image_match_method=method, image_matched_code=row['code'],
                        image_attribution=urlparse(response.url).hostname,
                        image_checked_at=datetime.now(timezone.utc).isoformat(),
                        image_evidence='catalogue_product_page')
        return {'reason': 'no_exact_image_match'}
    except requests.RequestException as error:
        return {'reason': type(error).__name__}

def main():
    report = {'checked_at': datetime.now(timezone.utc).isoformat(), 'categories': {}}
    for category, filename in [('food', 'curated_products.json'), ('cosmetic', 'curated_cosmetics.json')]:
        path = ROOT / 'assets' / filename
        rows = json.loads(path.read_text(encoding='utf-8'))
        added, missing = [], []
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
            for row, result in zip(rows, pool.map(lookup, rows)):
                if result and 'image_url' in result:
                    row.update(result)
                    added.append({'code': row['code'], 'name': row['name'], **result})
                elif result:
                    missing.append({'code': row['code'], 'name': row['name'], **result})
        path.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        summary = {'total': len(rows), 'added': len(added),
                   'with_image': sum(bool(r.get('image_url')) for r in rows),
                   'without_image': sum(not r.get('image_url') for r in rows)}
        report['categories'][category] = {**summary, 'matches': added, 'unmatched': missing}
        print(category, summary, flush=True)
    (ROOT / 'docs/catalogue_image_enrichment.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

if __name__ == '__main__':
    main()
