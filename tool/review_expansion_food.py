"""Manually reviewed retailer label transcriptions from the source research session."""
import json
from pathlib import Path
from tool.catalog_validation import validate_reviewed_record

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/catalog_analysis'

# Exact name, GTIN and full ingredient field on each listed product page were
# reviewed together. This is not a formula generator or a barcode correction.
REVIEWED = [
('8690527110317', 'Pınar Üçgen Mantı 400 g', 'pinar-ucgen-manti-400-gr',
 'Buğday unu, su, irmik, dana kıyma (%12), soğan, pastörize yumurta, tuz, kimyon, ayçiçek yağı, kekik, kırmızı biber, karabiber', ['gluten','eggs'], []),
('8690527102039', 'Pınar Gurme Burger 450 g', 'pinar-gurme-burger-450-gr',
 'Dana eti, dana yağı, peynir, soğan, ekmek, pastörize yumurta, maydanoz, baharat karışımı, tuz, sarımsak', ['gluten','eggs','milk'], []),
('8690527010938', 'Pınar Aç Bitir Macar Salam 60 g', 'pinar-ac-bitir-macar-salam-60-gr',
 'Dana eti ve yağı, ayçiçek yağı, su, patates nişastası, soya proteini, süt proteini, tuz, baharat karışımı, sarımsak, koruyucu madde (sodyum laktat, sodyum nitrit), stabilazör (sodyum polifosfat), antioksidan (askorbik asit), aroma vericiler, doğal tütsü aroması.', ['soybeans','milk'], []),
('8690527030653', 'Pınar Aç Bitir Kokteyl Hindi Sosis 180 g', 'pinar-ac-bitir-kokteyl-hindi-sosis-180-gr',
 'Hindi eti, ayçiçek yağı, dana yağı, su, patates nişastası, soya proteini, süt proteini, buğday lifi, baharat karışımı, tuz, sarımsak, kıvam arttırıcı (guar gam), koruyucu madde (sodyum laktat, sodyum nitrit), stabilazör (sodyum polifosfat), antioksidan (askorbik asit), aroma vericiler.', ['soybeans','milk','gluten'], []),
('8690527020920', 'Pınar Gurme Sucuk 250 g', 'pinar-gurme-sucuk-250-gr',
 'Dana eti ve yağı, baharat karışımı, tuz, tatlı kırmızı biber, sarımsak, koruyucu madde (sodyum nitrit), antioksidan (askorbik asit), aroma vericiler. Yağ oranı en çok %40.', [], []),
('8690527100011', 'Pınar Burger 225 g', 'pinar-burger-225-gr',
 'Dana eti ve yağı, soğan, bulgur, ekmek, baharat karışımı, tuz', ['gluten'], []),
('5449000103697', 'Cappy Ananaslı İçecek 1 L', 'cappy-ananasli-icecek-1-l',
 'Su, şeker veya fruktoz-glukoz şurubu (F)*, ananas suyu konsantresi, asitliği düzenleyici (sitrik asit), kıvam arttırıcı (pektin), aroma vericiler, antioksidan (askorbik asit), renklendici (beta karoten). *Kullanılan şeker veya fruktoz-glukoz şurubu paket üzerine kodlanmıştır.', [], []),
('86926973', 'Sütaş Hüptrik Çilekli 5x30 g', 'sutas-huptrik-cilekli-5x30-gr',
 'Homojenize ve pastörize inek sütü, sofra şekeri, patates nişastası, çilek preperatı %1 (renklendirici (kırmızı pancar suyu konsantresi), çilek aroma vericisi, çilek suyu konsantresi, kıvam arttırıcılar (guar gum, pektin), limon suyu konsantresi), doğal şeker aroma vericisi, yoğurt kültürü.', ['milk'], []),
('8692971429588', 'İçim Kefir Çilek 250 ml', 'icim-kefir-cilek-250-ml',
 'Pastörize inek sütü, çilek sosu (%11) [şeker, çilek (%10), nişasta, kıvam verici (karragenan), limon suyu konsantresi, aroma verici], kefir mayası, kefir kültürü, probiyotik', ['milk'], []),
('8690767710223', 'Sütaş Tatlımmm Çikolatalı Sütlü Tatlı 4x65 g', 'sutas-tatlimmm-tatlim-cikolatali-sutlu-4x65gr',
 'Homojenize ve pastörize inek sütü, sofra şeker, nişasta, kakao, kıvam arttırıcı (ksantan sakızı), çikolata (%0,1), doğal vanilya aroma vericisi.', ['milk'], []),
('8681324010306', 'Sütaş Bubble Mix Çilekli 140 g', 'sutas-bubble-mix-cilekli-140-gr',
 'Çilek Aromalı Süt Ürünü: Homojenize ve pastörize inek sütü, sofra şekeri, modifiye nişasta, çilek preparatı %1 (renklendirici (kırmızı pancar suyu konsantresi), çilek aroma vericisi, çilek suyu konsantresi, kıvam arttırıcılar (guar gum, pektin), limon suyu konsantresi), yoğurt kültürü. Çilek Aromalı Patlayan Top: İçindekiler: Su, fruktoz-glukoz şurubu, şeker, maltodekstrin, meyve suyu konsantresi (%1), stabilizör (kalsiyum laktat, kalsiyum klorür), tapyoka nişastası, asitlik düzenleyiciler (sitrik asit, malik asit), kıvam artırıcılar (ksantan gam, sodyum aljinat, karboksimetil selüloz), koruyucu (potasyum sorbat), aroma vericiler, bitkisel ekstrakt (hibisküs), tuz', ['milk'], []),
('8692971441641', 'İçim Şef Peynirli Kremalı Yemek Sosu 200 ml', 'icim-sef-peynirli-kremali-yemek-sosu-200-ml',
 'Pastörize inek sütü kreması, peynir tozu (%1,8), modifiye nişasta, kıvam arttırıcılar (karboksimetil selüloz, keçiboynuzu gamı, pektin), aroma vericiler.', ['milk'], []),
('8692971441689', 'İçim Şef Mantarlı Kremalı Yemek Sosu 200 ml', 'icim-sef-mantarli-kremali-yemek-sosu-200-ml',
 'Pastörize inek sütü kreması, mantar tozu (%1), modifiye nişasta, kıvam arttırıcılar (karboksimetil selüloz, keçiboynuzu gamı, pektin), aroma vericiler.', ['milk'], []),
('8690767675195', 'Sütaş Kaymaksız Yoğurt 2000 g', 'sutas-kaymaksiz-yogurt-2000-gr',
 'Pastörize İnek Sütü, Yoğurt Kültürü', ['milk'], []),
('86903332', 'Tamek Şeftali Nektarı 200 ml', 'tamek-meyve-suyu-seftali-200-ml',
 'Su, şeftali püre konsantresi (meyve oranı en az %50), şeker * (sakkaroz veya fruktoz-glukoz şurubu), asitlik düzenleyici (sitrik asit), antioksidan (askorbik asit), tatlandırıcı (sukraloz). Şeker ve Tatlandırıcı İçerir.', [], []),
('8690575061913', 'Tamek Bezelye 670 g', 'tamek-bezelye-670-gr',
 'Bezelye, su, tuz, şeker', [], []),
('8690575061715', 'Tamek Bezelye 830 g', 'tamek-bezelye-830-gr',
 'Bezelye, su, tuz', [], []),
('8690575012519', 'Tamek Domates Salçası 830 g', 'tamek-domates-salcasi-830-gr',
 'Domates.', [], []),
('8690575865214', 'Tamek Karışık Meyve Nektarı 200 ml', 'tamek-karisik-meyve-nektar-200-ml',
 'Su, meyve suyu ve püre konsantreleri (elma, şeftali, portakal) (meyve oranı en az %50), şeker * (sakkaroz veya fruktoz-glukoz şurubu), asitlik düzenleyici (sitrik asit), antioksidan (askorbik asit), tatlandırıcı (sukraloz). Şeker ve Tatlandırıcı İçerir', [], []),
]


def main():
    rows = []
    raw = json.loads((OUT/'research_food_expansion_raw.json').read_text(encoding='utf-8'))
    # Only these directly fetched records passed a manual same-name/quantity review.
    allowed = {'8690558010006': ([],['gluten','milk']),
               '8690527130551': (['fish','gluten'],[]),
               '8690565026441': (['almonds'],[]),
               '8690575878627': ([],[])}
    for row in raw:
        if row.get('code') in allowed:
            allergens, traces = allowed[row['code']]
            rows.append(dict(code=row['code'], name=row['name'], ingredients=row['ingredients'],
                             source_url=row['source_url'], allergens=allergens, traces=traces,
                             source_snapshot=row['source_snapshot']))
    for code, name, slug, ingredients, allergens, traces in REVIEWED:
        rows.append(dict(code=code, name=name, ingredients=ingredients, allergens=allergens,
                         traces=traces, source_url='https://www.sariyermarket.com/'+slug))
    for row in rows:
        url=row['source_url']
        row.update(source_name='Sarıyer Market ürün GTIN ve tam etiket bilgisi', barcode_source_url=url,
                   field_sources={field:[url] for field in ('code','name','ingredients')},
                   labels=[], category='food', catalog_batch='food-expansion-20261013',
                   checked_at='2026-10-13T00:00:00+03:00', ingredient_evidence='full_label_transcription',
                   evidence_status='retailer_reported_pending_package_check')
        validate_reviewed_record(row)
    (OUT/'reviewed_food_expansion_retailer.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('Reviewed', len(rows))


if __name__ == '__main__':
    main()
