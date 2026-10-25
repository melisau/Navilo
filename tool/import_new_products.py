"""Import reviewed product transcriptions from docs/new_products/*.txt.

Line format (pipe separated):
  code|name|ingredients|allergen statement|trace statement[|extra]
where `extra` depends on the kind:
  marketkarsilastir  (none)  product page shows GTIN and ingredients together
  danet              source URL|kcal|fat|sat|carb|sugars|protein|salt
                     (online.danet.com.tr page with Barkod, ingredients, table)
  off_photo          100g:kcal,fat,sat,carb,sugars,fibre,protein,salt (optional)
                     transcribed by a reviewer from the ingredient photo on
                     Open Food Facts (CC BY-SA); Open Food Facts had no text

Allergen and trace tags are derived from the ingredient text and the label's
own statements (TGK Annex 1 groups). Coverage verdicts come from
docs/new_products/coverage_*.txt (output of tool/off_presence.py in CI).

Usage: python tool/import_new_products.py KIND FILE BATCH
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from catalog_validation import valid_gtin  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
CATALOGUE = ROOT / 'assets/curated_products.json'
NAMES = ROOT / 'docs/new_products/source_names_20261025.txt'
WHEN = '2026-10-25T00:00:00+03:00'
TR = str.maketrans('çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')

# Phrases that contain an allergen word but are not that allergen.
NOT_ALLERGEN = [
    'peynir mayası', 'hindistan cevizi', 'hindistancevizi', 'laktaz', 'kakao yağı',
    'süt kültürü', 'yoğurt kültürü', 'muskat cevizi', 'yerine geçer',
    'domuz', 'ayçiçek', 'kakao kitlesi',
]
ALLERGENS = [
    ('en:gluten', r'buğday|\bun\b|unu\b|gluten|glüten|irmik|bulgur|çavdar|arpa|yulaf|malt|kepek|şehriye|makarna|erişte'),
    ('en:milk', r'süt|laktoz|peynir|tereyağ|krema|kefir|yoğurt|whey|kazein|sade yağ'),
    ('en:eggs', r'yumurta'),
    ('en:soybeans', r'soya'),
    ('en:peanuts', r'yer ?fıstı|yerfıstı'),
    ('en:nuts', r'fındık|ceviz|badem|antep ?fıstı|antepfıstı|kaju|sert kabuklu|pekan|macadamia|brezilya'),
    ('en:sesame-seeds', r'susam|tahin'),
    ('en:mustard', r'hardal'),
    ('en:celery', r'kereviz'),
    ('en:lupin', r'acı bakla|lupin'),
    ('en:sulphur-dioxide-and-sulphites', r'sülfit|kükürt dioksit|metabisülfit'),
    ('en:fish', r'balı[kğ]|sardalya|\bton\b|levrek|mezgit|hamsi|somon|uskumru|alabalık|ançüez'),
    ('en:crustaceans', r'karides|kabuklular'),
    ('en:molluscs', r'yumuşakça|midye|kalamar|ahtapot|istiridye'),
]
NEGATIVE = re.compile(r'içermez|içermemektedir|bulunmamaktadır', re.IGNORECASE)


def tags(text):
    text = text.lower()
    for phrase in NOT_ALLERGEN:
        text = text.replace(phrase, ' ')
    found = []
    for tag, pattern in ALLERGENS:
        probe = text
        if tag == 'en:nuts':  # "yer fıstığı" is a peanut, not a tree nut
            probe = re.sub(r'yer ?fıstı\w*|yerfıstı\w*|amerikan fıstı\w*', ' ', text)
        if re.search(pattern, probe):
            found.append(tag)
    return found


def coverage():
    verdicts = {}
    for path in (ROOT / 'docs/new_products').glob('coverage_*.txt'):
        for line in path.read_text(encoding='utf-8').splitlines():
            parts = line.split()
            if len(parts) >= 2 and parts[0] in ('not_in_open_facts', 'open_facts_without_ingredients',
                                                'in_open_facts'):
                verdicts[parts[1]] = parts[0]
    return verdicts


def mk_url(code, names):
    slug = re.sub(r'[^a-z0-9]+', '-', names[code].translate(TR).lower()).strip('-')
    return f'https://marketkarsilastir.com/fiyat/{code}-{slug}'


def nutrition(values, basis):
    keys = ['energyKcal', 'fat', 'saturatedFat', 'carbohydrate', 'sugars', 'fibre', 'protein', 'salt']
    out = {'basis': basis, 'source': 'catalogue'}
    for key, value in zip(keys, values):
        if value not in ('', None):
            out[key] = float(value)
    return out


def main():
    kind, path, batch = sys.argv[1], Path(sys.argv[2]), sys.argv[3]
    names = dict(line.strip().split('|', 1) for line in
                 NAMES.read_text(encoding='utf-8').splitlines() if '|' in line)
    verdicts = coverage()
    rows = json.loads(CATALOGUE.read_text(encoding='utf-8'))
    known = {r['code'] for r in rows}
    added, skipped = [], []
    for line in path.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        parts = line.split('|')
        code, name, ingredients, allergen_text, trace_text = parts[:5]
        extra = parts[5:]
        if not valid_gtin(code) or code in known or code in {r['code'] for r in added}:
            skipped.append(code)
            continue
        verdict = verdicts.get(code)
        if verdict == 'in_open_facts' or (kind != 'off_photo' and verdict is None):
            skipped.append(code)
            continue
        if kind == 'off_photo':
            verdict = verdict or 'open_facts_without_ingredients'
        statement_tags = [] if NEGATIVE.search(allergen_text) else tags(allergen_text)
        allergens = set(tags(ingredients)) | set(statement_tags)
        if re.search(r'gl[uü]ten içermez|glutensiz', allergen_text + name, re.IGNORECASE):
            allergens.discard('en:gluten')  # labelled gluten-free (e.g. certified oats)
        allergens = sorted(allergens)
        traces = sorted(set(tags(trace_text)) - set(allergens))
        row = {'code': code, 'name': name, 'category': 'food', 'ingredients': ingredients}
        if kind == 'marketkarsilastir':
            url = mk_url(code, names)
            row.update({
                'source_name': 'Market Karşılaştır ürün sayfası (GTIN ve içindekiler aynı sayfada)',
                'source_url': url, 'barcode_source_url': url,
                'field_sources': {'code': [url], 'name': [url], 'ingredients': [url]},
                'source_type': 'retailer',
                'evidence_status': 'retailer_reported_pending_package_check',
            })
        elif kind == 'danet':
            url = extra[0]
            kcal, fat, sat, carb, sugars, protein, salt = extra[1:8]
            row.update({
                'source_name': 'Danet resmi online mağaza ürün sayfası (Barkod, içindekiler ve besin değerleri)',
                'source_url': url, 'barcode_source_url': url,
                'field_sources': {'code': [url], 'name': [url], 'ingredients': [url], 'nutrition': [url]},
                'source_type': 'manufacturer',
                'evidence_status': 'manufacturer_product_page',
                'nutrition': nutrition([kcal, fat, sat, carb, sugars, '', protein, salt], '100g'),
            })
        elif kind == 'off_photo':
            url = f'https://world.openfoodfacts.org/product/{code}'
            row.update({
                'source_name': 'Open Food Facts içindekiler fotoğrafı (CC BY-SA), Navilo tarafından okundu',
                'source_url': url, 'barcode_source_url': url,
                'field_sources': {'code': [url], 'name': [url], 'ingredients': [url]},
                'source_type': 'open_food_facts',
                'evidence_status': 'community_photo_transcription_pending_package_check',
                'image_license': 'CC-BY-SA-3.0',
                'image_attribution': 'Open Food Facts contributors',
            })
            if extra and extra[0].startswith('100'):
                basis, values = extra[0].split(':', 1)
                row['nutrition'] = nutrition(values.split(','), '100ml' if basis == '100ml' else '100g')
                row['field_sources']['nutrition'] = [url]
        else:
            raise SystemExit(f'unknown kind {kind}')
        row.update({
            'allergens': allergens, 'traces': traces, 'labels': [],
            'status': 'verified', 'verified_at': WHEN, 'checked_at': WHEN,
            'catalog_batch': batch, 'ingredient_evidence': 'full_label_transcription',
            'open_facts_coverage': verdict,
        })
        statement = ' '.join(t for t in (allergen_text, trace_text) if t)
        if statement:
            row['source_allergen_text'] = statement
        added.append(row)
    if added:
        text = CATALOGUE.read_text(encoding='utf-8').rstrip()
        blocks = ['\n'.join('  ' + l for l in json.dumps(r, ensure_ascii=False, indent=2).splitlines())
                  for r in added]
        new_text = text[:-1].rstrip() + ',\n' + ',\n'.join(blocks) + '\n]\n'
        json.loads(new_text)
        CATALOGUE.write_text(new_text, encoding='utf-8')
    print(f'{kind}: added {len(added)}, skipped {len(skipped)} {skipped}')


if __name__ == '__main__':
    main()
