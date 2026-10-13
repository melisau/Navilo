# Golden Rose kozmetik kataloğu — 13 Ekim 2026

Color Expert, Extreme Gel Shine ve Ice Color serilerinin resmi Türkiye mağazasındaki renk bağlantıları taranarak 220 ürün eklendi. Mevcut 78 Flormar ürünü korundu; kozmetik kataloğunda toplam 298 benzersiz barkod var. Ürünler `assets/curated_cosmetics.json` üzerinden kozmetik barkod aramasında çevrimdışı çözülür.

Her ürün için kendi sayfasındaki schema.org Product `gtin13`, ürün başlığı ve INGREDIENTS alanı kullanıldı. GTIN kontrol basamakları doğrulandı. Genel seri formülü veya tahmini renk pigmentleri başka barkodlara kopyalanmadı. `may_contain` üreticinin +/- listesini ayrı tutar; kesin içerik değerlendirmesine katılmaz. Clear ürünündeki kesin CI 60725 ise ana içerik alanında korunur.

Gönderilen 50 barkodun tamamı kontrol basamağını geçse de yalnızca 23 barkod bu taramadaki resmi ürünlerle eşleşti. Eşleşme ürün adının veya gönderilen içerik listesinin doğru olduğunu tek başına göstermez. Gönderilen ad ve pigmentler `docs/goldenrose/audit.json` içinde resmi ad/kaynakla birlikte tutulur. Eşleşmeyen 27 barkoda içerik veya başka ürünün barkodunu bağlayan takma eşleşme eklenmedi.

Örnek düzeltmeler:

- `8691190703028`: Color Expert 02 Ice White; şeffaf Clear ayrı ürün ve `8691190703004` barkodlu.
- `8691190419103`: Extreme Gel Shine 04; gönderilen listede 10 Crimson Red olarak geçiyordu.
- Ice Color 101 resmi barkodu `8691190643010`; gönderilen `8691190504014` bu ürünün doğrulanmış barkodu kabul edilmedi.
- Color Expert 60 resmi sayfada siyah; gönderilen listede sarı olarak geçiyordu.

Ice Color 201 ve 205 sayfalarında kullanılabilir INGREDIENTS alanı bulunamadı; bu iki ürün dışarıda bırakıldı. Bağlantı listesinde görünmeyen renkler `missing_shades` alanında tutulur; bu, ürünün hiç üretilmediği anlamına gelmez. `checked_at` araştırma tarihidir, üretici formül değişiklik tarihi değildir. Ambalaj doğrulaması yapılmadı.

Kaynaklar:

- https://shop.goldenrose.com.tr/golden-rose-color-expert-nail-lacquer-clear-genis-fircali-oje
- https://shop.goldenrose.com.tr/golden-rose-extreme-gel-shine-nail-color-34-jel-parlakliginda-oje
- https://shop.goldenrose.com.tr/golden-rose-ice-color-nail-lacquer-158-mini-oje

Tekrar toplama: `python tool/collect_goldenrose.py` (requests ve beautifulsoup4). Girdi `docs/goldenrose/submitted.txt`, alan bazında sonuçlar `docs/goldenrose/audit.json` içinde. Toplayıcı diğer markaların kayıtlarını korur.

Kontroller: `flutter analyze`; `flutter test test/goldenrose_catalog_test.dart test/flormar_catalog_test.dart test/product_repository_test.dart test/turkey_catalog_test.dart`.

## Velvet Matte eklemesi

13 Velvet Matte ruj kendi resmi sayfasındaki GTIN ve INCI bilgisiyle eklendi. Kozmetik kataloğu bu eklemeden sonra 329 ürün içeriyor. Önceki toplamlar tarihsel eklemeleri anlatır. Gönderilen fondöten/ruj listelerinin kontrolü: [375 kayıtlık denetim](SUBMITTED_MAKEUP_AUDIT_20261013.md).

## Eyeliner ve göz kalemi eklemesi

Dipliner Black ile Dream Eyes 401–410 ürünlerinden 11 kayıt daha eklendi. Kozmetik kataloğu toplamı 340 oldu. Kaynaklar ve gönderilen iki listenin kontrolü: [eyeliner denetim raporu](SUBMITTED_EYELINER_AUDIT_20261013.md).
