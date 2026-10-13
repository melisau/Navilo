# Kahvaltılık soslar 101–200 — 13 Ekim 2026

Gönderilen 100 satırın tamamı `docs/breakfast_sauces/audit.json` içinde kayıt altına alındı. 57 barkod EAN-13 kontrol basamağını geçmiyor; bu barkodlar otomatik düzeltilmedi. Geçerli 43 barkod Open Food Facts'te sorgulandı: 1 ürün bulundu (101 Çokça), diğer 42 barkodda bu kaynakta kayıt bulunmadı. Kayıt bulunmaması ürünün hiç var olmadığını kanıtlamaz.

Ürün adları üzerinden perakende ve üretici kaynakları da araştırıldı. 4 ürün çevrimdışı gıda kataloğuna alındı; toplam gıda kaydı 73'ten 77'ye çıktı. Kozmetik kataloğu 316 kayıt olarak korundu.

| Barkod | Ürün | İçerik kaynağı | Barkod kaynağı |
|---|---|---|---|
| 8699118055419 | Çokça Acılı Kahvaltılık Sos 300 g | A101 | Open Food Facts |
| 8690635260393 | Tat Kahvaltılık Sos 300 g | CarrefourSA; Migros ile destekleniyor | Hapeloğlu; OFF ürün kimliği ile destekleniyor |
| 8690508004246 | Tukaş Kahvaltılık Sos 300 g | Migros | Market Karşılaştır; OFF ürün kimliği ile destekleniyor |
| 8690103131347 | Marmarabirlik Sade Zeytin Ezmesi 340 g | Open Food Facts Türkçe metin | Open Food Facts |

Üç yeni barkod, gönderilen hatalı barkodlara takma eşleşme olarak bağlanmadı. Her kayıt kendi gerçek barkoduyla aranır. Kullanıcının gönderdiği Marmarabirlik satırında gramaj olmadığı için kayıtta doğrulanan 340 g ambalaj açıkça yazılır. Fiziksel güncel ambalaj teyidi yapılmadı; `checked_at` araştırma tarihidir.

Önemli içerik düzeltmeleri:

- Çokça: A101'in tam içerik alanı kullanıldı. Ceviz içi ve çemen unu gönderilen metinde yoktu. OFF metni baharat/koruyucu bölümünü içermediğinden eksik metin tam liste kabul edilmedi. A101 yalnızca “koruyucular” diyor; sodyum benzoat türü tahmin edilmedi.
- Tat: Kaynakta yer fıstığı (%5) ve ceviz (%1) var. Gönderilen metindeki genel domates formülü kullanılmadı.
- Tukaş: Kaynakta ceviz, potasyum sorbat ve sodyum benzoat var. İçerik sırası kaynakta olduğu gibi korundu.
- Marmarabirlik: Türkçe OFF metni ayçiçeği lesitini, laktik asit ve potasyum sorbat içeriyor. Kaynakta `en:nuts` iz uyarısı mevcut. Uygulama OFF kaydını doğrulanmamış topluluk verisi olarak gösterir.

Formül uyuşmazlıkları ve eksik kayıtlar `docs/breakfast_sauces/evidence_conflicts.json` içinde:

- Tamek: Perakendecilerde %4 ceviz/%4 yer fıstığı ve %2 ceviz/%8 yer fıstığı içeren farklı sürümler var. Formülün barkod/sürüm eşleşmesi teyit edilmeden bir sürüm seçilmedi.
- Kühne: Aynı ad ve 300 g ambalaj altında salça bazlı ve %72 kapya biber bazlı iki içerik var. Barkod-formül ilişkisi çözülemedi.
- Sosero: Resmi sayfada doğru 290 g barkodu var; tanıtım metni tam ambalaj içeriği olarak kullanılmadı. Pazaryeri sayfasındaki soya sosuna benzeyen ilgisiz içerik listesi de ithal edilmedi.
- Burcu: Resmi acılı ürün barkodu bulundu. Tatlı ürünün içerikleri acılı ürüne taşınmadı. Burcuonline sayfalarındaki 12 haneli barkod metinleri resmi 13 haneli kod yerine geçirilmedi.

Kaynaklar:

- https://www.a101.com.tr/kapida/sut-urunleri-kahvaltilik/cokca-acili-kahvaltilik-sos-300-g_p-16001716
- https://world.openfoodfacts.org/product/8699118055419
- https://www.carrefoursa.com/tat-kahvaltilik-sos-300-g-p-30383914
- https://www.hapeloglu.com/tat-kahvalt%C4%B1l%C4%B1k-sos-300-gr-19659
- https://www.migros.com.tr/tukas-kahvaltilik-sos-300-g-p-8a4704
- https://marketkarsilastir.com/fiyat/8690508004246-tukas-kahvaltilik-sos-300-g
- https://world.openfoodfacts.org/product/8690103131347

Open Food Facts katkıcılarına atıf: © Open Food Facts contributors; ODbL 1.0, https://opendatacommons.org/licenses/odbl/1-0/ . OFF kaynaklı Marmarabirlik içerik kaydında lisans/atıf alanları korunur. Diğer kayıtların barkod kaynakları ayrı alanlarda belirtilir. Kullanıcı metni resmi veya fiziksel ambalaj kanıtı olarak etiketlenmedi.

Tekrar toplama: `python tool/collect_breakfast_sauces.py`; ek barkod araştırması: `python tool/research_corrected_sauces.py`; incelenmiş kayıtları yükleme: `python tool/import_breakfast_sauces_reviewed.py`. Toplama kaynak önbelleğini kullanır; 429 alınırsa devam etmez. İçe aktarma diğer markaları korur ve mevcut barkod çakışmasında durur.

Doğrulama: `flutter analyze`; `flutter test test/breakfast_sauce_catalog_test.dart test/turkey_catalog_test.dart test/harras_catalog_test.dart test/product_repository_test.dart`. Çevrimdışı barkod çözümlemesi, kaynak metni, alerjenler, GTIN, 100 satırlık kapsam ve belirsiz formüllerin dışarıda kalması kontrol edilir.
