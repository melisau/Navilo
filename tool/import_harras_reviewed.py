"""Import explicitly reviewed Harras records; preserve unverified submissions in audit."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/harras'
SELECTED={
    '8695077129444':'Harras Bütün Fındıklı Sütlü Çikolata 65 g',
    '8695077129468':'Harras Bütün Fındıklı Sütlü Çikolata 130 g',
    '8695077043641':'Harras Bitter Tablet Çikolata %60 Kakao 80 g',
    '8695077112583':'Harras Laktozsuz Yarım Yağlı UHT İçme Sütü 1 L',
}

def main():
    rows=[]
    for code,name in SELECTED.items():
        source=json.loads((OUT/'sources'/(code+'.json')).read_text(encoding='utf-8'))
        p=source['product']
        assert source['status']==1 and p['code']==code and 'harras' in p['brands'].lower()
        raw=p['ingredients_text_tr']
        assert raw
        ingredients=raw.split(' Alerjen Uyarısı:',1)[0]
        traces=['en:pistachios','en:almonds'] if 'Antep fıstığı ve badem' in raw else p.get('traces_tags') or []
        rows.append(dict(code=code,category='food',name=name,ingredients=ingredients,
            source_name='Open Food Facts · Harras (ODbL)',source_url='https://world.openfoodfacts.org/product/'+code,
            checked_at='2026-10-13T00:00:00+03:00',allergens=p.get('allergens_tags') or [],traces=traces,labels=[],
            catalog_batch='harras-20261013',evidence_status='community_transcription_pending_package_check',
            attribution='© Open Food Facts contributors',license='ODbL-1.0',license_url='https://opendatacommons.org/licenses/odbl/1-0/',
            source_ingredients_raw=raw))
    rows.append(dict(code='8695077141453',category='food',name='Harras Özel Lezzet Kakaolu Fındık Ezmesi 350 g',
        ingredients='Fındık (%35), şeker, fındık yağı, yağsız süt tozu, kakao (%4).',
        source_name='Harras · perakende barkodu ve 2024 ambalaj fotoğrafı',
        source_url='https://gidadedektifi.com/urun-incelemeleri/krema-sos-ve-ezmeler/harras-ozel-lezzet-kakaolu-findik-ezmesi-826',
        barcode_source_url='https://www.trendyol.com/harras/kakaolu-findik-ezmesi-p-958670708',
        ingredient_evidence_url='https://imagedelivery.net/Zcjn5gwAVfrAzXjwv_K0uw/af7f3edc-f2c3-4f64-b045-6d92b5096c00/public',
        checked_at='2026-10-13T00:00:00+03:00',source_published_at='2024-05-20',
        allergens=['en:milk','en:nuts'],traces=[],labels=[],catalog_batch='harras-20261013',
        evidence_status='retailer_identity_and_historical_label_photo_pending_current_package_check'))
    path=ROOT/'assets/curated_products.json'
    existing=json.loads(path.read_text(encoding='utf-8'))
    preserved=[r for r in existing if r.get('catalog_batch')!='harras-20261013']
    assert not ({r['code'] for r in preserved}&{r['code'] for r in rows}), 'Existing barcode conflict'
    path.write_text(json.dumps(preserved+rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    audit=json.loads((OUT/'audit.json').read_text(encoding='utf-8'))
    for row in audit:
        code=row['code']
        if code in SELECTED:
            row['status']='imported_source_reported_pending_package_check'
        elif code=='8695077122285':
            row['status']='identity_conflict_not_imported'
            row['review_note']='OFF kaydının tek fotoğrafı fındık ezmesi yerine sade kefir gösteriyor. Ezme, perakende kaynağında 8695077141453 barkoduyla ayrı kaydedildi; takma barkod oluşturulmadı.'
            row['related_verified_code']='8695077141453'
        elif code=='8695077029423':
            row['status']='conflicting_sources_not_imported'
            row['review_note']='Gönderilen listede en az %3,5 yağ; OFF metninde %3,1 yağ ve çelişkili 835g/1000ml miktar metadata mevcut.'
        elif code=='8695077109484':
            row['status']='incomplete_ingredients_not_imported'
            row['review_note']='Ürün kimliği ve 145 g miktarı kaynakta var; tam içerik metni eksik.'
        elif code=='8684992004226':
            row['review_note']='Şikayet kaydı ürün kimliğini bildirse de tam ambalaj içerik kanıtı değildir; %100 içerik varsayılmadı.'
        elif code=='8695077141033':
            row['status']='different_product_not_imported'
            row['review_note']='Kaynak Aknaz Yarım Yağlı Tost Peyniri bildiriyor; gönderilen Harras mantı eşleşmesi kabul edilmedi.'
        if code=='8695077129468':
            row['review_note']='Kaynakta %85 çikolata/%15 fındık var; gönderilen %82/%18 kullanılmadı. Besin ve saklama metinleri içerikten ayrıldı.'
        if code=='8695077112583':
            row['review_note']='Kaynak metninde ve ambalaj fotoğrafında laktoz enzimi yazıyor. Bu ifade laktaz enzimi olarak sessizce değiştirilmedi.'
    (OUT/'audit.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    (OUT/'reviewed_records.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Imported',len(rows),'food total',len(preserved)+len(rows))

if __name__=='__main__':
    main()
