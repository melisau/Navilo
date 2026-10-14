# Flormar kozmetik kataloğu — 14 Ekim 2026

79 Nail Enamel varyantı resmi Flormar ürün sayfalarından toplandı. Barkod araması `cosmetic` kategorisinde paketlenmiş `assets/curated_cosmetics.json` dosyasını kullanır; internet gerektirmez. Mevcut gıda kataloğu korunmuştur. Buna Latte Yüksek Pigmentli & Parlak Bitişli Kahve Tonlu Oje (`8682536104678`) de dahildir.

Kullanıcının verdiği 319 White Dance, 428, 305 Beige Latte, 227 Milk Foam, 321 Red Flag, 452 Marine Lover ve 077 Light Pink barkodları dahildir. 428'in güncel resmi renk adı HOT CHOCOLATE olarak kaydedildi.

Her varyantın kendi sayfasındaki analytics ürün barkodu, seçili renk, tam INGREDIENTS bölümü ve GTIN kontrol basamağı kontrol edildi. Ortak formül diğer renk sayfalarına kopyalanmadı. `checked_at` araştırma tarihidir; üretici formül güncelleme tarihi veya ambalaj doğrulaması değildir.

`ingredients` kesin baz listeyi, `may_contain` üreticinin +/- pigment listesini içerir. May contain pigmentlerinin tamamı ilgili renkte kesin varmış gibi eşleştirilmez. Kullanıcı bunları kaynak ayrıntılarında görür; değerlendirme ekranı pigment kapsamını açıklar. Pigment değerlendirmesi için ambalajdaki gerçek CI kodları gerekir. Vegan/temiz içerik veya güvenlik iddiası eklenmedi.

Pearly, Jelly Look, Full Color, Star Shine ve Green Up için kullanıcının verdiği genel baz ve varsayılan pigment eşleştirmeleri doğrulanmış ürün içerikleri olarak eklenmedi. Bu partinin kapsamı Nail Enamel serisidir.

Kaynak: https://www.flormar.com.tr/nail-enamel-yuksek-pigmentli-parlak-bitisli-oje-beyaz-8682536035880/

Tekrar toplama: `python tool/collect_flormar.py` (requests ve beautifulsoup4 gerekir). Başarısız sayfalar `docs/flormar/flormar_collection_errors.json` içinde tutulur. Son toplamada 78 ürün, 0 hata.

Doğrulama: `flutter analyze`; `flutter test test/flormar_catalog_test.dart test/product_repository_test.dart test/turkey_catalog_test.dart`. Barkod başına çevrimdışı çözümleme, kategori ayrımı, GTIN, ad ve formül eşleşmesi ile olası pigment ayrımı test edilir.
