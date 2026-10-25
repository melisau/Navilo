"""Download Open Food Facts ingredient-panel photos of Turkish products whose
ingredient text is missing, so a reviewer can transcribe the label.

Photos are CC BY-SA (Open Food Facts contributors). Output goes to
`docs/new_products/off_photos/` as <GTIN>.jpg (longest side 1600 px) plus
index.json with name, brand, image URL and product URL. Nothing is added to
the catalogue automatically.

Usage: python tool/off_ingredient_photos.py --limit 80 [--pages 5]
"""
import argparse
import io
import json
import re
import sys
import time
from pathlib import Path

import requests
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_validation import valid_gtin  # noqa: E402
from catalog_validation import excluded_codes  # noqa: E402

SKIP_NAME = re.compile(r'\b(sigara|tütün|maden suyu|kaynak suyu|içme suyu)\b', re.IGNORECASE)


def known_codes():
    codes = set(excluded_codes())
    for name in ('curated_products.json', 'curated_cosmetics.json'):
        path = ROOT / 'assets' / name
        if path.exists():
            codes |= {r.get('code', '') for r in json.loads(path.read_text(encoding='utf-8'))}
    return codes


def display_name(product):
    name = (product.get('product_name_tr') or product.get('product_name') or '').strip()
    brand = (product.get('brands') or '').split(',')[0].strip()
    code = str(product.get('code') or '')
    if not name or not brand or len(name) < 4 or code in name or SKIP_NAME.search(name):
        return None
    if not name.lower().startswith(brand.lower()):
        name = f'{brand} {name}'
    quantity = (product.get('quantity') or '').strip()
    if quantity and quantity.lower() not in name.lower():
        name = f'{name} ({quantity})'
    return re.sub(r'\s+', ' ', name)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/new_products/off_photos'
UA = 'Navilo/0.1 (https://github.com/melisau/Navilo; ingredient photo review)'
FIELDS = 'code,product_name,product_name_tr,brands,quantity,countries_tags,states_tags,categories_tags,images'


def image_path(code):
    if len(code) <= 8:
        return code
    return '/'.join([code[0:3], code[3:6], code[6:9], code[9:]])


def ingredient_image(code, images):
    """Full-size URL of the selected ingredients photo (Turkish first)."""
    keys = sorted((k for k in (images or {}) if k.startswith('ingredients')),
                  key=lambda k: (k != 'ingredients_tr', k != 'ingredients', k))
    for key in keys:
        rev = (images.get(key) or {}).get('rev')
        if rev:
            return (f'https://images.openfoodfacts.org/images/products/'
                    f'{image_path(code)}/{key}.{rev}.full.jpg')
    return None


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--limit', type=int, default=80)
    p.add_argument('--pages', type=int, default=5)
    args = p.parse_args()
    s = requests.Session()
    s.headers['User-Agent'] = UA
    OUT.mkdir(parents=True, exist_ok=True)
    index_file = OUT / 'index.json'
    index = json.loads(index_file.read_text(encoding='utf-8')) if index_file.exists() else []
    skip = known_codes() | {r['code'] for r in index}
    added = 0
    for page in range(1, args.pages + 1):
        if added >= args.limit:
            break
        for attempt in range(3):
            r = s.get('https://world.openfoodfacts.org/api/v2/search', params={
                'countries_tags': 'en:turkey',
                'states_tags': 'en:ingredients-to-be-completed',
                'sort_by': 'unique_scans_n', 'fields': FIELDS,
                'page_size': 100, 'page': page}, timeout=60)
            if r.status_code < 500:
                break
            time.sleep(20 * (attempt + 1))
        if r.status_code >= 400:
            print(f'search page {page}: HTTP {r.status_code}; stopping')
            break
        time.sleep(7)
        for prod in r.json().get('products', []):
            if added >= args.limit:
                break
            code = str(prod.get('code') or '')
            if code in skip or not valid_gtin(code):
                continue
            name = display_name(prod)
            url = ingredient_image(code, prod.get('images'))
            if not name or not url:
                continue
            try:
                img = s.get(url, timeout=60)
                img.raise_for_status()
                im = Image.open(io.BytesIO(img.content)).convert('RGB')
                im.thumbnail((1600, 1600))
                im.save(OUT / f'{code}.jpg', 'JPEG', quality=82)
            except Exception as error:  # noqa: BLE001
                print('skip', code, error)
                continue
            time.sleep(1)
            skip.add(code)
            added += 1
            index.append({'code': code, 'name': name, 'image_url': url,
                          'product_url': f'https://world.openfoodfacts.org/product/{code}',
                          'license': 'CC BY-SA 3.0, Open Food Facts contributors'})
            print(code, name)
    index_file.write_text(json.dumps(index, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(f'{added} photos added, {len(index)} total')


if __name__ == '__main__':
    main()
