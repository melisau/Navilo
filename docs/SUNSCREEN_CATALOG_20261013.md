# Güneş koruyucu kataloğu — 13 Ekim 2026

Gönderilen 50 kaydın 40 barkodu EAN-13 kontrol basamağını geçmiyor. Kalan 10 barkod için yapılan birebir web aramalarında ürün kaynağı bulunamadı. Bu 50 kayıt uygulama kataloğuna doğrudan aktarılmadı. Gönderilen liste `docs/sunscreens/submitted.txt`, kayıt bazında durumlar `submitted_audit.json` içinde tutulur. Eksik kontrol basamağı otomatik değiştirilerek yeni barkod üretilmedi.

Ürün adlarından hareketle resmi Maruderm, The Purest Solutions ve COSRX sayfaları araştırıldı. Aynı sayfa/ürünün resmi mağaza JSON verisindeki barkod ile tam INCI metni eşleşen 18 kayıt eklendi: 11 Maruderm, 6 The Purest Solutions, 1 COSRX. Kozmetik kataloğu 298'den 316 ürüne çıktı. Yeni kayıtlar gönderilen barkodların takma eşleşmesi değildir; doğrulanan kendi barkodlarıyla aranır.

Örnekler:

- COSRX Aloe Soothing Sun Cream SPF50+/PA+++ 50 ml: `8809416470191`.
- The Purest Solutions Invisible SPF50 50 ml: `8682773091335`.
- Maruderm Leke Karşıtı SPF50+ 50 ml: `8682397031205`.
- The Purest Solutions Mineral SPF30 40 ml: `8684083321423`. Gönderilen SPF50+ olarak kaydedilmedi.

INCI sırası ve metni kaynakta olduğu gibi korundu. `But friendship Extract`, `Ecocert Ingredients`, `Herbal Complex B19` gibi gönderilen metindeki belirsiz/hatalı bileşenler başka formüllere taşınmadı. Mineral/hibrit etiketleri, bebek veya hassas cilde uygunluk, SPF test sonuçları ve güvenlik iddiaları uygulama tarafından türetilmedi.

Kaynak verileri: `docs/sunscreens/manufacturer_evidence.json`. Bu dosyada resmi ürün sayfaları, barkod metadata'sı ve içerik kanıtı bulunur. Araştırma tarihi ambalaj doğrulaması veya üretici formül güncelleme tarihi değildir.

Kaynaklar:

- https://b2c.cosrx.com/products/aloe-soothing-sun-cream-spf50-pa
- https://thepurestsolutions.com/collections/gunes-kremi
- https://www.maruderm.com/gunes-bakim-urunleri

Tekrar toplama: `python tool/import_sunscreens.py` (requests, beautifulsoup4). Mevcut diğer kozmetik markalarını korur. Aynı barkoda farklı içerik çıkarsa işlem durur.
