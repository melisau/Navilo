# Bütünleşik doğrulama — 13 Ekim 2026

İki agent analiz ve onarım sonuçlarını doğrudan paylaşarak çalıştı. Analiz aracı yalnızca bu çalışma sırasında yenilendi; zamanlanmış otomasyon oluşturulmadı.

- Güncel katalog: 150 gıda, 341 kozmetik.
- Bu turda eklenen: 58 gıda (önceki onarımda 8; genişleme batchinde 50); başlangıçtaki 92 kayıt korundu.
- `flutter analyze`: sorun yok.
- `flutter test`: bütünleşik doğrulamada 59 test geçti; bu turdaki yeni 50 ürün için özel çevrimdışı tam içerik/barkod testi de geçti.
- `flutter analyze`: genişleme testi eklendikten sonra yeniden çalıştırıldı; gereksiz null assertion temizlendi.
- `python -m unittest tool.test_catalog_validation -v`: 7 test geçti.
- `tool/build_android.ps1`: debug APK üretildi.
- APK içindeki katalog dosyaları çalışma alanındaki kataloglarla byte düzeyinde karşılaştırıldı. Sonuç ve APK SHA-256 değeri `validation.json` içinde.

## Çözülen teknik engeller

GTIN-8/12/13/14 kontrolü hem Python içe aktarma araçlarında hem Dart katalog doğrulamasında destekleniyor. Kaynakla doğrulanan Eti Puf'un 8 haneli kodu 13 haneye çevrilmedi. Yinelenen GTIN'ler farklı ürünleri sessizce ezemiyor; geçersiz alanlar ve kategori uyuşmazlıkları `ProductRepository.curatedDataIssues` ile raporlanıyor. Başka geçerli kayıtlar hatalı tek satır yüzünden kaybolmuyor.

Python araçlarının paket/modül importları, cache klasörü oluşturulması, sağlayıcı yanıt şeması ve istenen barkodla dönen kimliğin kontrolü düzeltildi. HTTP 429, ürün yok olarak önbelleğe alınmıyor; hız sınırı durumunda sorgulama duruyor ve bekleme bilgisi tutuluyor.

Android Gradle derlemesindeki `Unable to establish loopback connection` hatasının yığını JBR 25 selector'ünün geçici Unix-domain soketi bağlantısına işaret etti. Proje içindeki `build/socket-tmp` dizinini `jdk.net.unixdomain.tmpdir` olarak kullanınca Gradle ve APK derlemesi başarıyla tamamlandı. `tool/build_android.ps1` bu ayarı yalnızca kendi işlemi sırasında uygular ve önceki ortam değerini geri yükler; sistemin kalıcı Java ayarları değiştirilmez.

## Dağıtım durumu

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Fiziksel telefon bağlı olmadığından telefona kurulmadı. Bu bir test paketidir; mağaza yayını yapılmadı.

## Kalan veri sorunları

Tam liste ve kayıt bazında nedenler `REPORT.md`, `pending.csv`, `report.json` dosyalarında. Kaynak bulunmaması, eksik tam etiket, çelişen formül ve yanlış varyant sorunları teknik GTIN düzeltmesiyle çözülmüş sayılmıyor. Türkiye pazarının tamamı için eksiksiz katalog iddiası yoktur.
