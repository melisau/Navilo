"""Read-only audit of submitted text, separate from catalogue publication."""
import json
import re
from collections import Counter
from pathlib import Path
from tool.catalog_validation import valid_gtin
from tool.submitted_text_normalization import normalize_submitted

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/catalog_analysis'

def main():
    rows = json.loads((OUT / 'submitted_processed_meat_150_20261013.json').read_text(encoding='utf-8'))
    rows = [normalize_submitted(row) for row in rows]
    assert [r['no'] for r in rows] == list(range(1, 151))
    counts = Counter(r['code'] for r in rows)
    commentary = {38, 56, 60, 61, 63, 70, 81, 86, 101, 115, 120, 144}
    issues = []
    for row in rows:
        flags = []
        checksum = valid_gtin(row['code'])
        if not checksum:
            flags.append('Barkodun GTIN kontrol basamağı hatalı')
        else:
            flags.append('GTIN kontrolü geçiyor; barkod–ürün–gramaj eşleşmesi bu gönderimle doğrulanmış değil')
        flags.append('Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok')
        if counts[row['code']] > 1:
            flags.append('32 ve 126 aynı ürün adı/barkoduyla tekrar edilmiş; iki ayrı ürün sayılmaz')
        if not re.search(r'\d+\s*(?:g|gr|ml|kg)\b', row['name'], re.I):
            flags.append('Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir')
        if re.search(r'(?<!\w)(?:emülgatör|stabilizatör|stabilizör|antioksidan|koruyucu)(?=\s*[,\.]|\s*$)', row['ingredients'], re.I):
            flags.append('Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz')
        if row['no'] in commentary:
            flags.append('İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış')
        if row['no'] in {64, 143}:
            flags.append('Karışık pakette her bileşen ürünün tam alt içeriği ayrı verilmemiş; tam etiket kabul edilemez')
        if row.get('text_corrections'):
            flags.append('Kullanıcının isteğiyle yazım düzeltildi; özgün metin saklandı; kaynak doğrulaması yapılmış sayılmaz')
        if row['no'] in {10, 79} and not row.get('text_corrections'):
            flags.append('Metin hatası: “deksitroz”; etiket kaynağıyla teyit edilmeden otomatik düzeltme yapılmamalı')
        if row['no'] == 97 and not row.get('text_corrections'):
            flags.append('Metin hatası: “süt proteni”; beklenen ifade “süt proteini”, kaynak teyidi gerekli')
        if row['no'] == 115 and not row.get('text_corrections'):
            flags.append('“hindistan cevizi cevizi (muskat)” ifadesi tekrar ve bileşen adı belirsizliği içeriyor')
        if row['no'] == 2:
            flags.append('Önceki işlemde 8690527021149 ile düzeltilmişti; kullanıcının sonraki talebiyle geri çekildi, karantinada')
        if row['no'] == 31:
            flags.append('Aynı ürün katalogda 8690527010938 ile mevcut; gönderilen metinde mevcut kaynakta bulunan soya proteini gibi bileşenler eksik')
        if row['no'] == 51:
            flags.append('Ürün adı/gramaj şüphesi: resmî mağazada İllaki Dana Sucuk 240 g ve İllaki Dana Kasap Sucuk 300 g ayrı ürünler; 240 g “Kasap” eşleşmesi teyit edilmeli')
        issues.append({**row, 'gtin_checksum_pass': checksum, 'findings': flags})
    summary = {
        'submitted_rows': len(rows), 'distinct_submitted_codes': len(counts),
        'invalid_gtin_rows': sum(not r['gtin_checksum_pass'] for r in issues),
        'checksum_pass_rows_not_identity_verified': sum(r['gtin_checksum_pass'] for r in issues),
        'rows_missing_submitted_label_evidence': 150,
        'rows_missing_quantity_fodmap_only': sum(any(f.startswith('Gramaj belirtilmemiş:') for f in r['findings']) for r in issues),
        'generic_additive_rows': sum(any(f.startswith('Katkının') for f in r['findings']) for r in issues),
        'duplicate_groups': [[32, 126]],
        'recovered_then_withdrawn': [2], 'previously_existing_product': [31],
    }
    (OUT / 'processed_meat_150_audit_20261013.json').write_text(json.dumps({'summary': summary, 'rows': issues}, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    md = '''# Son gönderilen 150 şarküteri kaydı — hata ve eksik incelemesi

13 Ekim 2026. Kapsam: ilk gönderimdeki 1–50 ve son gönderimdeki 51–150. Bunlar 150 gönderim satırıdır; 150 yeni ürünün uygulamaya eklendiği anlamına gelmez. Bu işlem katalog verisini değiştirmez.

**Kesin bulgu: 116/150 satırda (%77,3) barkod kontrol basamağı hatalı.** İlk 50 satırda 40; son 100 satırda 76. Kalan 34 satırda barkod matematiksel kontrolü geçer; bu kontrol gerçek ürün kimliği veya içerik doğrulaması değildir. Bir barkodun son rakamını hesaplayıp değiştirmek, o numarayı ürüne ait doğrulanmış barkod yapmaz.

**Gönderilen 150 içerik metninin hiçbirinde doğrudan etiket kaynağı, etiket fotoğrafı veya kaynak tarihi bulunmuyor.** Bu, içeriklerin hepsinin yanlış olduğunun kanıtı değildir; “resmî ambalaj içeriği” diye kabul etmek için kanıtın eksik olduğu anlamına gelir. Önceki işlemde 2. satır bağımsız kaynaklardan düzeltildi; 31. satırdaki ürün zaten katalogdaydı.

Ek bulgular (bir satır birden fazla grupta olabilir; sayılar toplanmamalıdır):

- 32 ve 126: aynı barkod ve ürünün tekrar gönderimi. 150 satırda 149 farklı barkod bulunur.
- 11 satırda gramaj eksik: 5, 9, 10, 11, 14, 36, 39, 40, 47, 48, 72. Genel içerik değerlendirmesinde engel değildir; yalnızca miktara göre FODMAP sonucu için ek kanıt gerekir.
- 15 satırda katkı maddesi ismi/E kodu yerine yalnızca “emülgatör”, “stabilizatör”, “antioksidan” gibi işlev yazıyor: 26, 41, 42, 93, 107, 108, 109, 114, 118, 119, 129, 134, 136, 139, 142. Bu, mevzuat ihlali tespiti değil; uygulamanın bileşen değerlendirmesi için yetersiz ayrıntı tespitidir.
- 64 ve 143: karışık şarküteri paketinin bileşen ürünleri için tam alt içerik ayrı verilmemiş.
- 10 ve 79: “dekstroz”; 97: “süt proteini”; 115: “muskat” olarak kullanıcı isteğiyle düzeltildi. Özgün metinler korunur.
- 12 satırda içindekiler alanına proses/ambalaj açıklaması veya ayrı bir iddia karışmış: 38, 56, 60, 61, 63, 70, 81, 86, 101, 115, 120, 144. Örneğin “katkı maddesi içermeyen”, “nişasta ve glukoz içermez”, “gaz paketleme” bir bileşen adı değildir; kaynakla teyit edilerek ayrı alanda tutulmalıdır.

Somut kaynak karşılaştırmaları:

- **2 — Pınar Klasik Dana Kangal Sucuk 225 g:** gönderilen `8690526032415` geçersiz. [Asya Market](https://www.asyasanalmarket.com/pinar-225-gr-sucuk--klasik--fermente--18988) aynı ürünün barkodunu `8690527021149` olarak veriyor. [CarrefourSA etiket alanı](https://www.carrefoursa.com/pinar-klasik-sucuk-225-g-p-30123642) askorbik asit bildiriyor; gönderilen metin sodyum askorbat yazıyor. Bu farklı bileşen adı olduğundan gönderim aynen alınmadı; doğrulanan kayıt eklendi.
- **31 — Pınar Aç Bitir Macar Salam 60 g:** gönderilen `8690526012110` geçersiz. Katalogdaki kaynaklı kayıt `8690527010938`. Gönderilen metin, mevcut kaynak metnindeki soya proteini, ayçiçek yağı ve diğer bazı bileşenleri taşımıyor. Mevcut kayıt korundu. Bu fark aynı ambalajın incelendiğini kanıtlamaz; yeniden etiket teyidi gerektirir.
- **51 — Pınar İllaki Dana Kasap Sucuk 240 g:** barkod geçersiz. [Resmî mağazada 240 g ürün “İllaki Dana Sucuk”](https://www.pinaronline.com/urun/pinar-illaki-dana-sucuk-240-g-152903096) olarak geçiyor. “Kasap” çeşidi ile karışmış olabileceğinden ad–gramaj eşleşmesi teyit bekler; yalnızca bu bulguyla kesin olarak ürünün mevcut olmadığı söylenmez.

Barkod kontrolünü geçen 34 satır:

'''
    md += ', '.join(str(r['no']) for r in issues if r['gtin_checksum_pass']) + '.\n\n'
    md += '''## Kullanıcının son talebine göre güncelleme

10 ve 79: “deksitroz” → “dekstroz”; 97: “süt proteni” → “süt proteini”; 115: “hindistan cevizi cevizi (muskat)” → “muskat”. Özgün metinler ve değişiklik geçmişi karantinada saklandı. Bu düzeltmeler kayıtların doğrulandığı veya yayımlandığı anlamına gelmez.

Gramaj eksikliği/farklılığı, genel içerik değerlendirmesinde tek başına ret nedeni değildir. Farklı ambalajlarda içerik metni gerçekten aynıysa aynı madde kuralları uygulanır. FODMAP için ayrıca kaynaklı gram/porsiyon aralıkları gerekir. Düşük bir miktar bilgisinden hareketle daha yüksek tüm miktarların otomatik olarak yüksek olduğu varsayılmaz; yalnızca kaynakta doğrulanan aralıklar kullanılabilir. Son 150 kayıt hâlâ tamamen karantinadadır; daha önce düzeltilerek eklenen 2. satır da kullanıcının sonraki talebiyle geri çekilmiştir.

'''
    md += '## Satır bazında bütün ürünler\n\nHer satırın tam adı, gönderilen barkodu ve bulunan sorunlar aşağıdadır. “Kaynak yok” ifadesi gönderilen metne ilişkindir; internet üzerinde hiçbir kaynak olmadığı iddiası değildir.\n\n'
    md += '| No | Ürün | Gönderilen barkod | Barkod kontrolü | Bulgular |\n|---:|---|---|---|---|\n'
    for row in issues:
        findings = row['findings'][1:]
        md += f"| {row['no']} | {row['name']} | `{row['code']}` | {'Geçer — kimlik teyidi değil' if row['gtin_checksum_pass'] else 'HATALI'} | {'; '.join(findings)} |\n"
    destination = ROOT / 'docs/PROCESSED_MEAT_150_AUDIT_20261013.md'
    destination.write_text(md, encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False))

if __name__ == '__main__':
    main()
