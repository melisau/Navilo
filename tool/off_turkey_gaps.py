"""Find products sold in Turkey that Open Facts knows by barcode but without
an ingredient list, and add them to the in-app contribution list.

Only barcode, name, brand and quantity are taken from Open Food Facts /
Open Beauty Facts (ODbL, attributed). Ingredients are never guessed: the
candidates ask users to photograph the package. Nothing is marked
`verified` and nothing is added to the reviewed catalogue.

Usage:
    python tool/off_turkey_gaps.py --limit 50 [--pages 3] [--dry-run]
"""
import argparse
import json
import os
import re
import sys
import time
from datetime import date
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_validation import excluded_codes, valid_gtin  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = ROOT / 'assets/contribution_candidates.json'
CATALOGUES = [ROOT / 'assets/curated_products.json',
              ROOT / 'assets/curated_cosmetics.json']
EXCLUSIONS_DART = ROOT / 'lib/domain/catalogue_exclusions.dart'
USER_AGENT = 'Navilo/0.1 (https://github.com/melisau/Navilo; catalogue gaps)'
SOURCES = [
    ('world.openfoodfacts.org', 'food', 'Open Food Facts'),
    ('world.openbeautyfacts.org', 'cosmetic', 'Open Beauty Facts'),
]
FIELDS = 'code,product_name,product_name_tr,brands,quantity,countries_tags,states_tags'
# Open Facts asks for at most ~10 search requests per minute.
SEARCH_PAUSE_SECONDS = 7


def known_codes():
    codes = set(excluded_codes())
    for path in CATALOGUES:
        if path.exists():
            codes.update(row.get('code', '') for row in
                         json.loads(path.read_text(encoding='utf-8')))
    if EXCLUSIONS_DART.exists():
        codes.update(re.findall(r"'(\d{8,14})'",
                                EXCLUSIONS_DART.read_text(encoding='utf-8')))
    return codes


def candidate_codes(rows):
    codes = set()
    for row in rows:
        if row.get('candidate_barcode'):
            codes.add(row['candidate_barcode'])
        match = re.search(r'(\d{8,14})$', row.get('id', ''))
        if match:
            codes.add(match.group(1))
    return codes


def display_name(product):
    name = (product.get('product_name_tr') or product.get('product_name') or '').strip()
    if not name:
        return None
    brand = (product.get('brands') or '').split(',')[0].strip()
    if brand and not name.lower().startswith(brand.lower()):
        name = f'{brand} {name}'
    quantity = (product.get('quantity') or '').strip()
    if quantity and quantity.lower() not in name.lower():
        name = f'{name} ({quantity})'
    return re.sub(r'\s+', ' ', name)


def search(session, host, page):
    response = session.get(
        f'https://{host}/api/v2/search',
        params={
            'countries_tags': 'en:turkey',
            'states_tags': 'en:ingredients-to-be-completed',
            'sort_by': 'unique_scans_n',
            'fields': FIELDS,
            'page_size': 100,
            'page': page,
        },
        timeout=30)
    if response.status_code == 429:
        raise RuntimeError(f'{host}: rate limited; retry later')
    response.raise_for_status()
    payload = response.json()
    products = payload.get('products')
    if not isinstance(products, list):
        raise ValueError(f'{host}: unexpected search response')
    return products


def collect(limit, pages, session):
    existing = json.loads(CANDIDATES.read_text(encoding='utf-8'))
    skip = known_codes() | candidate_codes(existing)
    found, report = [], []
    today = date.today().isoformat()
    for host, category, source_name in SOURCES:
        for page in range(1, pages + 1):
            if len(found) >= limit:
                break
            products = search(session, host, page)
            time.sleep(SEARCH_PAUSE_SECONDS)
            if not products:
                break
            for product in products:
                code = str(product.get('code') or '')
                if len(found) >= limit:
                    break
                if code in skip or not valid_gtin(code):
                    continue
                # Double-check the filters the API applied.
                if 'en:turkey' not in (product.get('countries_tags') or []):
                    continue
                if 'en:ingredients-to-be-completed' not in (product.get('states_tags') or []):
                    continue
                name = display_name(product)
                if not name:
                    continue
                skip.add(code)
                found.append({
                    'id': f'off-gap-{code}',
                    'name': name,
                    'category': category,
                    'candidate_barcode': code,
                    'missing_fields': ['ingredients', 'package_photo'],
                    'source_name': f'{source_name} (ODbL) · içerik eksik',
                    'source_url': f'https://{host}/product/{code}',
                    'found_at': today,
                })
        report.append(f'{source_name}: {sum(1 for r in found if r["category"] == category)} new')
    return existing, found, report


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--limit', type=int, default=50)
    parser.add_argument('--pages', type=int, default=3)
    parser.add_argument('--dry-run', action='store_true')
    args = parser.parse_args()
    session = requests.Session()
    session.headers['User-Agent'] = USER_AGENT
    existing, found, report = collect(args.limit, args.pages, session)
    summary = [f'Found {len(found)} Turkish products with a barcode but no ingredients.',
               *report, *[f'- {r["candidate_barcode"]} · {r["name"]}' for r in found]]
    print('\n'.join(summary))
    if os.environ.get('GITHUB_ACTIONS'):
        # One annotation keeps the result visible on the pull request.
        text = '\n'.join(summary)[:3500].replace('%', '%25').replace('\n', '%0A')
        print(f'::notice title=Catalogue gaps ({len(found)} found)::{text}')
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as out:
            out.write('\n'.join(summary) + '\n')
    if found and not args.dry_run:
        append_candidates(found)


def append_candidates(rows):
    """Append without reformatting the hand-edited entries above."""
    text = CANDIDATES.read_text(encoding='utf-8').rstrip()
    if not text.endswith(']'):
        raise ValueError('contribution_candidates.json must be a JSON array')
    body = text[:-1].rstrip()
    blocks = [
        '\n'.join('  ' + line for line in
                  json.dumps(row, ensure_ascii=False, indent=2).splitlines())
        for row in rows
    ]
    separator = ',\n' if body.rstrip().endswith('}') else '\n'
    new_text = body + separator + ',\n'.join(blocks) + '\n]\n'
    json.loads(new_text)  # never write an invalid file
    CANDIDATES.write_text(new_text, encoding='utf-8')


if __name__ == '__main__':
    main()
