"""Collect explicit label fields from selected retailer pages; never auto-import."""
import json
import re
import time
from pathlib import Path
import requests
from bs4 import BeautifulSoup
from tool.catalog_validation import valid_gtin

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/catalog_analysis/expansion_sources'
SLUGS = '''dimes-visne-nektari-1-lt
pinar-fish-finger-240-gr
pinar-bitkisel-bazli-badem-icecegi-1-lt
pinar-ucgen-manti-400-gr
pinar-gurme-burger-450-gr
pinar-ac-bitir-macar-salam-60-gr
pinar-ac-bitir-kokteyl-hindi-sosis-180-gr
pinar-gurme-sucuk-250-gr
pinar-burger-225-gr
pinar-geleneksel-tuzsuz-tereyag-200-gr
pinar-labne-laktozsuz-180-gr
pinar-citir-balik-400-gr
cappy-ananasli-icecek-1-l
sutas-huptrik-cilekli-5x30-gr
icim-kefir-cilek-250-ml
sutas-tatlimmm-tatlim-cikolatali-sutlu-4x65gr
sutas-meyveli-yogurt-cilekli-4x115-gr
sutas-krema-200-gr
sutas-bubble-mix-cilekli-140-gr
icim-sef-peynirli-kremali-yemek-sosu-200-ml
icim-sef-mantarli-kremali-yemek-sosu-200-ml
sutas-kaymaksiz-yogurt-2000-gr
sutas-bubble-mix-orman-meyveli-140gr
icim-suzme-peynir-500-gr
tamek-meyve-suyu-seftali-200-ml
tamek-bezelye-670-gr
tamek-kayisi-nektari-kahverengi-sise-200-ml
tamek-bezelye-830-gr
tamek-domates-salcasi-830-gr
tamek-karisik-meyve-nektar-200-ml
tamek-seftali-nektari-kahverengi-sise-200-ml
tamek-100-karisik-meyve-suyu-1-lt
tat-misir-3-x-210-gr'''.splitlines()


def collect(slug):
    url = 'https://www.sariyermarket.com/' + slug
    cache = OUT / (slug + '.txt')
    try:
        if cache.exists():
            content = cache.read_text(encoding='utf-8')
        else:
            response = requests.get(url, timeout=25, headers={'User-Agent': 'NaviloCatalog/0.2 (product label research)'})
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            header = soup.select_one('h1')
            if header is None:
                raise ValueError('No product heading')
            content = header.get_text(' ', strip=True) + '\n' + soup.get_text(' ', strip=True)
            cache.write_text(content, encoding='utf-8')
        name, text = content.split('\n', 1)
        code = re.search(r'GTIN:\s*([0-9]+)', text).group(1)
        ingredient_match = re.search(r'İçindekiler\s*:?\s*(.*?)\s*Alerjen Uyarısı\s*:?', text, re.S)
        ingredient = ingredient_match.group(1).strip() if ingredient_match else ''
        allergy = re.search(r'Alerjen Uyarısı\s*:?\s*(.*?)\s*Net Miktar', text, re.S)
        quantity = re.search(r'Net Miktar\s*\(gr/ml\)\s*:?\s*(.*?)\s*Saklama Koşulları', text, re.S)
        return dict(code=code, name=name, ingredients=ingredient, source_url=url,
                    allergen_raw=allergy.group(1).strip() if allergy else '',
                    quantity_raw=quantity.group(1).strip() if quantity else '',
                    gtin_valid=valid_gtin(code), source_snapshot=str(cache.relative_to(ROOT)))
    except Exception as error:
        return dict(source_url=url, status='pending', reason=str(error))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows=[]
    stopped=False
    for slug in SLUGS:
        if stopped:
            rows.append(dict(source_url='https://www.sariyermarket.com/'+slug,
                             status='pending', reason='Deferred after provider HTTP 429; do not retry until reset'))
            continue
        cached=(OUT/(slug+'.txt')).exists()
        row=collect(slug)
        rows.append(row)
        stopped='429' in row.get('reason','')
        if not cached and not stopped:
            time.sleep(3)
    path = ROOT / 'docs/catalog_analysis/research_food_expansion_raw.json'
    path.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(rows, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
