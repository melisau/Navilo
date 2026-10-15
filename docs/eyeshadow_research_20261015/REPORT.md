# Göz farı ve palet araştırması — 15 Ekim 2026

103 benzersiz ürün için kaynakla doğrulanmış barkod, tam ürün/varyant adı ve INCI beyanı hazırlandı. Kaynak bağlantıları her satırın içinde saklanır. Liste 49 Golden Rose, 18 Pastel, 11 Maybelline New York, 10 Catrice, 9 essence ve 6 Flormar kaydından oluşur.

75 kaydın GTIN ve içerikleri Türkiye'deki üreticinin kendi sayfasından, 28 kaydın içerikleri Avrupa perakendeci ürün sayfasından doğrulandı. Toplam 80 ürün için Türkiye sayfasında aynı GTIN kaydı da bulundu. Diğer 23 ürünün Türkiye'de aynı GTIN ile satıldığı ayrıca doğrulanmadı; bunlar kaynak ülkesini koruyan Avrupa ürün kayıtlarıdır.

## Uygulama kataloğuna aktarım

92 yeni ürün eklendi. Çalışma sırasında katalogda zaten bulunan 11 ürünün aynı GTIN ve kaynak sayfasındaki içerik sözcükleri yeniden kontrol edildi; mevcut adları ve kaynak metaverileri korundu. Eşdeğer içerik karşılaştırması yalnız `INGREDIENTS:` etiketi, büyük/küçük harf ve noktalama farklılıklarını ayırır. Formül veya ürün kimliği çelişkisi sessizce değiştirilemez.

`reviewed_combined.json` 103 kaynak kaydını, `imported_new.json` 92 yeni kaydı, `integration.json` mevcut 11 kaydın açıklamasını içerir. Başka bir çalışmada eklenen 30 göz farı bu araştırmanın 103 ürün sayısına eklenmedi. Katalogda eşzamanlı yapılan diğer değişiklikler korunmuştur.

## İlk CSV'nin 100 satırı

4 satır kaynakla düzeltildi; 96 satır bekliyor. Bekleyen 85 barkodun kontrol basamağı hatalı, 11 barkod biçimsel olarak geçerli olsa da tam kimlik/içerik kanıtı eksik. Yeni keşifler bu 96 gönderi düzeltilmiş gibi sayılmadı.

| Ürün | Gönderilen barkod | Doğrulanan barkod | Düzeltme |
|---|---|---|---|
| Maybelline The Nudes | 3600531199081 | 3600531199081 | Türkiye üretici sayfasının GTIN ve tam INCI alanları kullanıldı; CSV içeriği eksikti. |
| Maybelline The Blushed Nudes | 3600531293178 | 3600531293178 | Üreticinin parlak/mat tonlar için yayımladığı iki tam formül ve pigment listesi korundu. |
| Pastel Single Eyeshadow 63 | 8690644002007 | 8690644014635 | Üreticinin GTIN'i kullanıldı; Parfum ve olası pigmentler eklendi. Gönderilen barkoda takma eşleşme yapılmadı. |
| Pastel Glow Liquid 223 Eye-Catching | 8690644002236 | 8690644002236 | CSV'nin farklı/generic formülü yerine üreticinin tam INCI'si kullanıldı. |

Satır bazındaki sonuçlar `submitted_audit.json` içinde, aynı tablo Excel çıktısının `İlk CSV denetimi` sayfasındadır. Özgün dosya değiştirilmeden `submitted_original.csv` olarak saklandı; SHA-256 `summary.json` içinde.

## Bekleyen kaynak ürünleri

Golden Rose Quattro ailesindeki 7 paletin üretici INCI alanı ikinci formülün ortasında kesiliyor. Eye Glaze 01'in tam içerik alanı bulunamadı. Bu 8 aday aktarılmadı. Ayrıca `3600531701819` için dm Almanya 110 I Am Cozy, dm Avusturya 120 I Am Authentic adını gösteriyor; çelişkili kimlik aktarılmadı. Ayrıntılar `research_local_brands.json` ve `additional_identity_conflicts.json` dosyalarında.

Beaulis, LYKD ve Wet n Wild gönderilerinde eksiksiz barkod–varyant–INCI eşleşmesi bulunamayanlar bekliyor. Wet n Wild Heart & Sol için ABD ve Avrupa formülleri veya farklı barkodlar birbirine kopyalanmadı. Flormar Sunset eski 10'lu ve yeni 9'lu ürünler arasında belirsiz; kaynak sayfasındaki renk/açıklama uyuşmazlığı nedeniyle otomatik eşleştirilmedi.

## İçerik ve kaynak kapsamı

`ingredients` baz INCI beyanını, `may_contain` kaynakta belirtilen olası renk pigmentlerini taşır. Renk adına bakarak pigment eklenmez. Bir palet farklı ton grupları için ayrı baz listeleri yayımlıyorsa bütün gruplar korunur. Kaynakların ham içeriği `ingredients_original` veya ayrı kanıt JSON'larında saklanır. Excel/CSV çıktısında baz ve “İçerebilir (+/-)” beyanı birlikte okunabilir.

Türkiye üretici formülü ile Avrupa perakendeci formülü birleştirilmedi. Her kaydın kaynak ülkesi ve inceleme tarihi belirtilir; kayıt ilgili kaynağın yayımladığı formüle aittir, fiziksel ambalaj incelemesi yapılmadı.

## Doğrulama

- 103 benzersiz GTIN ve alan bazında HTTPS kanıtı `validate_reviewed_record` ile kontrol edildi.
- 103 ürünün çevrimdışı barkod aramasında doğru içerik/pigment/kaynakla döndüğü ve ağ isteği yapmadığı test edildi.
- Pastel 63/223 için yanlış CSV formülünün kullanılmadığı, eski yanlış barkod ve çelişkili Maybelline kodunun katalogda bulunmadığı kontrol edildi.
- Göz farı, Golden Rose ve kaynak doğrulaması testlerinde 9 test geçti; katalog validator testlerinde 7 test geçti.
- Excel'in iki sayfası görsel olarak incelendi; barkodlar dosyada metin olarak saklanır. CSV/Excel satırları kaynak JSON ile karşılaştırılır.
- Son veri/noktalama kontrolünden sonra göz farı testleri yeniden çalıştırıldı; 2 test geçti. `flutter analyze`, bu araştırmada değiştirilmeyen `lib/data/local_product_store.dart:150` satırında 1 `curly_braces_in_flow_control_structures` bilgi uyarısı bildirdi.

Bu çalışma uygulamanın yerel katalog varlığını güncelledi. Yeni APK derlenmedi ve canlı veritabanına aktarım yapılmadı.
