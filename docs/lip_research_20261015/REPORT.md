# Ruj / lipstick / lip gloss — 15 Ekim 2026

Kozmetik kataloğuna **200 yeni, benzersiz barkod** eklendi. Aktarım: 200 eklendi, 0 reddedildi. Önceki 543 kayıt korundu; bu aktarım sonunda 743 kayıt bulunuyordu. Çalışma sırasında diğer katalog grupları bağımsız olarak güncellenebilir.

| Türkiye mağaza kaynağı | Eklenen |
|---|---:|
| Gratis | 60 |
| Watsons | 70 |
| Eve | 30 |
| Rossmann | 40 |
| **Toplam** | **200** |

135 ruj/lipstick, 65 lip gloss; 19 marka. Ürün bazında barkod, ad, tam orijinal INCI, mağaza, barkod kaynağı, içerik kaynağı ve kontrol tarihi `verified_products_200.csv` dosyasındadır. Makine tarafından okunabilir aktarım kaydı `selected_200.json` dosyasındadır.

## Doğrulama yöntemi

- Barkodlar kaynakta yayımlanan biçimleriyle korunur; baştaki sıfırlar silinmez, kontrol basamağı üretilmez. Yinelenen ürün kontrolünde GTIN'in 14 haneye sıfırla tamamlanmış karşılığı kullanıldı.
- Mağaza ürün sayfasının barkodu ve renk/ürün adı doğrulandı. Eve ürünlerinde ve bazı Rossmann Essence ürünlerinde eksik içerik, **aynı GTIN** için üretici sayfasındaki tam INCI ile tamamlandı. Her alanın bağlantıları `field_sources` altında ayrıca saklandı.
- Orijinal içerik metni `ingredients_original` alanında ve Excel/CSV'de korundu. Kaynakta varsa olası pigmentler (+/- / May Contain) ve çift uçlu ürünlerin iki formülü de korunur. Kaynak olası pigmentleri listelediğinde bunlar belirli tonda kesin bulunan pigmentler olarak sunulmaz.
- Seri bazından renk formülü tahmin edilmedi. Kaynağın özgün yazımı korundu; ambalajın fiziksel incelemesi yapılmadı. Bu liste, belirtilen tarihteki yayımlanmış tam içerik beyanlarını aktarır.

## Eklenmeyenler

251 benzersiz doğrulanmış araştırma kaydından 200'ü seçildi; diğer **51 kayıt yedektir**, hatalı kayıt sayısı değildir (`reviewed_reserve.json`). İki Vaseline Gluta Hya kaydı dudak bakım serumu ağırlıklı olduğu için bu 200 ürünün dışında tutuldu.

Kaynak çelişkileri nedeniyle seçime alınmayan örnekler:

- `8684274001424`: Callista; Rossmann 405 Peachy Queen, üretici 406 Plum Pout adı yayımlıyor.
- `8684274000434`: Callista Hot Cocoa; Rossmann 153, üretici 513 kodu yayımlıyor.
- L'Oreal 540: yayımlanan içerikte bozuk `DILINOLE,ATEACETYLATED` parçası ve pigment bilgisi eksikliği nedeniyle onaylanmadı.

Mağaza bazındaki `audit_*.json` dosyaları ek araştırma adaylarını ve erişim/içerik eksikliği nedenlerini içerir. Tarama denemeleri ve sayfa sayıları tekil ürün sayısıyla aynı değildir. Pazarlama açıklaması bulunan fakat tam INCI bulunmayan adaylar doğrulanmış listeye alınmadı.

## Kontroller

- İçe aktarma: 200 eklendi, 0 reddedildi.
- Flutter: bu 200 barkodun tamamı çevrimdışı katalogdan doğru ürün adı, INCI, olası pigment ve kaynak bağlantısıyla döndü; **0 ağ çağrısı**. Önceki göz farı regresyonlarıyla birlikte 3 test geçti.
- Python: katalog doğrulama ve kaynak izlenebilirliği için 14 test geçti.
- Excel/CSV: 200 satırın barkodları ve tam içerik metinleri aktarım kaydıyla karşılaştırıldı; baştaki sıfırlar metin olarak korundu. Excel görünümü kontrol edildi.

Değişiklik yerel uygulama veri dosyasındadır (`assets/curated_cosmetics.json`). Bu çalışma yeni APK veya canlı ortam yayını yapmaz.
