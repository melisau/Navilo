"""Attach exact-barcode CC BY-SA image references; never overwrite ingredients.

By default uses previously cached Open Food Facts responses. --refresh requests
missing references in batches, with search rate limits and no retry on denial.
"""
import argparse
import json
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse
import requests

ROOT = Path(__file__).resolve().parents[1]


def image_for(product, code):
    value = product.get('image_front_url')
    if not isinstance(value, str):
        return None
    uri = urlparse(value)
    # Verify the image belongs to this barcode, including its leading zeroes.
    path = uri.path.removeprefix('/images/products/').split('/')
    if uri.scheme != 'https' or uri.hostname != 'images.openfoodfacts.org':
        return None
    if ''.join(path[:-1]) != code:
        return None
    return value


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--refresh', action='store_true')
    args = parser.parse_args()
    asset = ROOT / 'assets/curated_products.json'
    rows = json.loads(asset.read_text(encoding='utf-8'))
    codes = {r['code'] for r in rows}
    images = {}
    for path in (ROOT / 'docs').rglob('*.json'):
        try:
            data = json.loads(path.read_text(encoding='utf-8'))
        except (ValueError, OSError):
            continue
        if not isinstance(data, dict) or data.get('status') != 1:
            continue
        product = data.get('product')
        if not isinstance(product, dict):
            continue
        code = str(product.get('code') or data.get('code') or path.stem)
        image = image_for(product, code)
        if code in codes and image:
            images[code] = image
    errors = []
    if args.refresh:
        missing = sorted(codes - images.keys())
        for offset in range(0, len(missing), 50):
            batch = set(missing[offset:offset + 50])
            try:
                response = requests.get(
                    'https://world.openfoodfacts.org/api/v2/search',
                    params={'code': ','.join(sorted(batch)), 'page_size': 100,
                            'fields': 'code,image_front_url'},
                    headers={'User-Agent': 'Navilo/0.1 (catalogue image collection)'},
                    timeout=30)
                response.raise_for_status()
                products = response.json().get('products', [])
                for product in products:
                    code = str(product.get('code', ''))
                    image = image_for(product, code)
                    if code in batch and image:
                        images[code] = image
            except (requests.RequestException, ValueError) as error:
                errors.append(str(error))
                break  # Respect provider denial/outage; no identity changes or retries.
            if offset + 50 < len(missing):
                time.sleep(7)
    for row in rows:
        code = row['code']
        if code in images:
            row.update(image_url=images[code], image_license='CC-BY-SA-3.0',
                       image_attribution='Open Food Facts contributors',
                       image_source_url=f'https://world.openfoodfacts.org/product/{code}')
    asset.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    report = {'checked_at': datetime.now(timezone.utc).isoformat(),
              'food_products': len(rows), 'images_added': len(images),
              'provider_errors': errors, 'images': images,
              'licence_reference': 'https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/license-be-on-the-legal-side/'}
    (ROOT / 'docs/catalogue_images_report.json').write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({k: v for k, v in report.items() if k != 'images'}))


if __name__ == '__main__':
    main()
