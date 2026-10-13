# Namet, Aytaç ve Erpiliç kaynak incelemesi

13 Ekim 2026. Namet'in önceki turda eklenen kaydı bu incelemede geri çekildi. Kaynak metni sessizce E301 veya E316 olarak değiştirilmedi. Tam içerik doğrulaması beklenirken kayıt uygulama sonuçlarında kullanılmıyor; dış servis veya ürün adı aramasıyla geri getirilemiyor. Önceki kaynaklı partide kullanılabilir ürün sayısı 7'den 6'ya indi.

| Ürün | Barkod | Durum | Eksik/çelişki |
|---|---|---|---|
| Namet Kangal Sucuk 240 g | 8697471727219 | Doğrulanmadı; etiketten teyit edilmeli | Aynı barkodda OFF E301, Macrocenter E316 |
| Aytaç Çiftlik Piliç Kokteyl Sosis 500 g | Bilinmiyor | Doğrulanmadı | Tam içerik var, GTIN kaynağı yok |
| Aytaç Çiftlik Dana Kokteyl Sosis 250 g | Bilinmiyor | Doğrulanmadı | Tam içerik var, GTIN kaynağı yok |
| Aytaç Kokteyl Sosis 225 g | 8691520104198 | Doğrulanmadı | Perakendeci JSON-LD GTIN'i var; tam içerik yok |
| Erpiliç Kokteyl Sosis 700 g | 8696024317020 | Doğrulanmadı | Perakendeci JSON-LD GTIN'i var; aynı ürüne bağlı tam içerik yok |

Namet kaynakları:

- [Macrocenter 240 g](https://www.macrocenter.com.tr/namet-kangal-sucuk-240-g-p-d8d15c): antioksidan **E316**.
- [Open Food Facts aynı barkod](https://world.openfoodfacts.org/product/8697471727219/namet-kangal-sucuk-240-g): [API](https://world.openfoodfacts.org/api/v2/product/8697471727219.json) yanıtı doğrudan HTTP 200 alındı; `ingredients_text_tr` içinde **E301**, `additives_tags` içinde `en:e301` var. API yanıtı `catalog_analysis/namet_conflict_20261013/off.json` dosyasında saklandı.
- [Aksa Gıda 200 g](https://aksagida.com.tr/magaza/namet-dana-sucuk-kangal-vakumlu-200-gr--12): kullanıcı E301 bildirdi; bu oturumdaki doğrudan istek HTTP 410 döndü. Bu ayrı ürünün bilgisi 240 g ürünün çelişkisini çözmek için kullanılmadı.

Aytaç kaynakları:

- [Şok piliç kokteyl 500 g](https://www.sokmarket.com.tr/aytac-ciftlik-pilic-kokteyl-sosis-500-g-p-214005): tam içerik, soya ve süt beyanı var; mağaza ürün kodu barkod sayılmadı.
- [Şok dana kokteyl 250 g](https://www.sokmarket.com.tr/aytac-ciftlik-dana-kokteyl-sosis-250-g-p-600510): tam içerik, soya ve süt beyanı var; mağaza ürün kodu barkod sayılmadı.
- [Mismar Aytaç 225 g](https://www.mismarsanalmarket.com/aytac-kokteyl-sosis-225-gr): JSON-LD `gtin=8691520104198` doğrudan doğrulandı; açıklama boş. 250/500 g içerikleri otomatik aktarılmadı.
- [Mismar Erpiliç 700 g](https://www.mismarsanalmarket.com/erpilic-kokteyl-sosis-700-gr): JSON-LD `gtin=8696024317020` doğrudan doğrulandı; açıklama boş. Genel sosis formülü bu barkoda varsayımla atanmadı.

Gramaj farkı genel içerik değerlendirmesinde tek başına ret nedeni değildir. Buradaki sorun, farklı kayıtların gerçekten aynı içeriğe sahip olduğunu gösteren kanıtın olmamasıdır. Barkod öneki tek başına ürün doğrulama veya ret kuralı yapılmadı; tam barkod, ürün adı ve içerik kaynaklarının eşleşmesi esas alındı.

Araştırma kayıtları `data/quarantine/source_review_pending.json` dosyasındadır. Namet'in eski inceleme tarihi `previous_verified_at` olarak korundu; güncel `verified_at=null`, `status=unverified`, `field_status.antioxidant=label_check_required`. Veriler ürün sonucu veya gluten/laktoz/FODMAP değerlendirmesi üretmek için kullanılmaz.

Sunucu için ek SQL migration hazırlandı; canlı veritabanına uygulanmadı. Bu çalışma yerel uygulama kataloğu ve Android paketini günceller.
