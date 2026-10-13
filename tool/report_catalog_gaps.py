"""Rebuild evidence-aware submission report; never mutates product catalogues."""
import csv
import json
import re
from collections import Counter
from datetime import datetime, timezone, timedelta
from pathlib import Path
try:
    from .catalog_validation import merge_reviewed
except ImportError:
    from catalog_validation import merge_reviewed

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/catalog_analysis'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def valid(code):
    return code.isdigit() and len(code) in (8, 12, 13, 14) and sum(int(c) * (3 if i % 2 == 0 else 1) for i, c in enumerate(code[-2::-1])) % 10 == (10-int(code[-1])) % 10

def main():
    OUT.mkdir(exist_ok=True)
    food = read(ROOT/'assets/curated_products.json')
    cosmetics = read(ROOT/'assets/curated_cosmetics.json')
    catalogs = {'food': {str(x['code']): x for x in food}, 'cosmetic': {str(x['code']): x for x in cosmetics}}
    corrected = {}
    known_path=OUT/'known_corrections.json'
    for item in read(known_path) if known_path.exists() else []:
        if item['verified_code'] in catalogs[item['category']]:
            corrected[(item['category'],item['submitted_code'])]=item['verified_code']
    repair_items=[]
    repair_files=sorted(OUT.glob('repair_results*.json'))
    for repair_path in repair_files:
        batch=read(repair_path)
        if isinstance(batch,dict): batch=batch.get('records',batch.get('results',[]))
        for item in batch:
            if not item.get('source_url') and item.get('source_urls'):
                source_urls=item['source_urls']
                if isinstance(source_urls,dict):
                    sources=source_urls.get('code') or source_urls.get('ingredients') or source_urls.get('name') or []
                else:
                    sources=source_urls
                item['source_url']=sources[0] if sources else ''
        repair_items.extend(batch)
    # Include only reviewed cosmetic records explicitly marked ready, and only
    # when their verified GTIN matches the product record.
    reviewed_cosmetics=[]
    for reviewed_path in OUT.glob('reviewed_cosmetics_sources_round*.json'):
        reviewed_cosmetics.extend(read(reviewed_path))
    ready_cosmetic_codes={str(x.get('verified_code')) for x in repair_items
        if x.get('status') in ('ready_identity_verified','ready_identity_corrected') and x.get('verified_code')}
    existing_cosmetic_codes={str(x.get('code')) for x in cosmetics}
    ready_cosmetics=[x for x in reviewed_cosmetics
        if str(x.get('code')) in ready_cosmetic_codes and str(x.get('code')) not in existing_cosmetic_codes]
    if ready_cosmetics:
        cosmetics=merge_reviewed(cosmetics,ready_cosmetics)
        (ROOT/'assets/curated_cosmetics.json').write_text(
            json.dumps(cosmetics,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    repairs={str(x.get('submitted_code')):x for x in repair_items if x.get('submitted_code')}
    for path in (ROOT/'docs').glob('*.md'):
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            if not line.startswith('|'): continue
            codes=re.findall(r'(?<!\d)\d{8,14}(?!\d)',line)
            if len(codes)>1:
                for category, catalog in catalogs.items():
                    for submitted in codes:
                        if submitted not in catalog:
                            actual=next((c for c in codes if c in catalog),'')
                            if actual: corrected[(category,submitted)]=actual
    rows = []
    def add(code, name, source, category='food', historical='', url=''):
        code = str(code)
        current = catalogs[category].get(code)
        related = corrected.get((category,code),'') or next((candidate for candidate in re.findall(r'(?<!\d)\d{8,14}(?!\d)',historical) if candidate != code and candidate in catalogs[category]), '')
        repair=repairs.get(code,{})
        if repair.get('status') in ('added','existing_verified','reviewed_ready','identity_corrected_reviewed_ready','corrected_gtin_reviewed_ready','verified_not_imported') and repair.get('verified_code') in catalogs[category]:
            related=repair['verified_code']
        reason = 'Barkod katalogda mevcut' if current else ('Gönderilen barkod kontrol basamağı geçersiz; doğru ürün barkodu ve tam etiket gerekli' if not valid(code) else 'Barkod geçerli biçimde; ürün kimliği ve tam içerik için bağımsız kaynak gerekli')
        if not current and historical and 'invalid' not in historical:
            reason += '; önceki denetim: ' + historical
        if related:
            reason='Önceki denetimde kaynakla doğrulanan farklı barkod katalogda mevcut; gönderilen barkoda takma eşleşme yapılmadı'
        if repair.get('reason'): reason=repair['reason']
        error_class='none' if current or related else ('invalid_barcode' if not valid(code) else 'unverified_identity_and_ingredients')
        for marker,label in [('identity_conflict','identity_conflict'),('different_product','identity_conflict'),('incomplete_ingredients','incomplete_ingredients'),('conflicting_sources','conflicting_sources'),('not_found','source_not_found')]:
            if not (current or related) and marker in historical: error_class=label
        if not (current or related) and repair.get('status')=='identity_conflict': error_class='identity_conflict'
        actual=current or catalogs[category].get(related,{})
        candidate_code=repair.get('verified_code','') if not (current or related) else ''
        rows.append(dict(barcode=code, name=name, catalog_name=actual.get('name',''), category=category, status='available_by_submitted_barcode' if current else ('available_by_corrected_barcode' if related else 'pending_verification'), related_verified_code=related, unlinked_candidate_code=candidate_code, candidate_in_catalog=candidate_code in catalogs[category], error_class=error_class, reason=reason, source=source, source_url=repair.get('source_url') or url or actual.get('source_url',''), previous_outcome=historical, next_action='Tamamlandı' if current or related else 'Aynı ürün ve gramajın gerçek GTIN kaydını ve eksiksiz etiketini bul; barkodu hesaplayarak değiştirme'))
    for rel, category in [('harras/audit.json','food'), ('breakfast_sauces/audit.json','food'), ('rimmel/audit.json','cosmetic'), ('sunscreens/submitted_audit.json','cosmetic'), ('makeup/eyeliner_audit.json','cosmetic'), ('makeup/submission_audit.json','cosmetic')]:
        path=ROOT/'docs'/rel
        data=read(path)
        if isinstance(data,dict):
            data=data.get('submitted', data.get('records', []))
        for x in data:
            if isinstance(x,dict) and (x.get('code') or x.get('supplied_code')):
                code=x.get('code') or x.get('supplied_code')
                if x.get('sourced_code') in catalogs[category]: corrected[(category,str(code))]=x['sourced_code']
                add(code,x.get('name',x.get('submitted_name','')),str(path.relative_to(ROOT)),category,x.get('status',''),x.get('source_url',''))
    gr=read(ROOT/'docs/goldenrose/audit.json')
    for x in gr.get('submitted',[]):
        if x.get('code'): add(x['code'],x.get('submitted_name',x.get('name','')),'docs/goldenrose/audit.json','cosmetic',x.get('status',''))
    for path in (ROOT/'docs/submitted_catalogues_20261013').glob('*.txt'):
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            cells=line.split('\t')
            if len(cells)>=3 and re.fullmatch(r'\d{8,14}',cells[1].strip()):
                add(cells[1].strip(),cells[2].strip(),str(path.relative_to(ROOT)))
    for filename in ['SUBMITTED_SNACKS_AUDIT_20261013.md','SUBMITTED_DAIRY_STAPLES_AUDIT_20261013.md','SUBMITTED_PRODUCTS_66_100_AUDIT_20261013.md','SUBMITTED_PROTEIN_POWDERS_AUDIT_20261013.md']:
        path=ROOT/'docs'/filename
        for line in path.read_text(encoding='utf-8-sig').splitlines():
            cells=[x.strip() for x in line.split('|')[1:-1]]
            if len(cells)>=4 and re.fullmatch(r'\d{8,14}',cells[1]):
                add(cells[1],cells[0],str(path.relative_to(ROOT)),historical=cells[-1])
    # Keep occurrences: duplicate submissions can disagree about identity.
    pending=[x for x in rows if x['status']=='pending_verification']
    summary=dict(generated_at=datetime.now(timezone(timedelta(hours=3))).isoformat(),food_products=len(food),cosmetic_products=len(cosmetics),submission_occurrences=len(rows),pending_occurrences=len(pending),pending_unique_barcodes=len({x['barcode'] for x in pending}),invalid_pending_occurrences=sum(not valid(x['barcode']) for x in pending),scope='Yalnızca projede saklanan gönderiler; Türkiye pazarının eksiksiz envanteri değildir. Gönderilen barkodun yokluğu ürünün başka barkodla katalogda olmadığı anlamına gelmez.')
    summary['categories']={category:dict(submission_occurrences=sum(x['category']==category for x in rows),pending_occurrences=sum(x['category']==category for x in pending),pending_unique_barcodes=len({x['barcode'] for x in pending if x['category']==category}),error_classes=dict(Counter(x['error_class'] for x in pending if x['category']==category))) for category in catalogs}
    summary['available_occurrences']=len(rows)-len(pending)
    summary['pending_distinct_submitted_names']=len({x['name'].strip().casefold() for x in pending})
    summary['pending_repeated_barcode_occurrences']=len(pending)-len({x['barcode'] for x in pending})
    summary['current_repair_batch']=dict(added=sum(x.get('status')=='added' for x in repair_items),pending=sum(x.get('status')=='pending' for x in repair_items),identity_conflict=sum(x.get('status')=='identity_conflict' for x in repair_items))
    summary['repair_result_files']=[str(path.relative_to(ROOT)) for path in repair_files]
    summary['repair_batch_counts']={str(path.relative_to(ROOT)):dict(Counter(x.get('status','unknown') for x in (read(path).get('records',read(path).get('results',[])) if isinstance(read(path),dict) else read(path)))) for path in repair_files}
    (OUT/'report.json').write_text(json.dumps(dict(summary=summary,records=rows),ensure_ascii=False,indent=2),encoding='utf-8')
    with (OUT/'pending.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(pending)
    with (OUT/'available.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(x for x in rows if x['status']!='pending_verification')
    latest_discoveries={}
    submitted_codes={x['barcode'] for x in rows}
    for item in repair_items:
        if not item.get('submitted_code') or item.get('submitted_code') not in submitted_codes:
            latest_discoveries[item.get('verified_code') or item.get('name')]=item
    discovery_pending=[x for x in latest_discoveries.values() if x.get('status','').startswith('pending') or x.get('status')=='identity_conflict' or (x.get('status')=='reviewed_ready' and x.get('verified_code') not in catalogs['food'] and x.get('verified_code') not in catalogs['cosmetic'])]
    summary['additional_discovery_pending']=len(discovery_pending)
    with (OUT/'discovery_pending.csv').open('w',encoding='utf-8-sig',newline='') as f:
        fields=['submitted_code','verified_code','status','name','reason','source_url']
        writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(discovery_pending)
    with (OUT/'research_outcomes.csv').open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(repair_items)
    (OUT/'report.json').write_text(json.dumps(dict(summary=summary,records=rows,discovery_pending=discovery_pending),ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'current_catalog.json').write_text(json.dumps(dict(food=food,cosmetics=cosmetics),ensure_ascii=False,indent=2),encoding='utf-8')
    lines=['# Ürün kütüphanesi analizi','',f"Güncel katalog: **{len(food)} gıda**, **{len(cosmetics)} kozmetik**.",f"İncelenen gönderi satırı: {len(rows)}. Gönderilen barkodla bulunmayan: {len(pending)} satır / {summary['pending_unique_barcodes']} farklı barkod. Bunların {summary['invalid_pending_occurrences']} satırında kontrol basamağı hatalı.",'',summary['scope'],'','Tam liste: [pending.csv](pending.csv), [report.json](report.json). Tekrar üretim: `python tool/report_catalog_gaps.py`.','', 'Aşağıdaki adlar kullanıcı gönderileridir; ürünün var olduğu veya gönderilen barkodla eşleştiği doğrulanmış sayılmaz. Önceki denetimde başka GTIN ile eklenenler previous_outcome alanında korunur.','', '| Barkod | Ürün | Neden | Gönderi kaynağı |','|---|---|---|---|']
    details=['## Kapsam ve durum','', '| Kategori | Gönderi satırı | Bekleyen satır | Bekleyen farklı barkod |','|---|---:|---:|---:|']
    details += [f"| {category} | {values['submission_occurrences']} | {values['pending_occurrences']} | {values['pending_unique_barcodes']} |" for category,values in summary['categories'].items()]
    details += ['', 'Barkod sayısı benzersiz ürün sayısı değildir. Aynı ürün yanlış barkodlarla veya farklı gramajlarla tekrar gönderilmiş olabilir. Available tablosu, gönderilen barkodla mevcut olanlar ve kaynakla bulunan farklı barkodla eklenenleri ayırır; katalogdaki tüm ürünler current_catalog.json dosyasındadır.','', '## Teknik sorunların çözümü','', 'GTIN-8, GTIN-12, GTIN-13 ve GTIN-14 kontrol basamakları desteklenir. GTIN-8/12/14 geçersiz sayılmaz. Uygulama katalog yüklerken invalid_gtin, category_mismatch, missing_name_or_ingredients, missing_source, missing_check_date, invalid_tag_list ve duplicate_gtin nedenlerini ayrı izler. Kaynakta bulunamama, eksik içerik ve ürün kimliği uyuşmazlıkları bu dosyada ayrıca sınıflanır.','', 'Eşleşen gönderiler: [available.csv](available.csv). Katalogdaki tam ürün adıyla gönderilen ad farklıysa catalog_name alanını esas alın. Tam isim benzerliği tek başına otomatik ürün eşleştirmesi yapmaz.','', '## Eklenemeyen gönderiler','']
    lines=lines[:-2]+details+lines[-2:]
    batch=['## Kayıtlı onarım ve genişletme araştırmaları','', 'Aşağıdaki tablo repair_results*.json dosyalarındaki tüm kayıtlı araştırmaları içerir; yalnız son çalışmanın ekleme sayısı değildir. Her batchin ayrı sayıları report.json içindeki repair_batch_counts alanındadır.', '', f"Gönderi listesinden bağımsız yeni keşiflerde ayrıca **{len(discovery_pending)} bekleyen ürün adayı** var: [discovery_pending.csv](discovery_pending.csv). Bunlar yukarıdaki gönderi satırı toplamına dahil değildir. Yeni doğrulanan katalog ürününün eski yanlış barkodlu gönderiyle aynı kimlikte olduğu kanıtlanmadığında gönderi bekleyen sayısı otomatik düşürülmez.", '', '| Sonuç | Ürün | Gönderilen barkod | Kaynakla bulunan barkod | Açıklama |','|---|---|---|---|---|']
    batch += ['| '+' | '.join(str(x.get(k,'')).replace('|','/') for k in ('status','name','submitted_code','verified_code','reason'))+' |' for x in repair_items]
    lines=lines[:4]+['']+batch+['']+lines[4:]
    lines += ['| '+ ' | '.join(str(x[k]).replace('|','/') for k in ('barcode','name','reason','source'))+' |' for x in pending]
    (OUT/'REPORT.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
    print(json.dumps(summary,ensure_ascii=False,indent=2))

if __name__=='__main__':
    main()

