# Şarküteri düzeltme çalışması — 13 Ekim 2026

Çalışma tamamlanmadı. 150 ham satır korundu; 149 aday kimliği oluşturuldu. 32/126 tek adaydır fakat içerikleri farklı olduğu için iki metin de saklanır.

12 satırdaki köşeli parantezli proses/iddia metni submitted_notes alanına taşındı. Kaynak teyidi verilmedi. Önceden yapılmış dört yazım düzeltmesi korundu.

116 hatalı özgün barkod değiştirilmedi; kaynakta bulunan numaralar repair_evidence.candidate_code alanındadır. 139 satır için bu tur kaynak araştırması henüz yapılmadı. Canlı kataloğa eklenen ürün: 0.

| Satır | Kaynak sonucu | Aday barkod | Kalan iş |
|---|---|---|---|
| 2 | retailer_fields_matched | 8690527021149 | Daha önce kullanıcı tarafından yayından çekilmiş; kaynaklı düzeltme ayrı saklanır. Canlı yayın durumu değişmedi. |
| 3 | secondary_barcode_lead_only | 8697471729732 | İkincil kaynakta aday numara bulundu. Üretici/perakendeci barkod ve tam içerik kanıtı gerekli; gönderilen geçerli GTIN kimliği kanıtlamıyor. |
| 8 | variant_and_formula_link_pending | 8680181001984 | Üreticinin 2025 ihracat kataloğundaki çeşit ile gönderimdeki Doğal ürünün kimliği ve ülke/formül eşleşmesi bekliyor. |
| 16 | candidate_needs_direct_barcode_page_check | 8690527030134 | Barkod arama indeksinde görüldü; doğrudan barkod sayfası açılmadı. Aynı gramajdaki hindi sosis ile karıştırılmamalı. |
| 31 | linked_existing_catalogue_product | 8690527010938 | Yeni ürün değildir. Gönderim metni mevcut kaynaklı içerikle değiştirilmeden ayrı korunmuştur. |
| 32 | historical_barcode_current_label_link_pending | 8690527011065 | Barkod üreticinin 2018 kataloğunda; güncel ambalaj eşleşmesi gerekli. Migros %3 fıstık bildiriyor, iki gönderim %4. Gönderimler arasında nişasta/mısır nişastası farkı da var. |
| 51 | variant_ambiguity | — | Gönderimde Kasap çeşidi yazıyor; 240 g standart ürünün bilgisi Kasap çeşidine taşınmadı. |
| 104 | secondary_barcode_lead_only | 8690681202514 | İkincil kaynak adayı; doğrudan barkod ve tam içerik kaynağı gerekli. 250 g piliç sosisin barkodu farklıdır. |
| 113 | manufacturer_page_quantity_conflict | 8697403890462 | Resmi sayfanın ürün başlığı ve gramaj alanı 250 g; arama başlığı 215 g. Ambalaj gramajı ve barkod eşleşmesi teyit edilmeli. Tam bileşen alanında süt ve soya proteini bulunuyor. |
| 126 | historical_barcode_current_label_link_pending | 8690527011065 | Barkod üreticinin 2018 kataloğunda; güncel ambalaj eşleşmesi gerekli. Migros %3 fıstık bildiriyor, iki gönderim %4. Gönderimler arasında nişasta/mısır nişastası farkı da var. |
| 144 | retailer_fields_matched | 8690527200278 | Kaynak düzeyinde eşleşti; ambalaj incelemesi yapılmadı. Gönderimde eksik olan süt, soya, buğday ve kereviz bilgileri kaynak adayında korunur. |

## Kaynaklar

- Satır 2, barcode_source_url: https://www.asyasanalmarket.com/pinar-225-gr-sucuk--klasik--fermente--18988
- Satır 2, ingredients_source_url: https://www.carrefoursa.com/pinar-klasik-sucuk-225-g-p-30123642
- Satır 3, barcode_source_url: https://marketkarsilastir.com/fiyat/8697471729732-namet-dana-fermente-kangal-sucuk-225-g
- Satır 8, barcode_source_url: https://torku.com.tr/Upload/Contents/7883150_Torku-Ihracat-Katalogu-2025.pdf
- Satır 8, ingredients_source_url: https://www.macrocenter.com.tr/torku-sucuk-vakum-225-g-p-d8d16b
- Satır 16, barcode_source_url: https://ercaglayangida.com/urun/pinar-dana-sosis-avantaj-paket-430-gr/
- Satır 16, ingredients_source_url: https://www.carrefoursa.com/pinar-dana-sosis-10-lu-430-g-p-30037887
- Satır 31, barcode_source_url: https://www.gurmar.com.tr/pinar-ac-bitir-dana-macar-salam-60-gr-7078-p
- Satır 31, ingredients_source_url: https://www.sariyermarket.com/pinar-ac-bitir-macar-salam-60-gr
- Satır 32, barcode_source_url: https://www.pinar.com.tr/images/pdf/PERAKENDE31.10.2018.pdf#page=98
- Satır 32, ingredients_source_url: https://www.migros.com.tr/mion/pinar-salam-ac-bitir-dana-macar-fistikli-salam-50g-p-d72647
- Satır 51, product_source_url: https://www.pinaronline.com/urun/pinar-illaki-dana-sucuk-240-g-152903096
- Satır 104, barcode_source_url: https://marketkarsilastir.com/fiyat/8690681202514-maret-sosis-kokteyl-dana-250-gr
- Satır 113, barcode_source_url: https://online.danet.com.tr/kokteyl-sosis-250gr
- Satır 113, ingredients_source_url: https://online.danet.com.tr/kokteyl-sosis-250gr
- Satır 126, barcode_source_url: https://www.pinar.com.tr/images/pdf/PERAKENDE31.10.2018.pdf#page=98
- Satır 126, ingredients_source_url: https://www.migros.com.tr/mion/pinar-salam-ac-bitir-dana-macar-fistikli-salam-50g-p-d72647
- Satır 144, barcode_source_url: https://www.sariyermarket.com/pinar-ac-bitir-buyuk-dilim-hindi-fume-60-gr
- Satır 144, ingredients_source_url: https://www.sariyermarket.com/pinar-ac-bitir-buyuk-dilim-hindi-fume-60-gr
- Satır 144, supporting_source_url: https://gurmar.com.tr/p%C4%B1nar-ac-bitir-hindi-fume-60-gr
