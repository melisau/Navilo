"""Add the reviewed 2026-10-25 batch: Turkish products that Open Food Facts /
Open Beauty Facts do not know, or know without an ingredient list.

Source rows (docs/new_products/not_in_open_facts_20261025.txt):
  code|name|ingredients|allergen statement|trace statement
Each was read from the Market Karşılaştır product page for that GTIN, which
shows barcode, name and ingredient text together. Coverage verdicts come
from tool/off_presence.py run in CI (open-facts-coverage workflow).
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_validation import valid_gtin  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
CATALOGUE = ROOT / 'assets/curated_products.json'
SOURCE = ROOT / 'docs/new_products/not_in_open_facts_20261025.txt'
NAMES = ROOT / 'docs/new_products/source_names_20261025.txt'
BATCH = 'not-in-open-facts-20261025'
WHEN = '2026-10-25T00:00:00+03:00'

# Open Facts coverage verdict per GTIN (CI run 2026-10-25).
NOT_IN_OPEN_FACTS = set('''
8690575044312 8690575085711 8693374011196 8693374011226 8690710001286
8690710138555 8690710139750 8690710107070 8691225152494 8691225152449
8691225155235 8697403873953 8699197160080 8699197161261 8699197160288
8690103853041 8692963150667
'''.split())
WITHOUT_INGREDIENTS = set('''
8690508103468 8690508153357 8690508654212 8690508007254 8690575045715
8690710137312 8690710009442 8690710141708 8690710009084 8690710070046
8690710136155 8699177445411 8691225153002 8691225153415 8697403871041
8692963150810
'''.split())

ALLERGENS = {
    '8693374011196': ['en:gluten'], '8693374011226': ['en:gluten'],
    '8690710001286': ['en:gluten', 'en:sesame-seeds', 'en:nuts'],
    '8690710138555': ['en:nuts'],
    '8690710107070': ['en:nuts'],
    '8690710009442': ['en:sesame-seeds', 'en:nuts'],
    '8690710141708': ['en:sesame-seeds'],
    '8690710070046': ['en:nuts'],
    '8690710136155': ['en:peanuts', 'en:sesame-seeds'],
    '8699197160288': ['en:gluten'],
}
MILK = {'8691225152494', '8691225152449', '8691225155235', '8691225153002',
        '8691225153415', '8697403873953', '8697403871041', '8699197160080',
        '8699197161261', '8692963150667', '8692963150810'}
TRACES = {
    '8690710001286': ['en:nuts', 'en:peanuts'],
    '8690710138555': ['en:peanuts', 'en:nuts', 'en:sesame-seeds'],
    '8690710107070': ['en:sesame-seeds', 'en:nuts', 'en:peanuts', 'en:gluten'],
    '8690710009442': ['en:nuts'],
    '8690710009084': ['en:nuts'],
    '8690710136155': ['en:nuts', 'en:gluten'],
    '8699177445411': ['en:lupin', 'en:nuts', 'en:gluten', 'en:celery', 'en:soybeans',
                      'en:sesame-seeds', 'en:milk', 'en:peanuts', 'en:eggs'],
}

TR = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')


def page_url(code, source_name):
    slug = re.sub(r'[^a-z0-9]+', '-', source_name.translate(TR).lower()).strip('-')
    return f'https://marketkarsilastir.com/fiyat/{code}-{slug}'


def main():
    names = dict(line.strip().split('|', 1) for line in
                 NAMES.read_text(encoding='utf-8').splitlines() if line.strip())
    rows = json.loads(CATALOGUE.read_text(encoding='utf-8'))
    known = {r['code'] for r in rows}
    added = []
    for line in SOURCE.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        code, name, ingredients, allergen_text, trace_text = line.split('|')
        assert valid_gtin(code), code
        assert code in NOT_IN_OPEN_FACTS | WITHOUT_INGREDIENTS, code
        if code in known:
            continue
        url = page_url(code, names[code])
        coverage = ('not_in_open_facts' if code in NOT_IN_OPEN_FACTS
                    else 'open_facts_without_ingredients')
        row = {
            'code': code,
            'name': name,
            'category': 'food',
            'ingredients': ingredients,
            'source_name': 'Market Karşılaştır ürün sayfası (GTIN ve içindekiler aynı sayfada)',
            'source_url': url,
            'barcode_source_url': url,
            'field_sources': {'code': [url], 'name': [url], 'ingredients': [url]},
            'allergens': (['en:milk'] if code in MILK else []) + ALLERGENS.get(code, []),
            'traces': TRACES.get(code, []),
            'labels': [],
            'source_type': 'retailer',
            'status': 'verified',
            'verified_at': WHEN,
            'checked_at': WHEN,
            'catalog_batch': BATCH,
            'ingredient_evidence': 'full_label_transcription',
            'evidence_status': 'retailer_reported_pending_package_check',
            'open_facts_coverage': coverage,
        }
        statement = ' '.join(t for t in (allergen_text, trace_text) if t)
        if statement:
            row['source_allergen_text'] = statement
        added.append(row)
    text = CATALOGUE.read_text(encoding='utf-8').rstrip()
    assert text.endswith(']')
    blocks = ['\n'.join('  ' + l for l in json.dumps(r, ensure_ascii=False, indent=2).splitlines())
              for r in added]
    new_text = text[:-1].rstrip() + ',\n' + ',\n'.join(blocks) + '\n]\n'
    json.loads(new_text)
    CATALOGUE.write_text(new_text, encoding='utf-8')
    print(f'added {len(added)} rows')


if __name__ == '__main__':
    main()
