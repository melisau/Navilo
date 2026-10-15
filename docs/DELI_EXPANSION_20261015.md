# Şarküteri kataloğu genişletmesi — 15 Ekim 2026

Bu paket **10 yeni ürün** ekledi: 4 sucuk, 3 salam, 3 sosis. Mevcut kayıtlar değiştirilmedi. Aynı barkod/ürün/gramaj için tam içerik metni ve alan bazında kaynaklar kaydedildi.

| Barkod | Ürün | İçerik kanıtı | Barkod kanıtı |
| --- | --- | --- | --- |
| 8681594301548 | Beşler Gold Kangal Sucuk 300 g | [Kaynak](https://www.sariyermarket.com/besler-gold-kangal-sucuk-300-gr) | [GTIN](https://www.sariyermarket.com/besler-gold-kangal-sucuk-300-gr) |
| 8693407004157 | Polonez Dana Kasap Sucuk 250 g | [Kaynak](https://www.sariyermarket.com/polonez-dana-kasap-sucuk-250-gr) | [GTIN](https://www.sariyermarket.com/polonez-dana-kasap-sucuk-250-gr) |
| 8693407002795 | Polonez Dana Sucuk 240 g | [Kaynak](https://www.sariyermarket.com/polonez-dana-sucuk-240-gr) | [GTIN](https://www.sariyermarket.com/polonez-dana-sucuk-240-gr) |
| 8693407004560 | Polonez Hindi Kokteyl Sosis 220 g | [Kaynak](https://www.sariyermarket.com/polonez-hindi-kokteyl-sosis-220-gr) | [GTIN](https://www.sariyermarket.com/polonez-hindi-kokteyl-sosis-220-gr) |
| 8690527030882 | Pınar Hindi Uzun Sosis 430 g | [Kaynak](https://www.sariyermarket.com/pinar-hindi-uzun-sosis-430-gr) | [GTIN](https://www.sariyermarket.com/pinar-hindi-uzun-sosis-430-gr) |
| 8697420920296 | Apikoğlu Dana Parmak Sucuk 200 g | [Kaynak](https://www.apikoglu.com.tr/dana-parmak-sucuk-200-gr) | [GTIN](https://www.sariyermarket.com/apikoglu-parmak-sucuk-200-gr) |
| 8690527011621 | Pınar Aç Bitir Hindi Fıstıklı Salam 50 g | [Kaynak](https://www.migros.com.tr/hemen/pinar-salam-ac-bitir-hindi-fistikli-salam-50-g-p-d72646) | [GTIN](https://www.sariyermarket.com/pinar-salam-ac-bitir-hindi-fistikli-salam-50-gr) |
| 8697471726373 | Maret Pratik Dana Macar Salam 50 g | [Kaynak](https://www.migros.com.tr/hemen/maret-pratik-dana-macar-salam-50-g-p-d74a5b) | [GTIN](https://www.sariyermarket.com/maret-pratik-dana-macar-salam-50-gr) |
| 8697471725642 | Maret Pratik Hindi Salam 60 g | [Kaynak](https://www.migros.com.tr/hemen/maret-pratik-hindi-salam-60-g-p-d74a26) | [GTIN](https://barisgrossonlinemagaza.com/maret-pratik-hindi-salam-60-gr-12800-p) |
| 8690527030028 | Pınar Dana Kokteyl Sosis 215 g | [Kaynak](https://www.migros.com.tr/hemen/pinar-kokteyl-sosis-215-g-p-d5c6f8) | [GTIN](https://www.gurmar.com.tr/pinar-kokteyl-sosis-215-gr-1220-p) |

Tam metinler, alerjenler ve kontrol tarihi [`reviewed_new.json`](catalog_analysis/deli_expansion_20261015/reviewed_new.json) ve `assets/curated_products.json` içinde.

Apikoğlu 200 g için üretici metni önceliklendirildi: üreticinin E250 bildirimini içermeyen perakendeci metni tam içerik olarak kullanılmadı. Polonez Kasap 250 g kaynağının yazım hataları yorumla değiştirilmedi. Polonez Hindi Kokteyl 220 g içindeki bitkisel proteinin türü belirtilmediğinden soya olarak tahmin edilmedi. Pınar fıstıklı salamın buğday lifi, süt, soya ve Antep fıstığı içerikleri kayda işlendi.

Fiziksel ambalaj görülmedi. İçerik listelerinden glutensiz/laktozsuz/şekersiz veya FODMAP sertifikası türetilmedi. Boş alerjen ve iz dizileri alerjensizlik garantisi değildir.

## Bekleyen adaylar

Namet 7/24 Dana Macar Salam 60 g için kaynaklar antioksidan konusunda E301/E316 şeklinde çelişiyor. Apikoğlu Kangal 280 g ve Polonez Piliç Jumbo 320 g metinleri eksik; Namet Macar 150 g içeriği boş. Bu dört ürün aktif kataloğa alınmadı; [gerekçeler ve kaynaklar](catalog_analysis/deli_expansion_20261015/pending.json) korundu.

Sarıyer Market doğrudan erişimde bazı sayfalara HTTP 429 döndürdü; bu istekler tekrar edilmedi. İlgili ürünlerin daha önce elde edilen arama indeksindeki GTIN kanıtları, Migros ve üretici içerik sayfalarıyla çapraz kontrol edildi. Ham arama çıktısı yerine yalnızca ilgili ürün alanları saklandı.

## Doğrulama

- Standart içe aktarıcı: 10 eklendi, 0 reddedildi.
- On yeni kaydın katalogdaki metin ve kaynakları gözden geçirilmiş giriş dosyasıyla birebir karşılaştırıldı; barkodlar benzersiz ve geçerli.
- `flutter test test/turkey_catalog_test.dart --reporter expanded`: 4 test geçti.
