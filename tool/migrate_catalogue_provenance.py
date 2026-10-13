"""One-time metadata migration using recorded source review dates, not new dates."""
import json
from pathlib import Path
from urllib.parse import urlparse
from tool.catalog_validation import valid_gtin, valid_source
from tool.submitted_text_normalization import normalize_submitted

ROOT = Path(__file__).resolve().parents[1]

def source_type(row):
    host = urlparse(row.get('source_url', '')).hostname or ''
    evidence = row.get('evidence_status', '')
    if host.endswith(('openfoodfacts.org', 'openbeautyfacts.org', 'openproductsfacts.org')):
        return 'open_food_facts'
    if host in {'www.zuber.com', 'yorsan.com.tr', 'www.icim.com.tr', 'www.sutas.com.tr',
                'www.activia.com', 'www.activiaturkiye.com', 'proteinocean.com', 'www.soke.com.tr',
                'www.flormar.com.tr', 'shop.goldenrose.com.tr', 'www.maruderm.com',
                'thepurestsolutions.com', 'b2c.cosrx.com', 'www.rimmellondon.com'}:
        return 'manufacturer'
    if evidence == 'manufacturer_product_page':
        return 'manufacturer'
    return 'retailer'

def main():
    raw = json.loads((ROOT / 'docs/catalog_analysis/submitted_processed_meat_150_20261013.json').read_text(encoding='utf-8'))
    quarantine = [dict(normalize_submitted(r), category='food', source_type=None, source_url=None,
                       verified_at=None, status='unverified', catalog_batch='processed-meat-20261013',
                       exclusion_reason='user_excluded_unverified_submission') for r in raw]
    removed = []
    summary = {}
    for filename in ['curated_products.json', 'curated_cosmetics.json']:
        path = ROOT / 'assets' / filename
        rows = json.loads(path.read_text(encoding='utf-8'))
        kept = []
        for row in rows:
            if row.get('catalog_batch') == 'processed-meat-20261013':
                removed.append(dict(row, status='unverified', verified_at=None))
                continue
            if 'status' not in row:
                # Preserve a previous source review, never invent today's review.
                usable = valid_gtin(row.get('code')) and valid_source(row.get('source_url')) and bool(row.get('checked_at'))
                row.update(source_type=source_type(row),
                           verified_at=row.get('checked_at') if usable else None,
                           status='verified' if usable else 'unverified',
                           verification_basis='existing_catalogue_source_review' if usable else 'missing_source_review')
            kept.append(row)
        path.write_text(json.dumps(kept, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
        summary[filename] = {'total': len(kept), 'verified': sum(r['status']=='verified' for r in kept)}
    directory = ROOT / 'data/quarantine'
    directory.mkdir(parents=True, exist_ok=True)
    (directory / 'processed_meat_150.json').write_text(json.dumps(quarantine, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    archive = directory / 'withdrawn_processed_meat.json'
    if removed:
        archive.write_text(json.dumps(removed, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    # Old research files remain research; adding provenance never promotes them.
    for path in (ROOT / 'docs/catalog_analysis').glob('reviewed*.json'):
        rows = json.loads(path.read_text(encoding='utf-8'))
        if not isinstance(rows, list):
            continue
        for row in rows:
            if not isinstance(row, dict) or 'status' in row:
                continue
            usable = valid_gtin(row.get('code')) and valid_source(row.get('source_url')) and bool(row.get('checked_at'))
            row.update(source_type=source_type(row), status='verified' if usable else 'unverified',
                       verified_at=row.get('checked_at') if usable else None)
        path.write_text(json.dumps(rows, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'catalogues': summary, 'quarantined': len(quarantine), 'withdrawn': len(removed)}))

if __name__ == '__main__':
    main()
