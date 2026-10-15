"""Explicitly reviewed protein variants; never expand a formula to other flavours."""
import json,re
from datetime import datetime,timezone
from pathlib import Path
from bs4 import BeautifulSoup
from tool.catalog_validation import validate_reviewed_record

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/protein_expansion_20261015'
NOW=datetime.now(timezone.utc).isoformat()
ROWS=[]

def add(family,code,name,ingredients,url,kind='manufacturer',barcode=None,allergens=None,traces=None,note=''):
 barcode=barcode or url
 row=dict(code=code,name=name,category='food',ingredients=ingredients.strip(),
  source_type=kind,source_url=url,barcode_source_url=barcode,
  source_name='Üretici / perakendeci tam içerik ve çeşit eşleştirmesi',
  verified_at=NOW,checked_at=NOW,status='verified',catalog_batch='protein-expansion-20261015',
  ingredient_evidence='full_label_transcription',evidence_status='source_reviewed_pending_physical_package_check',
  field_sources={'code':[barcode],'name':list(dict.fromkeys([url,barcode])),'ingredients':[url]},
  allergens=allergens or [],traces=traces or [],labels=[],fodmap_servings=[],
  requested_family=family,evidence_note='Aroma ve paket kimliği kaynakla eşleştirildi. Fiziksel ambalaj incelenmedi; tüketim/doz veya düşük laktoz iddiası üretilmedi. '+note)
 validate_reviewed_record(row)
 ROWS.append(row)

def soup(i):return BeautifulSoup((OUT/f'source_{i}.html').read_text(encoding='utf-8'),'html.parser')
sources=json.loads((OUT/'source_results.json').read_text(encoding='utf-8'))
# Manufacturer JSON-LD GTIN is bound to the current product, not related products.
for i,family in [(0,'BigJoy Iso Pro'),(1,'BigJoy Iso Clear'),(2,'BigJoy Big Whey Classic'),(4,'BigJoy Beef & Whey')]:
 s=soup(i);t=s.get_text(' ',strip=True)
 product=next(json.loads(x.get_text()) for x in s.select('script[type="application/ld+json"]') if json.loads(x.get_text()).get('@type')=='Product')
 if i==4:
  ingredients=t.split('Peynir Altı Suyu Protein Karışımı',1)[1].split('Alerjen Uyarısı:',1)[0]
  ingredients='Peynir Altı Suyu Protein Karışımı'+ingredients
 else:
  ingredients=re.split(r'Bileşenler:|İçindekiler',t,flags=re.I)[1].split('Alerjen Uyarısı',1)[0]
 add(family,product['gtin'],s.h1.get_text(' ',strip=True),ingredients,sources[i]['url'],allergens=['milk'],traces=['eggs','soybeans','celery','gluten','mustard'])

s=BeautifulSoup((OUT/'source_go.html').read_text(encoding='utf-8'),'html.parser');t=s.get_text(' ',strip=True)
product=next(json.loads(x.get_text()) for x in s.select('script[type="application/ld+json"]') if json.loads(x.get_text()).get('@type')=='Product')
add('BigJoy Big Whey GO',product['gtin'],'BigJoy BIGWHEYGO Çikolata 15 × 34 g',t.split('Bileşenler:',1)[1].split('Alerjen Maddeler',1)[0],
 'https://gsplus.bigjoy.com.tr/bigwhey-go-15-cikolata',allergens=['milk'],traces=['eggs','celery','soybeans','gluten','mustard'],note='Bu GTIN 15 saşelik kutuya aittir; tek saşeye veya 68 karışık aroma kutusuna atanmadı.')

for i,family,title,code in [(5,'ProteinOcean Whey Protein','ProteinOcean Whey Protein Çikolata 1600 g','8682696551039'),(6,'ProteinOcean Isolate Protein','ProteinOcean Whey Isolate Çikolata 1600 g','8682696881037'),(7,'ProteinOcean Vegan Protein','ProteinOcean Pea Protein Çikolata 400 g','8682696240032')]:
 j=json.loads((OUT/f'product_{i}.json').read_text(encoding='utf-8'))
 assert any(code in (v.get('barcodeList') or []) for v in j['variants'])
 attr=next(a for a in j['attributes'] if 'İÇİNDEKİLER' in a['productAttribute']['name'])
 pars=BeautifulSoup(attr['value'],'html.parser').find_all('p')
 ingredients=next(p.get_text(' ',strip=True).split(':',1)[1] for p in pars if p.get_text(' ',strip=True).startswith('Çikolata Aromalı:'))
 add(family,code,title,ingredients,sources[i]['url'],allergens=['milk'] if i<7 else [],
  note='Üreticideki güncel ürün adı PEA PROTEIN ve protein kaynağı bezelyedir; talepteki pirinç karışımı teyit edilmedi.' if i==7 else '')

for i,family,name,code,start,end in [
 (8,'Saf Nutrition Bezelye Proteini','Saf Nutrition Bezelye Proteini Tozu 100 g','8682368978119','İçindekiler','Menşe ülke:'),
 (9,'Saf Nutrition Mix Vegan Protein','Saf Nutrition Sports Protein Mix 360 g','8682368978218','İçindekiler','Tüm protein mix')]:
 t=soup(i).get_text(' ',strip=True)
 add(family,code,name,t.split(start,1)[1].split(end,1)[0],sources[i]['url'],note='Bezelye ürünü üretici tarafından organik olarak adlandırılmadığından adına Organik eklenmedi.' if i==8 else '')

products=json.loads((OUT/'ozel_products.json').read_text(encoding='utf-8'))
for handle,family in [('hardline-whey-3-matrix-cikolatali-454g','Hardline Whey 3Matrix'),('hardline-hipro-isowhey-cikolata-908g','Hardline Hipro Iso Whey'),('hardline-vmax-bitkisel-protein-2000-g','Hardline Vmax')]:
 p=next(p for p in products if p['handle']==handle)
 ps=BeautifulSoup(p['body_html'],'html.parser').find_all('p')
 ingredient=next(x.get_text(' ',strip=True) for x in ps if re.match('İçindekiler',x.get_text(' ',strip=True),re.I))
 add(family,p['variants'][0]['sku'],p['title'],ingredient.split(':',1)[1],
  'https://www.ozelbeslenme.com/products/'+handle,'retailer',allergens=['milk','soybeans'] if family!='Hardline Vmax' else [])

p=next(p for p in products if p['handle']=='hardline-progainer-cikolata-3000g')
add('Hardline Progainer',p['variants'][0]['sku'],'Hardline Progainer Çikolata 3000 g',
 'Karbonhidratlar (Maltodekstrin, Dekstroz), Proteinler (Ultrafiltre edilmiş whey proteini, Bitkisel protein), Vitamin ve mineral karışımı (Kalsiyum, Fosfor, Vitamin C, Niasin, Çinko, Vitamin B6, Riboflavin, Tiamin, Folik asit, Vitamin B12), Yağı azaltılmış kakao tozu, Kreatin monohidrat (%1,25), Aroma verici: Çikolata, L-Glutamin, Taurin (%0,5).',
 'https://www.hardlinenutrition.com/image/Hardline-Katalog.pdf','manufacturer',
 'https://www.ozelbeslenme.com/products/hardline-progainer-cikolata-3000g',allergens=['milk','soybeans','gluten'],note='Üretici kataloğu sayfa 52; çikolata formülü. Satıcıdaki genel özet içerik yerine üretici tam listesi kullanıldı.')

t=soup(11).get_text(' ',strip=True)
add('Dymatize Elite 100% Whey','4029679676602','Dymatize Elite 100% Whey Rich Chocolate 2170 g',
 t.split('İçindekiler (etiketten):',1)[1].split('Yumurta ve soya içerebilir.',1)[0],sources[11]['url'],'retailer',allergens=['milk'],traces=['eggs','soybeans'])
t=soup(12).get_text(' ',strip=True)
add('Olimp Whey Protein Complex 100%','5901330084485','Olimp Whey Protein Complex 100% Double Çikolata 700 g',
 t.split('İçindekiler — Double Çikolata:',1)[1].split('Alerjen —',1)[0],sources[12]['url'],'retailer',allergens=['milk','soybeans'],traces=['eggs','nuts','peanuts','fish','crustaceans','gluten'])

add('Naturiga Organik Pirinç Proteini','8681851001105','Naturiga Organik Pirinç Proteini Tozu 250 g','Organik Pirinç Proteini Tozu (%100).',
 'https://www.veganbakkal.com.tr/naturiga-organik-pirinc-proteini-tozu-250gr-2252','retailer')

# Link exact UPC/EAN variants across sources; retain regional/package limitations.
add('Optimum Gold Standard Whey','748927028669','Optimum Nutrition Gold Standard 100% Whey Double Rich Chocolate 2,29 kg',
 'Protein karışımı (whey protein izolatı, whey protein konsantresi, hidrolize whey proteini), kakao tozu (alkali ile işlenmiş), ayçiçek ve/veya soya lesitini, doğal ve yapay aroma verici, asesülfam potasyum.',
 'https://www.vitacost.com/products/optimum-nutrition-gold-standard-100-whey-protein-double-rich-chocolate-5-05-lb-2-29-kg-27509','retailer',
 'https://www.trendyol.com/en/optimum-nutrition/optimum-gold-standard-whey-protein-powder-2273-gr-chocolate-flavored-p-25567009',allergens=['milk','soybeans'],
 note='Aynı UPC Türkiye listesinde 2273 g, içerik kaynağında 5.05 lb / 2.29 kg olarak geçiyor. Gramaj farkı korunur; tüm seriye genişletilmez. İngilizce tam içerik Türkçeye çevrildi.')
add('Optimum Platinum Hydrowhey','5060245601481','Optimum Nutrition Platinum Hydrowhey Çikolata 1600 g',
 'Hidrolize whey protein izolatı (süt) (%86) (emülgatör: soya lesitini), dallı zincirli amino asitler (%5) (L-lösin, L-izolösin, L-valin, emülgatör: ayçiçek lesitini), kıvam artırıcı (karragenan), aroma vericiler, yağı azaltılmış kakao tozu, tatlandırıcılar (sukraloz, asesülfam K), sodyum klorür, aroma artırıcı (potasyum klorür), ayçiçek yağı tozu (süt).',
 'https://www.kaufland.fr/product/369332987/','retailer','https://www.3ka.com.tr/optimum-platinum-hydrowhey-chocolate-1600gr',allergens=['milk','soybeans'],note='Aynı EAN, aroma ve gramaj eşleştirildi. Fransızca çikolata tam listesi Türkçeye çevrildi; sayfadaki diğer aromalar aktarılmadı.')

add('Optimum Serious Mass','5060245600552','Optimum Nutrition Serious Mass Muz 2727 g',
 'Maltodekstrin, whey protein konsantresi (süt), kalsiyum kazeinat (süt), aroma vericiler, kreatin monohidrat, süt mineral kompleksi, orta zincirli trigliseritler (süt), yumurta albümini, dipotasyum fosfat, sodyum klorür, renklendirici (kurkumin), vitamin ve mineral karışımı (sodyum L-askorbat, demir pirofosfat, D-alfa-tokoferil asetat, nikotinamid, çinko oksit, retinol asetat, kalsiyum D-pantotenat, sodyum florür, manganez sülfat, potasyum iyodür, siyanokobalamin, D-biyotin, krom (III) klorür, pteroilmonoglutamik asit, kolekalsiferol, sodyum selenit, bakır sitrat, piridoksin hidroklorür, tiamin hidroklorür, filokinon, riboflavin, sodyum molibdat), glutamin peptitleri (buğday gluteni), L-glutamin, magnezyum oksit, peynir altı suyu tozu (süt), inositol, L-askorbik asit, tatlandırıcı (sukraloz), antioksidan (tokoferolce zengin ekstrakt), kalsiyum D-pantotenat, pteroilmonoglutamik asit.',
 'https://www.decathlon.fr/p/mp/hard-gainer-serious-mass-banane/cdfdf79b-bac0-4b0d-a4e0-b4ee5fd91543/g8','retailer',
 'https://www.3ka.com.tr/optimum-serious-mass-banana-2727gr',allergens=['milk','eggs','gluten'],traces=['soybeans','nuts','peanuts'],note='Aynı EAN ve muz aroması; Fransızca tam etiket Türkçeye çevrildi. Yabancı satıcının son çapraz bulaşma cümlesi bozuk olduğundan içerik listesine karıştırılmadı.')
add('Dymatize ISO-100 Hydrolyzed','4029679682511','Dymatize ISO100 Hydrolyzed Clear Wild Berry Lollipop 512 g',
 'Hidrolize whey protein izolatı (süt) (%46), whey protein izolatı (süt) (%46), doğal aroma vericiler, asit (sitrik asit), renk verme amaçlı gıda (kırmızı pancar suyu tozu), renklendirici (antosiyaninler), kanola yağı, köpüklenmeyi önleyici (silikon dioksit), tatlandırıcılar (asesülfam K, sukraloz).',
 'https://www.eprotein.com.tr/dymatize-iso100-hydrolyzed-clear-512-gr','retailer',allergens=['milk'],note='ISO100 serisinin Clear alt çeşididir; çikolatalı standart ISO100 formülü olarak kullanılmaz.')
OUT.joinpath('reviewed.json').write_text(json.dumps(ROWS,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'reviewed_variants':len(ROWS),'families':len(set(r['requested_family'] for r in ROWS))}))
