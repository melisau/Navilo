"""Reviewed source transcriptions for the user's new eight-record submission.

The original 150 raw records and previously excluded Pinar remain quarantined.
"""
import json
import re
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlparse, urljoin
import requests
from bs4 import BeautifulSoup
from tool.catalog_validation import validate_reviewed_record, excluded_codes

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/catalog_analysis/verified_meat_20261013'
DANET = 'https://online.danet.com.tr/'
SOSIS = 'Dana eti, dana yağı, patates nişastası, su, tuz, baharat karışımı, soya proteini, süt proteini, kıvam arttırıcı (guar gam), aroma vericiler, sarımsak, koruyucu (sodyum laktat, sodyum nitrit), stabilizör (sodyum polifosfat), antioksidan (askorbik asit), tütsü aroma vericisi.'
SPECS = [
 ('8697403891537','Danet Dana Dilimli Isıl İşlem Görmüş Sucuk 250 g',
  'Dana eti, dana yağı, baharat karışımı, tuz, sarımsak, stabilizör (sodyum polifosfat), antioksidan (askorbik asit), koruyucu (sodyum nitrit).',
  DANET+'isil-islem-gormus-dana-sucuk',DANET+'isil-islem-gormus-dana-sucuk','manufacturer',[],[]),
 ('8697403890462','Danet Dana Kokteyl Sosis 250 g',SOSIS,
  DANET+'kokteyl-sosis-250gr',DANET+'kokteyl-sosis-250gr','manufacturer',['soybeans','milk'],[]),
 ('8697403890400','Danet Dana Uzun Sosis 250 g',SOSIS,
  DANET+'uzun-sosis-250gr',DANET+'uzun-sosis-250gr','manufacturer',['soybeans','milk'],[]),
 ('8697403891841','Danet Dana Macar Salam Dilimli 50 g',
  'Dana eti, dana yağı, su, ayçiçek yağı, baharat karışımı, patates nişastası, tuz, soya proteini, süt proteini, kıvam arttırıcı (karragenan), sarımsak, stabilizör (sodyum polifosfat), antioksidan (askorbik asit), koruyucu (sodyum nitrit), tütsü aroma vericisi.',
  DANET+'tadimlik-dilimli-macar-salam-50g',DANET+'tadimlik-dilimli-macar-salam-50g','manufacturer',['soybeans','milk'],[]),
 ('8693407001057','Polonez Dana Kangal Isıl İşlem Görmüş Sucuk 200 g',
  'Dana eti ve yağı, tuz, baharat karışımı, sarımsak, stabilizör (sodyum polifosfat), antioksidan (askorbik asit), koruyucu madde (sodyum nitrit).',
  'https://www.migros.com.tr/polonez-isil-islem-gormus-kangal-sucuk-2x200-g-p-d8d06e',
  'https://polonez.com.tr/urun-detay/perakende-urunler/sucuk/dana-kangal-isil-islem-gormus-sucuk-200-gr','retailer',[],[]),
 ('8690451706426','Banvit Piliç Kokteyl Sosis 1000 g',
  'Piliç eti ve yağı, mekanik ayrılmış piliç eti, su, nişasta, bitkisel lif (selüloz), baharat karışımı, tuz, soya proteini, dekstroz, koruyucu (sodyum laktat, sodyum asetat, sodyum nitrit), stabilizör (sodyum polifosfat), antioksidan (sodyum eritorbat), kıvam arttırıcı (karragenan, ksantan gam, konjak gam), maya özü, tütsü aroma vericisi, baharat ekstrakları, renklendirici (paprika, hibiskus, siyah havuç ve pancar kökü özütü)',
  'https://www.banvit.com/urunlerimiz/banvit-pilic-kokteyl-sosis-1000-g',
  'https://www.eonbir.com.tr/banvit-kokteyl-sosis-1000-gr-6962','manufacturer',['soybeans'],['gluten','celery','milk','eggs']),
 ('8697471727219','Namet Gurme Dana Kangal Sucuk 240 g',
  'Dana eti ve yağı, baharat karışımı, tuz, sarımsak, stabilizör (E450, E452), antioksidan (E316), koruyucu madde (E250).',
  'https://www.macrocenter.com.tr/namet-kangal-sucuk-240-g-p-d8d15c',
  'https://gurmar.com.tr/namet-gurme-dana-sucuk-240-gr-17632-p','retailer',[],[]),
]

def source_snapshot(url, label):
    try:
        response = requests.get(url, timeout=20)
        response.raise_for_status()
        soup = BeautifulSoup(response.content.decode('utf-8'), 'html.parser')
        (OUT / (label+'.txt')).write_text(soup.get_text(' ',strip=True), encoding='utf-8')
        return soup, response.url
    except requests.RequestException:
        # Sources were independently reviewed with the web tool in this session;
        # a failed direct fetch is recorded, never treated as new evidence.
        return None, url

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    now = datetime.now(timezone.utc).isoformat()
    rows = []
    for code,name,ingredients,label,barcode,kind,allergens,traces in SPECS:
        if code in excluded_codes():
            continue  # Later source conflict must never be republished by this old batch.
        row = dict(code=code,name=name,category='food',ingredients=ingredients,
            source_type=kind,source_url=label,barcode_source_url=barcode,
            source_name=('Üretici etiket bilgisi' if kind=='manufacturer' else 'Perakendeci etiket bilgisi')+' · kaynak eşleştirmesi',
            verified_at=now,checked_at=now,status='verified',
            catalog_batch='source-verified-meat-20261013',
            ingredient_evidence='full_label_transcription',evidence_status='source_reviewed_pending_physical_package_check',
            field_sources={'code':[barcode],'name':list(dict.fromkeys([label,barcode])),'ingredients':[label]},
            allergens=allergens,traces=traces,labels=[],fodmap_servings=[])
        if code=='8693407001057':
            row['field_sources']['ingredients'].append('https://www.migros.com.tr/polonez-fermente-kangal-sucuk-200-g-p-d8ad79')
            row['evidence_note']='Üretici 200 g barkodu; Migros 2×200 g tam etiket içeriği, aynı bileşenleri veren 200 g sayfasıyla karşılaştırıldı. Çoklu paketin barkodu kullanılmadı.'
        if code=='8697403890400':
            row['evidence_note']='Güncel üretici sayfası başlık ve gramaj bölümünde 250 g veriyor. Tam içerik bu ürünün kendi sayfasından doğrulandı; diğer sosisin metnine atıfla kaydedilmedi.'
        if code=='8690451706426':
            row['allergen_note']='Soya proteini içerir. Eser miktarda gluten, kereviz, süt, yumurta içerebilir.'
        soup,actual = source_snapshot(barcode, code+'-identity')
        if label != barcode:
            source_snapshot(label, code+'-label')
        # A front image may be attached only from an exact-barcode product page.
        if soup and re.search(r'Barkod\s*:\s*'+code+r'(?!\d)', soup.get_text(' ',strip=True)):
            image = soup.find('meta',property='og:image')
            if image and image.get('content'):
                image_url = urljoin(actual,image['content'])
                try:
                    with requests.get(image_url,stream=True,timeout=15) as check:
                        if urlparse(image_url).scheme=='https' and check.status_code==200 and check.headers.get('Content-Type','').startswith('image/'):
                            row.update(image_url=image_url,image_source_url=actual,image_evidence='catalogue_product_page',
                                image_match_method='barcode',image_matched_code=code,image_checked_at=now,
                                image_attribution=urlparse(actual).hostname)
                except requests.RequestException:
                    pass
        validate_reviewed_record(row)
        rows.append(row)
    destination = OUT / 'reviewed.json'
    destination.write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    pinar = dict(code='8690527021149',name='Pınar Klasik Kangal Sucuk 225 g',
        category='food',status='unverified',verified_at=None,source_type='retailer',
        source_url='https://www.macrocenter.com.tr/pinar-klasik-kangal-sucuk-225-g-p-d8d144',
        source_reviewed_at=now,exclusion_reason='Earlier explicit user exclusion remains in effect; new evidence alone does not revoke it.')
    (OUT / 'pinar_exclusion_retained.json').write_text(json.dumps(pinar,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'reviewed':len(rows),'images':sum(bool(r.get('image_url')) for r in rows),'pinar_excluded':True}))

if __name__=='__main__':
    main()
