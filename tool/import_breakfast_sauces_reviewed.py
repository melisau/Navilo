import json
from pathlib import Path
try:
    from .collect_harras import valid
except ImportError:
    from collect_harras import valid

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/breakfast_sauces'

def main():
    rows=[
        dict(code='8699118055419',name='Çokça Acılı Kahvaltılık Sos 300 g',
             ingredients='Biber salçası, domates salçası, su, çemen unu, sarımsak, sıvı yağ, ceviz içi, baharatlar, koruyucular.',
             source_name='A101 ürün etiketi · barkod: Open Food Facts',
             source_url='https://www.a101.com.tr/kapida/sut-urunleri-kahvaltilik/cokca-acili-kahvaltilik-sos-300-g_p-16001716',
             barcode_source_url='https://world.openfoodfacts.org/product/8699118055419',
             allergens=['en:nuts'],traces=[],labels=[]),
        dict(code='8690635260393',name='Tat Kahvaltılık Sos 300 g',
             ingredients='Biber salçası, domates salçası, közlenmiş kapya biber, su, yer fıstığı(%5), ceviz(%1), ayçiçek yağı, şeker, tuz, baharat karışımı, sarımsak, modifiye mısır nişastası, antioksidan(askorbik asit), aroma vericiler.',
             source_name='CarrefourSA ürün etiketi · barkod: Hapeloğlu',
             source_url='https://www.carrefoursa.com/tat-kahvaltilik-sos-300-g-p-30383914',
             barcode_source_url='https://www.hapeloglu.com/tat-kahvalt%C4%B1l%C4%B1k-sos-300-gr-19659',
             corroborating_ingredient_source_url='https://toptan.migros.com.tr/tat-kahvaltilik-sos-300-g-p-09062250',
             allergens=['en:peanuts','en:nuts'],traces=[],labels=[]),
        dict(code='8690508004246',name='Tukaş Kahvaltılık Sos 300 g',
             ingredients='Biber salçası, Domates salçası, su, ayçiçek yağı, tuz, sarımsak, ceviz, çeşitli baharat, şeker, asitlik düzenleyici, antioksidan, koruyucu madde(potasyum sorbat, sodyum benzoat), acı biber ekstratı.',
             source_name='Migros ürün etiketi · barkod: Market Karşılaştır',
             source_url='https://www.migros.com.tr/tukas-kahvaltilik-sos-300-g-p-8a4704',
             barcode_source_url='https://marketkarsilastir.com/fiyat/8690508004246-tukas-kahvaltilik-sos-300-g',
             allergens=['en:nuts'],traces=[],labels=[]),
    ]
    p=json.loads((OUT/'sources/8690103131347.json').read_text(encoding='utf-8'))['product']
    assert p['code']=='8690103131347' and 'Marmarabirlik' in p['brands'] and '340' in p['product_name_tr']
    inci=p.get('ingredients_text_tr') or p.get('ingredients_text')
    assert inci
    rows.append(dict(code='8690103131347',name='Marmarabirlik Sade Zeytin Ezmesi 340 g',
        ingredients=inci,source_name='Open Food Facts · Marmarabirlik (ODbL)',
        source_url='https://world.openfoodfacts.org/product/8690103131347',
        allergens=p.get('allergens_tags') or [],traces=p.get('traces_tags') or [],labels=[],
        attribution='© Open Food Facts contributors',license='ODbL-1.0',
        license_url='https://opendatacommons.org/licenses/odbl/1-0/',
        evidence_status='community_transcription_pending_package_check'))
    for r in rows:
        assert valid(r['code']) and r['ingredients']
        r.update(category='food',catalog_batch='breakfast-sauces-20261013',checked_at='2026-10-13T00:00:00+03:00')
        r.setdefault('evidence_status','retailer_reported_pending_package_check')
    path=ROOT/'assets/curated_products.json'
    old=json.loads(path.read_text(encoding='utf-8'))
    preserved=[r for r in old if r.get('catalog_batch')!='breakfast-sauces-20261013']
    assert not({r['code'] for r in preserved}&{r['code'] for r in rows}), 'Existing barcode conflict'
    path.write_text(json.dumps(preserved+rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'reviewed_records.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    audit=json.loads((OUT/'audit.json').read_text(encoding='utf-8'))
    related={126:'8690635260393',129:'8690508004246',175:'8690103131347'}
    for r in audit:
        if r['index']==101:
            r['status']='imported_with_retailer_ingredient_correction'
            r['review_note']='A101 tam içerik alanı kullanıldı; gönderide eksik olan ceviz ve çemen unu korundu. Koruyucu türü üretici bilgisi olmadan tahmin edilmedi.'
        if r['index'] in related:
            r['related_verified_code']=related[r['index']]
            r['review_note']='Gönderilen barkod ithal edilmedi; aynı ürün grubundan kaynaklı barkod/gramaj ayrı kaydedildi. Takma barkod yok.'
    (OUT/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    conflicts=[
        dict(brand='Tamek',codes=['8690575171513','8690575171520'],status='conflicting_formulas_not_imported',
             source_urls=['https://www.carrefoursa.com/tamek-findik-ve-cevizli-aci-sos-300-g-p-30221982','https://www.tkkoop.com.tr/urun/tamek-kahvaltilik-sos-300-g','https://www.fiyatarsivi.com/kahvaltilik-sos/tamek-kahvaltilik-aci-sos-300-g%2C2309ea6e-efef-4ed5-b494-c2112ea8df6b'],
             note='Bir içerik sürümünde %4 ceviz/%4 yer fıstığı; başka sürümde %2 ceviz/%8 yer fıstığı. Formül-barkod sürümü teyit edilmedi.'),
        dict(brand='Kühne',codes=['8696027016913'],status='formula_barcode_mapping_unresolved_not_imported',
             source_urls=['https://www.migros.com.tr/kuhne-kahvaltilik-sos-300-g-p-8ae089','https://www.migros.com.tr/kuhne-kahvaltilik-sos-300-g-p-89e018'],
             note='Aynı ad/gramaj altında biri salça, diğeri %72 kapya biber bazlı iki içerik var. Hangi barkod/formüle ait oldukları kesinleştirilmedi.'),
        dict(brand='Sosero',codes=['8680395186828'],status='incomplete_ingredient_evidence_not_imported',
             source_urls=['https://sosero.com/urunler/kahvaltilik-acuka/300-cc-cam-kavanoz'],
             note='Resmi barkod ve 290g mevcut; genel tanıtım metni tam etiket içeriği yerine geçirilmedi. Pazaryerindeki başka kayıtta soya sosu içeriği yanlış eşlenmiş görünüyor.'),
        dict(brand='Burcu',codes=['8691573082801'],status='incomplete_ingredient_evidence_not_imported',
             source_urls=['https://www.burcu.com.tr/urun/burcu-kahvaltilik-sos-aci/'],
             note='Resmi acılı ürün barkodu mevcut; tatlı sosun içerik listesi acılı ürüne kopyalanmadı.'),
    ]
    (OUT/'evidence_conflicts.json').write_text(json.dumps(conflicts,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Imported',len(rows),'food total',len(preserved)+len(rows))

if __name__=='__main__':
    main()
