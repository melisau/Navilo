"""Repair submission structure and attach evidence without asserting publication."""
import json
import re
from datetime import datetime, timezone
from pathlib import Path

from tool.catalog_validation import valid_gtin
from tool.submitted_text_normalization import normalize_submitted

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / 'data/quarantine/processed_meat_150.json'
REPORT = ROOT / 'docs/catalog_analysis/processed_meat_repair_20261013.json'
NOTES = ROOT / 'docs/PROCESSED_MEAT_REPAIR_20261013.md'


def main():
    original = json.loads(PATH.read_text(encoding='utf-8'))
    rows = [normalize_submitted(r) for r in original]
    commentary_rows = {38, 56, 60, 61, 63, 70, 81, 86, 101, 115, 120, 144}
    assert len(rows) == 150 and len({r['no'] for r in rows}) == 150
    by_no = {r['no']: r for r in rows}
    reviewed_at = datetime.now(timezone.utc).isoformat()
    existing = json.loads((ROOT / 'assets/curated_products.json').read_text(encoding='utf-8'))
    existing_salam = next(r for r in existing if r['code'] == '8690527010938')
    evidence = {
        2: {
            'candidate_code': '8690527021149',
            'candidate_name': 'Pınar Klasik Dana Fermente Sucuk 225 g',
            'candidate_ingredients': 'Dana eti ve yağı, baharat karışımı, tuz, tatlı kırmızıbiber, sarımsak, antioksidan(askorbik asit), koruyucu madde(sodyum nitrit).',
            'barcode_source_url': 'https://www.asyasanalmarket.com/pinar-225-gr-sucuk--klasik--fermente--18988',
            'ingredients_source_url': 'https://www.carrefoursa.com/pinar-klasik-sucuk-225-g-p-30123642',
            'result': 'retailer_fields_matched',
            'remaining': 'Daha önce kullanıcı tarafından yayından çekilmiş; kaynaklı düzeltme ayrı saklanır. Canlı yayın durumu değişmedi.',
        },
        16: {
            'candidate_code': '8690527030134',
            'candidate_name': "Pınar Dana Sosis 10'lu 430 g",
            'barcode_source_url': 'https://ercaglayangida.com/urun/pinar-dana-sosis-avantaj-paket-430-gr/',
            'ingredients_source_url': 'https://www.carrefoursa.com/pinar-dana-sosis-10-lu-430-g-p-30037887',
            'result': 'candidate_needs_direct_barcode_page_check',
            'remaining': 'Barkod arama indeksinde görüldü; doğrudan barkod sayfası açılmadı. Aynı gramajdaki hindi sosis ile karıştırılmamalı.',
        },
        31: {
            'candidate_code': existing_salam['code'],
            'candidate_name': existing_salam['name'],
            'candidate_ingredients': existing_salam['ingredients'],
            'barcode_source_url': 'https://www.gurmar.com.tr/pinar-ac-bitir-dana-macar-salam-60-gr-7078-p',
            'ingredients_source_url': existing_salam['source_url'],
            'result': 'linked_existing_catalogue_product',
            'remaining': 'Yeni ürün değildir. Gönderim metni mevcut kaynaklı içerikle değiştirilmeden ayrı korunmuştur.',
        },
        32: {
            'candidate_code': '8690527011065',
            'candidate_name': 'Pınar Aç Bitir Fıstıklı Macar Salam 50 g (dana)',
            'barcode_source_url': 'https://www.pinar.com.tr/images/pdf/PERAKENDE31.10.2018.pdf#page=98',
            'ingredients_source_url': 'https://www.migros.com.tr/mion/pinar-salam-ac-bitir-dana-macar-fistikli-salam-50g-p-d72647',
            'result': 'historical_barcode_current_label_link_pending',
            'remaining': 'Barkod üreticinin 2018 kataloğunda; güncel ambalaj eşleşmesi gerekli. Migros %3 fıstık bildiriyor, iki gönderim %4. Gönderimler arasında nişasta/mısır nişastası farkı da var.',
        },
        51: {
            'candidate_code': None,
            'candidate_name': 'Pınar İllaki Dana Sucuk 240 g',
            'product_source_url': 'https://www.pinaronline.com/urun/pinar-illaki-dana-sucuk-240-g-152903096',
            'result': 'variant_ambiguity',
            'remaining': 'Gönderimde Kasap çeşidi yazıyor; 240 g standart ürünün bilgisi Kasap çeşidine taşınmadı.',
        },
        144: {
            'candidate_code': '8690527200278',
            'candidate_name': 'Pınar Aç Bitir Büyük Dilim Hindi Füme 60 g',
            'candidate_ingredients': 'Hindi göğüs eti,su,patates nişastası,tuz,baharat karışımı (karabiber,kimyon,kekik,kereviz),buğday lifi,sarımsak,kıvam arttırıcı(karragenan,guar gam),süt proteini,koruyucu madde(sodyum laktat,sodyum nitrit),stabilazör (sodyum polifosfat),antioksidan(askorbik asit),aroma vericiler,soya proteini',
            'barcode_source_url': 'https://www.sariyermarket.com/pinar-ac-bitir-buyuk-dilim-hindi-fume-60-gr',
            'ingredients_source_url': 'https://www.sariyermarket.com/pinar-ac-bitir-buyuk-dilim-hindi-fume-60-gr',
            'supporting_source_url': 'https://gurmar.com.tr/p%C4%B1nar-ac-bitir-hindi-fume-60-gr',
            'result': 'retailer_fields_matched',
            'remaining': 'Kaynak düzeyinde eşleşti; ambalaj incelemesi yapılmadı. Gönderimde eksik olan süt, soya, buğday ve kereviz bilgileri kaynak adayında korunur.',
        },
    }
    evidence.update({
        8: {
            'candidate_code': '8680181001984',
            'candidate_name': 'Torku Sucuk Keyfim Fermente 225 g',
            'barcode_source_url': 'https://torku.com.tr/Upload/Contents/7883150_Torku-Ihracat-Katalogu-2025.pdf',
            'ingredients_source_url': 'https://www.macrocenter.com.tr/torku-sucuk-vakum-225-g-p-d8d16b',
            'result': 'variant_and_formula_link_pending',
            'remaining': 'Üreticinin 2025 ihracat kataloğundaki çeşit ile gönderimdeki Doğal ürünün kimliği ve ülke/formül eşleşmesi bekliyor.',
        },
        3: {
            'candidate_code': '8697471729732',
            'candidate_name': 'Namet Dana Fermente Kangal Sucuk 225 g',
            'barcode_source_url': 'https://marketkarsilastir.com/fiyat/8697471729732-namet-dana-fermente-kangal-sucuk-225-g',
            'result': 'secondary_barcode_lead_only',
            'remaining': 'İkincil kaynakta aday numara bulundu. Üretici/perakendeci barkod ve tam içerik kanıtı gerekli; gönderilen geçerli GTIN kimliği kanıtlamıyor.',
        },
        104: {
            'candidate_code': '8690681202514',
            'candidate_name': 'Maret Dana Kokteyl Sosis 250 g',
            'barcode_source_url': 'https://marketkarsilastir.com/fiyat/8690681202514-maret-sosis-kokteyl-dana-250-gr',
            'result': 'secondary_barcode_lead_only',
            'remaining': 'İkincil kaynak adayı; doğrudan barkod ve tam içerik kaynağı gerekli. 250 g piliç sosisin barkodu farklıdır.',
        },
        113: {
            'candidate_code': '8697403890462',
            'candidate_name': 'Danet Dana Kokteyl Sosis 250 g',
            'barcode_source_url': 'https://online.danet.com.tr/kokteyl-sosis-250gr',
            'ingredients_source_url': 'https://online.danet.com.tr/kokteyl-sosis-250gr',
            'result': 'manufacturer_page_quantity_conflict',
            'remaining': 'Resmi sayfanın ürün başlığı ve gramaj alanı 250 g; arama başlığı 215 g. Ambalaj gramajı ve barkod eşleşmesi teyit edilmeli. Tam bileşen alanında süt ve soya proteini bulunuyor.',
        },
    })
    evidence[126] = {**evidence[32], 'same_candidate_as_row': 32}
    for row in rows:
        row.setdefault('ingredients_original', row['ingredients'])
        # Reconstruct from preserved text so reruns cannot lose bracketed ingredients.
        restored = normalize_submitted({**row, 'ingredients': row['ingredients_original']})
        row['ingredients'] = restored['ingredients']
        if row['no'] not in commentary_rows:
            row.pop('submitted_notes', None)
            row.pop('submitted_notes_verified', None)
        # Only explicitly bracketed commentary is moved; ingredient parentheses stay.
        notes = re.findall(r'\[([^\]]+)\]', row['ingredients']) if row['no'] in commentary_rows else []
        if notes:
            row['submitted_notes'] = list(dict.fromkeys(row.get('submitted_notes', []) + notes))
            row['submitted_notes_verified'] = False
            row['ingredients'] = re.sub(r'\s*\[[^\]]+\]', '', row['ingredients']).strip()
        row['submitted_code_checksum_valid'] = valid_gtin(row['code'])
        row['canonical_submission_no'] = 32 if row['no'] == 126 else row['no']
        if row['no'] in (32, 126):
            row['duplicate_group'] = [32, 126]
            row['duplicate_ingredient_conflict'] = 'nişasta / mısır nişastası'
        if row['no'] in evidence:
            candidate = evidence[row['no']]
            if candidate.get('candidate_code'):
                assert valid_gtin(candidate['candidate_code'])
            prior = row.get('repair_evidence', {})
            candidate['reviewed_at'] = prior.get('reviewed_at', reviewed_at)
            row['repair_evidence'] = candidate
        assert row['status'] == 'unverified' and row['verified_at'] is None
    assert [r['code'] for r in original] == [r['code'] for r in rows]
    summary = {
        'submitted_rows': len(rows),
        'canonical_candidates': len({r['canonical_submission_no'] for r in rows}),
        'original_invalid_barcode_rows': sum(not r['submitted_code_checksum_valid'] for r in rows),
        'notes_separated_rows': [r['no'] for r in rows if r.get('submitted_notes')],
        'source_researched_rows': sorted(evidence),
        'retailer_matched_rows': [2, 144],
        'existing_catalogue_link_rows': [31],
        'historical_or_access_pending_rows': [16, 32, 126],
        'variant_pending_rows': [51],
        'not_source_researched_this_pass': [r['no'] for r in rows if r['no'] not in evidence],
        'newly_published_products': 0,
        'complete': False,
    }
    PATH.write_text(json.dumps(rows, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    REPORT.write_text(json.dumps({'summary': summary, 'evidence': evidence}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    lines = ['# Şarküteri düzeltme çalışması — 13 Ekim 2026', '',
             'Çalışma tamamlanmadı. 150 ham satır korundu; 149 aday kimliği oluşturuldu. 32/126 tek adaydır fakat içerikleri farklı olduğu için iki metin de saklanır.', '',
             '12 satırdaki köşeli parantezli proses/iddia metni submitted_notes alanına taşındı. Kaynak teyidi verilmedi. Önceden yapılmış dört yazım düzeltmesi korundu.', '',
             f"116 hatalı özgün barkod değiştirilmedi; kaynakta bulunan numaralar repair_evidence.candidate_code alanındadır. {150-len(evidence)} satır için bu tur kaynak araştırması henüz yapılmadı. Canlı kataloğa eklenen ürün: 0.", '',
             '| Satır | Kaynak sonucu | Aday barkod | Kalan iş |', '|---|---|---|---|']
    for no, e in sorted(evidence.items()):
        lines.append(f"| {no} | {e['result']} | {e.get('candidate_code') or '—'} | {e['remaining']} |")
    lines += ['', '## Kaynaklar', '']
    for no, e in sorted(evidence.items()):
        for key, value in e.items():
            if key.endswith('_url'):
                lines.append(f'- Satır {no}, {key}: {value}')
    NOTES.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False))


if __name__ == '__main__':
    main()
