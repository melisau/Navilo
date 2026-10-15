# Salam, sosis ve sucuk kaynak incelemesi — 15 Ekim 2026

Kullanıcının gönderdiği 10 barkodun tamamı GTIN kontrol basamağından geçti. Bu kontrol ürün veya formül doğrulaması olarak kullanılmadı. Dört yeni kayıt aynı ürün/gramajın tam içerik listesi ve ayrı GTIN kanıtıyla eklendi; bir kayıt zaten vardı; beş kayıt eksik etiket kanıtı nedeniyle bekletildi.

## Eklenen kayıtlar

| Barkod | Ürün | Tam içerik kaynağı | Barkod kaynağı |
| --- | --- | --- | --- |
| 8697471724614 | Namet Dana Kokteyl Sosis 250 g | [Gıda Sepetim](https://www.gidasepetim.com.tr/products/namet-sosis-dana-kokteyl-250-gr) | [Gürmar](https://www.gurmar.com.tr/namet-kokteyl-dana-sosis-250-gr-14810-p) |
| 8697471722818 | Namet Hindi Uzun Sosis 210 g | [Tarım Kredi Koop](https://www.tkkoop.com.tr/urun/namet-hindi-uzun-sosis-5-li-210-g) | [Barış Gross](https://barisgrossonlinemagaza.com/zqnamet-hindi-uzun-sosis-210-gr-27715-p) |
| 8697471720197 | Maret Afiyetle Isıl İşlem Görmüş Dana Sucuk 200 g | [Migros](https://www.migros.com.tr/maret-dana-isil-islem-gormus-afiyetle-sucuk-200-g-p-d8ad5d) | [Asya Market](https://www.asyasanalmarket.com/maret-afiyetle-dana-sucuk-200-gr-112-35220) |
| 8690527020890 | Pınar Aç Bitir Dana Sucuk 75 g | [CarrefourSA](https://www.carrefoursa.com/pinar-dana-sucuk-ac-bitir-75-g-p-30475525) | [Memleket Gurmesi](https://www.memleketgurmesi.com.tr/p%C4%B1nar-a%C3%A7-bitir-dana-sucuk-75-gr-9539) |

Tam metinler, alerjenler, tarih ve alan bazında kaynaklar [`reviewed_new.json`](catalog_analysis/processed_meat_20261015/reviewed_new.json) ve uygulamanın `assets/curated_products.json` dosyasında tutulur. Kaynakta bildirilmiş süt ve soya alerjenleri Namet sosislerine işlendi. Boş alerjen/iz dizileri alerjensizlik iddiası değildir. Glutensiz, laktozsuz, şekersiz veya FODMAP iddiası türetilmedi. Fiziksel ambalajlar bu incelemede görülmedi.

Namet 250 g için eski Migros URL’si artık **Maret Dana Kokteyl Sosis 250 g** başlığı döndürdüğünden Namet içeriğine kanıt olarak kullanılmadı. Gıda Sepetim’in aynı Namet 250 g ürünü için yayımladığı metin kullanıldı; kelime içinde bölünmüş “renklendi rici” boşluğu ve noktalama düzenlendi. Kaynakta yer alan ambalajlama gazı bilgisi korundu.

## Zaten katalogda olan kayıt

`8690527010938` — Pınar Aç Bitir Macar Salam 60 g. Mevcut perakendeci kaynaklı içerik kaydı korunarak ikinci kayıt oluşturulmadı. Bu incelemede tarih veya formül yenilenmedi. OFF aynı GTIN için 50 g bildiriyor ve içeriği boş; bu kayıt mevcut 60 g formülün yerine geçirilmedi.

## Bekleyen kayıtlar

| Barkod | Ürün | Eksik bilgi |
| --- | --- | --- |
| 8697434840481 | Şahin Macar Salam 250 g | GTIN/gramaj var; üretici 250 g sayfasında tam içerik listesi yok. 900 g formülü kullanılmadı. |
| 8697471722856 | Namet Dana Uzun Sosis 210 g | GTIN/gramaj var; bulunan kg ve 240 g içerikleri 210 g ürünün yerine aktarılmadı. |
| 8690527030578 | Pınar Aç Bitir Hindi Kokteyl Sosis 170 g | A101 içerik metni katkı maddelerini adsız bırakıyor; tam etiket doğrulanamadı. 180 g formülü kopyalanmadı. |
| 8690527031094 | Pınar Yörük Büfe Sosis 430 g | GTIN/gramaj var, tam içerik yok; hindi ve hindi/piliç adlarıyla karşılaşıldı. |
| 8697471721521 | Maret Dana Kangal Sucuk 500 g | OFF yanıtında 500 g var; ürün adı ve içerik alanı boş. |

Bekleyen ürünlerin baktığımız kaynakları ve gerekçeleri [`pending.json`](catalog_analysis/processed_meat_20261015/pending.json), OFF alan kontrolleri [`off_checks.json`](catalog_analysis/processed_meat_20261015/off_checks.json) içinde. Bunlar aktif içerik kataloğuna alınmadı.

## Kontroller

- Standart gözden geçirilmiş kayıt içe aktarıcısı: **4 eklendi, 0 reddedildi**.
- Bu içe aktarma adımında gömülü gıda kataloğu **208 → 212** kayıt oldu; diğer katalog paketleri toplam sayıyı ayrıca artırabilir.
- `flutter test test/turkey_catalog_test.dart --reporter expanded`: **4 test geçti**; barkod geçerliliği, benzersizlik, kaynak metadatası ve mevcut çevrimdışı çözümleme kapsamı kontrol edildi.
