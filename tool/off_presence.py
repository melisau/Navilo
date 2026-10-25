"""Check whether barcodes are already known to Open Food Facts, Open Beauty
Facts or Open Products Facts, and whether those records have ingredients.

Navilo looks these databases up after its own catalogue, so a product only
adds coverage when it is missing there (or has no ingredient list).

Input: a JSON array of objects with `code` (and optionally `name`).
Usage: python tool/off_presence.py docs/new_products/queue.json [--out report.json]
"""
import argparse
import json
import os
import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_validation import valid_gtin  # noqa: E402

USER_AGENT = 'Navilo/0.1 (https://github.com/melisau/Navilo; coverage check)'
HOSTS = [('world.openfoodfacts.org', 'OFF'),
         ('world.openbeautyfacts.org', 'OBF'),
         ('world.openproductsfacts.org', 'OPF')]
FIELDS = 'code,product_name,ingredients_text,ingredients_text_tr,ingredients_text_en'


def lookup(session, host, code, attempts=3):
    """'missing', 'no_ingredients', 'has_ingredients', or 'error: …'."""
    for attempt in range(1, attempts + 1):
        try:
            r = session.get(f'https://{host}/api/v2/product/{code}',
                            params={'fields': FIELDS}, timeout=30)
            if r.status_code == 404:
                return 'missing'
            if r.status_code in (429, 500, 502, 503, 504):
                raise RuntimeError(f'HTTP {r.status_code}')
            r.raise_for_status()
            data = r.json()
            if data.get('status') != 1:
                return 'missing'
            p = data.get('product') or {}
            text = ' '.join(str(p.get(k) or '') for k in
                            ('ingredients_text', 'ingredients_text_tr', 'ingredients_text_en'))
            return 'has_ingredients' if text.strip() else 'no_ingredients'
        except Exception as error:  # noqa: BLE001
            if attempt == attempts:
                return f'error: {error}'[:120]
            time.sleep(10 * attempt)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('queue')
    parser.add_argument('--out')
    args = parser.parse_args()
    rows = json.loads(Path(args.queue).read_text(encoding='utf-8'))
    session = requests.Session()
    session.headers['User-Agent'] = USER_AGENT
    report, lines = [], []
    for row in rows:
        code = str(row['code'])
        if not valid_gtin(code):
            result = {'code': code, 'verdict': 'invalid_gtin'}
        else:
            found = {}
            for host, label in HOSTS:
                found[label] = lookup(session, host, code)
                time.sleep(0.8)  # product API allows ~100 requests/minute
            states = set(found.values())
            if any(s.startswith('error') for s in states):
                verdict = 'unknown'
            elif 'has_ingredients' in states:
                verdict = 'in_open_facts'
            elif 'no_ingredients' in states:
                verdict = 'open_facts_without_ingredients'
            else:
                verdict = 'not_in_open_facts'
            result = {'code': code, 'verdict': verdict, **found}
        result['name'] = row.get('name', '')
        report.append(result)
        lines.append(f"{result['verdict']:32} {code} {result['name']}")
    counts = {}
    for r in report:
        counts[r['verdict']] = counts.get(r['verdict'], 0) + 1
    summary = [f'{len(report)} barcodes: ' + ', '.join(f'{k}={v}' for k, v in sorted(counts.items())),
               *lines]
    print('\n'.join(summary))
    if os.environ.get('GITHUB_ACTIONS'):
        text = '\n'.join(summary)[:3800].replace('%', '%25').replace('\n', '%0A')
        print(f'::notice title=Open Facts coverage ({len(report)} checked)::{text}')
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a', encoding='utf-8') as out:
            out.write('```\n' + '\n'.join(summary) + '\n```\n')
    if args.out:
        Path(args.out).write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n',
                                  encoding='utf-8')


if __name__ == '__main__':
    main()
