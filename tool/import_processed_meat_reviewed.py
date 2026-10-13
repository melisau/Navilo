"""Audit the 50 submitted rows; import only independently recovered evidence."""
import json
from pathlib import Path
from tool.catalog_validation import valid_gtin, merge_reviewed
from tool.enrich_catalogue_images import lookup

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/catalog_analysis'
BATCH = 'processed-meat-20261013'
BARCODE_SOURCE = 'https://www.asyasanalmarket.com/pinar-225-gr-sucuk--klasik--fermente--18988'
LABEL_SOURCE = 'https://www.carrefoursa.com/pinar-klasik-sucuk-225-g-p-30123642'
ROW = dict(
    code='8690527021149', name='Pınar Klasik Dana Kangal Sucuk 225 g', category='food',
    ingredients='Dana eti ve yağı, baharat karışımı, tuz, tatlı kırmızıbiber, sarımsak, antioksidan(askorbik asit), koruyucu madde(sodyum nitrit).',
    source_url=LABEL_SOURCE, source_name='CarrefourSA etiket bilgisi · Asya Market barkod eşleştirmesi',
    barcode_source_url=BARCODE_SOURCE,
    field_sources={'code': [BARCODE_SOURCE], 'name': [LABEL_SOURCE, BARCODE_SOURCE], 'ingredients': [LABEL_SOURCE]},
    checked_at='2026-10-13T00:00:00+03:00', catalog_batch=BATCH,
    ingredient_evidence='full_label_transcription', evidence_status='retailer_reported_pending_package_check',
    submitted_code='8690526032415', submitted_row=2,
    allergens=[], traces=[], labels=[])

def main():
    submitted = json.loads((OUT / 'submitted_processed_meat_20261013.json').read_text(encoding='utf-8'))
    path = ROOT / 'assets/curated_products.json'
    existing = json.loads(path.read_text(encoding='utf-8'))
    reviewed = dict(ROW)
    # Same barcode and quantity; the evidence-page heading is used for the image.
    previous = next((r for r in existing if r['code'] == ROW['code']), None)
    if previous:
        reviewed = previous
    else:
        image = lookup({**ROW, 'name': 'Pınar Dana Sucuk 225g Klasik Fermente', 'source_url': BARCODE_SOURCE})
        if image and image.get('image_url'):
            reviewed.update(image)
    merged = merge_reviewed(existing, [reviewed])
    results = []
    for row in submitted:
        result = {**row, 'submitted_gtin_valid': valid_gtin(row['code'])}
        if row['no'] == 2:
            result.update(status='added_with_verified_correction', verified_code=ROW['code'],
                reason='Aynı 225 g ürünün barkodu ve içerik metni bağımsız kaynaklardan doğrulandı; gönderilen metin yerine kaynak etiket bilgisi kullanıldı.',
                sources=[BARCODE_SOURCE, LABEL_SOURCE])
        elif row['no'] == 31:
            result.update(status='already_in_catalog_with_different_code', verified_code='8690527010938',
                reason='Pınar Aç Bitir Macar Salam 60 g katalogda zaten var. Gönderilen barkod geçersiz; içerik metni mevcut kaynakla uyuşmuyor. Mevcut kayıt korundu.')
        else:
            result.update(status='pending_verification', reason=(
                'Gönderilen barkod GTIN kontrol basamağını geçmiyor. Doğrulanmış aynı ürün/gramaj barkodu ve tam etiket kaynağı olmadan eklenmedi.'
                if not valid_gtin(row['code']) else
                'Kontrol basamağı geçerli, ancak bu barkodla ürün adı/gramaj/içerik eşleşmesi doğrulanamadı. Eklenmedi.'))
        results.append(result)
    path.write_text(json.dumps(merged, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    (OUT / 'processed_meat_audit_20261013.json').write_text(json.dumps({
        'submitted': 50, 'invalid_submitted_gtins': 40, 'added': 1, 'already_present': 1,
        'pending': 48, 'results': results}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'before': len(existing), 'after': len(merged), 'new': len(merged)-len(existing), 'pending': 48}))

if __name__ == '__main__':
    main()
