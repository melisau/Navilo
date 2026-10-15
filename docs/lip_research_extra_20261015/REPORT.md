# Ek 100 ruj/lipstick/lip gloss — 15 Ekim 2026

Yerel kozmetik kataloğuna **100 yeni benzersiz GTIN** eklendi; önceki 200 dudak ürünüyle çakışma yok. İçe aktarma 100 kabul, 0 ret. Aktarım öncesi 743 ürün vardı. Paralel diğer katalog güncellemeleriyle son dosya kontrolünde toplam 918 ürün görüldü; bu toplamın tamamı bu çalışmaya ait değildir. Bu iki dudak ürünü çalışması toplam 300 ürün ekledi.

| Mağaza | Yeni ürün |
|---|---:|
| Gratis | 36 |
| Watsons | 37 |
| Eve | 25 |
| Rossmann | 2 |
| **Toplam** | **100** |

72 ruj/lipstick ve 28 lip gloss, 16 marka. Önceki çalışmanın kataloğa alınmamış 49 doğrulanmış yedek kaydı kullanıldı; 51 kayıt yeni araştırmadan seçildi. Bu kayıtlar da kataloğa ilk kez eklenmiştir.

## Alan ve kaynak doğrulaması

Her ürün için yayımlanan barkod, ürün adı, tam özgün içerik beyanı, kontrol tarihi ve alan bazında kaynak URL'leri saklandı. Excel/CSV içeriği `ingredients_original` alanını eksiltmeden aktarır. Kaynakta varsa May Contain / olası pigment listeleri korunur; seriden veya renk adından formül üretilmez. Barkod başındaki sıfırlar korunur, kontrol basamağı değiştirilmez. Yinelenen ürünler GTIN-14 eşdeğerliğiyle denetlendi.

Gratis/Watsons içerikleri doğrudan ilgili ürün sayfalarından alındı. Eve'deki bazı ürünlerin tam INCI'si, aynı GTIN'yi yayımlayan Essence, Pastel veya diğer ilgili üretici sayfalarıyla tamamlandı. Mağaza ve içerik kaynakları ayrı sütunlardadır. `reviewed_rossmann.json` dosya adı araştırmayı yapan agentın önceki kaynak görevinden gelir; bu turdaki Essence kayıtlarının mağaza kaynağı **Eve** olup kaynak istatistiğinde Eve olarak sayılmıştır.

Özgün kaynak yazımı korunur; liste yayımlanmış içerik beyanını aktarır. Fiziksel ambalaj kontrolü yapılmadı. Aynı serideki başka bir renk için içerik tahmin edilmedi.

## Seçime alınmayan örnekler

- Deborah 06 Burgundy (`8009518442281`): içerik yalnızca yedi baz bileşende bitiyor, pigment bildirimi yok; eksiksizlik doğrulanamadı.
- I Heart Revolution Milkshake Gloss (`5057566843263`): kaynak pigment listesinde kapanmayan parantez nedeniyle eksik metin olasılığı giderilemedi.
- Essence Rare Bears blind box (`4059729617286`): rastgele renkli ürün olduğundan kesin ton eşleştirmesi yapılamadı.
- Gosh adayları: Gratis barkod/adı bulunmasına rağmen eksiksiz üretici veya mağaza INCI eşleştirmesi tamamlanamadı.
- Dudak yağı, balm ve treatment ürünleri kapsam dışında bırakıldı.

Seçilmeyen doğrulanmış ürünler hata olarak sayılmaz; `reviewed_reserve.json` içinde saklanır. Diğer adayların gerekçeleri `audit_*.json` dosyalarındadır; sayfa yakalama sayıları benzersiz ürün sayısı değildir. Eve .js araştırması 160 adaydan sonra HTTP 429 alınca durduruldu; eksik kanıtla doğrulanmış kayıt üretilmedi.

## Kontroller ve teslim

`test/lip_extra_catalog_test.dart`: 100 ürünün tamamı yayınlanan barkoduyla çevrimdışı bulunuyor; doğru ürün adı, INCI, olası pigment, kaynak URL ve doğrulanmış durum döndürülüyor. Ağ çağrısı: 0. Önceki 200 dudak ürünü ve göz farı regresyonlarıyla birlikte 4 Flutter testi geçti.

`verify_deliverables.py`: Excel/CSV'de 100 satır, tam ürün adı ve özgün INCI birebir karşılaştırıldı; barkodların metin türü ve baştaki sıfırları kontrol edildi. Excel görünümü ayrıca incelendi. Sonuç `verification.json` dosyasında. Katalog doğrulama ve kaynak izlenebilirliği için 14 Python testi de geçti.

İçe aktarma verisi `selected_100.json`; kaynaklı liste `verified_products_100.csv`. Excel ve CSV `outputs/lips_extra_100_20261015/` altındadır. Güncelleme yerel uygulama veri dosyasına yapıldı; bu turda Git push, APK veya canlı ortam yayını yapılmadı.
