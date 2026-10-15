# Navilo — Amaç, yapılan işler, mevcut durum ve eksikler

**Durum tarihi:** 15 Ekim 2026
**Uygulama sürümü:** 0.1.0+1 — geliştirme prototipi
**İnceleme kapsamı:** Mevcut Flutter kodu, gömülü kataloglar, veri doğrulama araçları, testler ve proje raporları. Bu doküman bir mağaza yayını veya telefona kurulum tutanağı değildir.

## 1. Projenin amacı

Navilo, gıda, kozmetik ve kişisel bakım ürünlerinin içeriklerini kullanıcı için anlaşılır hâle getiren bir mobil uygulamadır. Kullanıcı ürünün barkodunu okutur veya içindekiler etiketinin fotoğrafını çeker; uygulama içerik metnini bulur, kontrol ettirir ve tanımlı içerik kurallarıyla karşılaştırır. Sonuçta hangi maddelerin tespit edildiğini, neden dikkat gerektirebildiğini ve bilginin kaynağını gösterir.

Temel ihtiyaç, uzun ve teknik etiketleri okuma yükünü azaltmak ve ürünleri aynı ölçütlerle incelemektir. Ürün kütüphanesi, aynı ürünün her kullanımda yeniden fotoğraflanmasını azaltır. Kullanıcının beslenme tercihleri ve cilt bilgileri kişiselleştirme için temel oluşturur.

Bir madde eşleşmesi, ürünün her kullanıcı için zararlı olduğunu kanıtlamaz. Konsantrasyon, kullanım biçimi ve kişisel hassasiyet gibi bilgiler etikette her zaman bulunmaz. Benzer şekilde hiçbir eşleşme bulunmaması, güvenlik garantisi değildir. Uygulamanın mevcut sonucu “Listemizdeki madde tespit edildi/edilmedi” yaklaşımına dayanır.

## 2. Kullanıcı açısından mevcut akış

1. Kullanıcı gıda veya kozmetik alanını seçer; barkod, kamera, galeri veya metin üzerinden ilerler.
2. Barkod için önce kullanıcının cihazındaki kayıtlar kontrol edilebilir. Ürün deposunda kaynaklı gömülü kayıtlar önceliklidir; yapılandırılmışsa onaylı ortak katalog ve kategoriye uygun Open Facts servisleri de kullanılır.
3. Ürün bulunamaz veya içindekiler eksikse etiket fotoğrafı/metin incelemesi yoluna geçilir. İsimle bulunan aday, kullanıcı seçimi ve ambalaj karşılaştırması gerektirir.
4. Fotoğraf kırpılıp döndürülebilir. Cihazdaki OCR metni okur; kullanıcı yanlışları düzeltir ve içerik listesinin tamamlığını onaylar.
5. Sonuç ekranı eşleşmeleri, kısa açıklamaları, ilgili beslenme değerlendirmelerini ve kaynak/sınırlılık bilgilerini gösterir.
6. Kullanıcı ürünü kişisel kütüphanesine kaydedebilir. Barkodlu kayıtlar ortak kaynak inceleme kuyruğuna gönderilebilir; bağlantı yoksa yerel kuyruk daha sonra yeniden denenir. Mevcut arayüz bu paylaşım davranışını kullanıcıya bildirir. Gönderilen metinler onaylanmadan herkese açık katalog hâline gelmez.

Fotoğraf ve kişisel profil, mevcut metin katkısı mekanizmasının parçası olarak gönderilmez. Bununla birlikte yerel kaydetme ile ortak kaynağa gönderme seçeneklerinin kullanıcı açısından yeterince açık ve ayrı olup olmadığı yayın öncesinde gözden geçirilmelidir.

## 3. Şimdiye kadar yapılan işler

| Alan | Kodda bulunan çalışma | Mevcut sınır |
|---|---|---|
| Mobil temel | Flutter arayüzü, Android ve iOS proje yapıları, Türkçe/İngilizce metinler | İki platformda üretim kabulü bu incelemede doğrulanmadı |
| Ürün yakalama | Barkod okuyucu, kamera/galeri seçimi, kırpma/döndürme, ML Kit OCR | Küçük yazı, parlama, kavisli ambalaj ve eksik etiket için cihaz ölçümü gerekli |
| Metin inceleme | Manuel düzeltme, okuma uyarıları, tamamlık onayı | Kullanıcının onayı bağımsız içerik doğrulaması değildir |
| İçerik değerlendirme | Sürümlü kural sözlüğü, TR/EN eş adlar, kategoriye göre eşleştirme, “içermez” ifadelerini ele alma | Kapsam sınırlı; uzman incelemesi ve zor etiket örnekleri gerekli |
| Kısa açıklamalar | 34 kuralın tamamında Türkçe açıklama; kaynak alanları ve açıklama bileşeni | Açıklamalar doz ve kişisel klinik durumu değerlendirmez |
| Hata düzeltmeleri | Açıklama metadatasında boş değer için güvenli okuma; sonuçtaki Null/String çökmesine yönelik düzeltme | Eski kurulu uygulamanın güncellendiği anlamına gelmez |
| Beslenme bilgisi | Gluten, laktoz ve şeker beyanlarını ayıran değerlendirmeler; kaynaklı referans sözlüğü | Tam besin değeri ve porsiyon tabanlı filtre sistemi yok |
| Cilt profili | Cilt anketi, sonuç saklama ve içerik üzerinden sınırlı cilt uyumu değerlendirmesi | Dermatolojik teşhis veya doğrulanmış kişisel öneri modeli değil |
| Kişisel kütüphane | Cihazda saklama, ad/barkod arama, gıda/kozmetik ayrımı, tekrar çağırma | Hesaplar arası güvenilir senkronizasyon ve yedekleme tamamlanmış sayılmaz |
| Ortak katalog | Supabase istemcisi, katkı gönderimi, çevrimdışı kuyruk, SQL migration ve onay yapısı | Canlı ortam erişim kuralları, kötüye kullanım önleme ve yönetim operasyonu ayrıca doğrulanmalı |
| Katalog güvenilirliği | GTIN kontrolü, kaynak/tarih takibi, doğrulanmamış kayıtları ayırma, çelişkili tekrarları engelleme | Kaynak sayfası fiziksel ambalaj veya laboratuvar doğrulaması değildir |
| Veri araştırması | Gıda, makyaj, güneş koruyucu ve deodorant paketleri için kaynak incelemeleri ve raporlar | Kapsama pazarın tamamını temsil etmez; düzenli güncelleme gerekli |
| Test altyapısı | 30 Dart test dosyası; ek Python doğrulama araçları | Otomatik testler kamera, cihaz ve canlı servis kabulünün yerine geçmez |

## 4. Katalogun güncel büyüklüğü

Bu sayılar 15 Ekim 2026 tarihinde uygulamanın **gömülü JSON dosyalarından** hesaplanmıştır. Kişisel cihaz kayıtları, bekleyen inceleme kayıtları ve canlı Supabase verileri toplama dahil değildir. Sayım birimi barkod kaydıdır; aynı çeşit farklı barkodlarla birden fazla kayıt olabilir.

| Katalog | Kayıt | Kendi dosyası içinde benzersiz barkod |
|---|---:|---:|
| Gıda | 247 | 247 |
| Kozmetik ve kişisel bakım | 543 | 543 |
| Toplam | **790** | Dosya bazında tekrar yok |

| Kaynak türü | Gıda | Kozmetik/kişisel bakım |
|---|---:|---:|
| Üretici | 48 | 479 |
| Perakendeci | 188 | 63 |
| Etiket fotoğrafı | 6 | 1 |
| Open Food Facts | 5 | 0 |

Kaynak türleri, kaydın mevcut metadatasıdır; bu rapor tüm 790 ürünün internet sayfasını yeniden doğrulamamıştır. “Üretici” kaydı da yalnız başına ürünün piyasadaki bütün ambalajlarının aynı formülü taşıdığını göstermez.

### Kategori istatistiklerinde eksik olan bölüm

Gıda kayıtlarının **247'sinde alt kategori alanı yoktur**. Kozmetik kayıtlarında **122 eyeshadow/far**, **64 deodorant** alt kategori değeri bulunur; **357 kayıtta alt kategori alanı yoktur**. Bu nedenle bugün doğrudan alanlardan güvenilir bir “süt kaç, yoğurt kaç, ekmek kaç, peynir kaç” tablosu üretilemez. Ürün adından tahmin edilen kategori ile gözden geçirilmiş kategori ayrı tutulmalıdır.

Yapılması gereken: kategori sözlüğü tanımlamak, kayıtları bu sözlüğe eşlemek, belirsizleri incelemek ve kategori bazında toplam/doğrulanmış/bekleyen/reddedilen sayıları aynı raporda sunmak. Alanı boş ürün, otomatik olarak “diğer” kategorisinde doğrulanmış sayılmamalıdır.

## 5. İçerik kuralları ve açıklamalar

Politika sürümü **0.2.0-draft** olup **16 gıda ve 18 kozmetik olmak üzere 34 kural grubu** içerir. Her grupta Türkçe kısa açıklama bulunur. Bu sayı bütün kimyasal maddelerin veya bütün katkıların kapsandığı anlamına gelmez; bir kural grubu birden fazla eş ad içerebilir.

Kurallar uygulama içinde belirli, tekrar üretilebilir metin eşleştirmeleriyle değerlendirilir. Bu, kaynağı izlenebilir sonuçlar için yararlıdır; OCR hatası, farklı yazım veya eksik eş ad nedeniyle kaçan eşleşmeler hâlâ mümkündür. İçerik, besin tablosu ve pazarlama beyanlarının ayrımı kritik önem taşır.

“Neden dikkat edilmeli?” bölümü her madde için kısa, kaynaklı ve ölçülü olmalıdır. Tercih nedeniyle kaçınılan madde, belirli kişilerde hassasiyet yapabilen madde ve mevzuatla sınırlandırılmış madde aynı gerekçeyle sunulmamalıdır. Uzman/editör onayı, inceleme tarihi ve kaynak değişikliği süreci henüz kurumsal bir yayın mekanizması olarak tamamlanmış değildir.

## 6. Barkod ve formül sorunları neden yaşanıyor?

| Sorun | Anlamı | Doğru yaklaşım |
|---|---|---|
| Kontrol basamağı hatası | Barkodun matematiksel yapısı geçmiyor | Asıl ambalajdan doğrulamak; tahmini son basamak üretmemek |
| Geçerli fakat doğrulanamayan barkod | Matematik doğru, ürün kimliği için kanıt yok | Ürün/gramaj/pazar eşleşmesini ayrıca aramak |
| Ürün var, içerik yok | İsim veya satış kaydı bulunuyor | Başka boy/çeşidin formülünü kopyalamamak |
| Aynı barkodda çelişkili listeler | Kaynaklar farklı içerik bildiriyor | Formül tarihi, pazar ve aynı ambalaj etiketiyle çözmek |
| Eksik veya çevrilmiş içerik | “Parfüm, koruyucu” gibi genel adlar veya standart olmayan çeviri var | Tam özgün içerik/INCI istemek ve kaynağı korumak |
| Çift kayıt | Aynı barkod tekrar ekleniyor | Aynıysa tekrar eklememek; çelişki varsa incelemeye ayırmak |

Önceki konuşmadaki **719 satır / 527 hatalı kontrol basamağı** ifadesi bu raporda güncel katalog istatistiği olarak kullanılmamıştır. Farklı dosyalara ait eski inceleme sayısı, mevcut kabul edilmiş katalog toplamıyla karıştırılmamalıdır.

Son Old Spice incelemesinde 10 eski barkod hâlâ beklemektedir: 2 formül çelişkisi, 3 eksik/güvenilir olmayan tam INCI, 4 doğrulanamayan barkod–ürün eşleşmesi, 1 geçersiz kontrol basamağı. Bearglove sprey 150 ml için farklı, doğrulanmış iki barkod kaydı ayrıca eklenmiştir; eski belirsiz barkoda aktarılmamıştır. Ayrıntılar `OLD_SPICE_DEEP_REVIEW_20261015.md` içindedir.

## 7. Teknik yapı

| Dosya/alan | Görevi |
|---|---|
| `lib/main.dart` | Ana ekranlar, yakalama, metin inceleme, sonuç, kütüphane ve katkı akışları |
| `lib/data/product_repository.dart` | Gömülü/ortak/dış kaynak ürün arama, kaynak ve hata bilgileri |
| `lib/data/local_product_store.dart` | Kişisel kayıtlar ve bekleyen gönderimlerin yerel saklanması |
| `lib/data/community_submission.dart` | Supabase'e metin katkısı gönderimi |
| `lib/data/app_settings.dart` | Cihazdaki uygulama tercihleri |
| `lib/domain/policy.dart` | Kural modeli ve içerik eşleştirmesi |
| `lib/domain/ingredient_text.dart`, `dietary.dart` | İçerik metni ve beslenme değerlendirme yardımcıları |
| `lib/domain/catalogue_provenance.dart`, `barcode.dart` | Kaynak koşulları ve barkod doğrulama |
| `lib/features/skin_test/` | Cilt anketi ve sınırlı içerik uyumu değerlendirmesi |
| `assets/` | Politika, beslenme referansı ve gömülü ürün katalogları |
| `tool/` | Araştırma, denetim ve kaynaklı veri içe aktarma araçları |
| `data/quarantine/` | Kabul edilmeyen veya incelemesi süren veri kayıtları |
| `supabase/migrations/` | Ortak katalog ve katkı veritabanı değişiklikleri |
| `test/`, `docs/` | Otomatik kontroller, araştırma kanıtları ve proje belgeleri |

OCR için Google ML Kit; barkod için mobile_scanner; görsel seçimi/kırpma için image_picker ve image_cropper kullanılır. Yerel ayarlar için shared_preferences, dosya alanı için path_provider bulunur. Supabase erişimi kodda vardır; bağlantı yapılandırmasının bulunması, canlı güvenlik ve yayın kabulünün tamamlandığını kanıtlamaz.

## 8. Eksikler ve öncelik sırası

### P0 — Kullanıcıya güvenilir sonuç verebilmek için

- **Gerçek cihaz kabulü:** Barkod → ürün → metin inceleme → sonuç → kaydetme → tekrar okutma zincirini fiziksel Android cihazda kayda almak. Kamera izni reddi, iptal, düşük ışık, çevrimdışı durum ve uygulamanın kapanıp açılması dahil edilmeli.
- **Formül belirsizliği:** Aynı GTIN için pazar/ambalaj/formül sürümü modeli kurmak. Şu an temel ürün modeli tek içerik metni taşıyor; çelişen sürümler bu yapıyla güvenle birleştirilemiyor.
- **İçerik açıklamalarının editoryal onayı:** 34 kuralın gerekçelerini uzman incelemesi, tarih ve kanıt düzeyiyle yönetmek. Belirsiz bilgiden kesin zarar iddiası üretmemek.
- **Katkı ve gizlilik akışı:** Yerel kayıt ile ortak kaynağa gönderim davranışını netleştirmek; canlı Supabase erişim/onay kurallarını ve kullanıcılar arası veri ayrımını uçtan uca sınamak.

### P1 — Kullanılabilir ve sürdürülebilir bir ilk sürüm için

- **Kategori sistemi:** Gıda ve kozmetik alt kategorilerini tamamlamak; kategori bazında ürün ve yükleme istatistiği oluşturmak.
- **Yönetim paneli:** Bekleyen ürün, kaynak karşılaştırma, kabul/red gerekçesi, formül değişikliği ve geri alma için ekranlar hazırlamak. SQL ve araçların varlığı kullanılabilir bir moderasyon paneli değildir.
- **Veri güncelliği:** Son kontrol tarihi, tekrar inceleme zamanı, bozuk kaynak bağlantıları ve değişen formüller için süreç kurmak.
- **OCR ölçümü:** Türkçe gıda etiketleri ve INCI için sabit test görselleriyle hata oranı ve kritik kaçırmaları ölçmek. Tamamlık onayını okuma doğruluğu ölçümüyle karıştırmamak.
- **Profil entegrasyonu:** Cilt değerlendirmesini kapsamı açıklanmış hâle getirmek; beslenme tercihlerini doğrulanmış ürün özellikleriyle tutarlı filtrelere bağlamak.
- **Kodun ayrıştırılması:** `main.dart` içindeki büyük ekran ve akışları özellik bazında bölmek; veri, arayüz ve değerlendirme sorumluluklarını sadeleştirmek.
- **Dokümantasyon temizliği:** README ve roadmap içinde artık yapılmış işleri hâlâ yapılmamış gösteren bölümleri güncellemek; tek güncel durum belgesini referans almak.

### P2 — Sonraki ürün geliştirmeleri

- Kaynaklı özelliklerle ürün karşılaştırma ve alternatif önerme.
- Açıklanmış ve doğrulanmış bir yöntem olmadan sayısal sağlık/uygunluk puanı yayımlamamak.
- Hesap, yedekleme ve kontrollü cihazlar arası senkronizasyon.
- Porsiyon ve kullanım hakkı doğrulanmış FODMAP verisi; mevcut referans uyarıları kesin FODMAP sınıflaması değildir.
- iOS cihaz kabulü, mağaza kimlikleri, sürümleme, destek ve yayın operasyonu.
- Fiyat/stok gibi dış veriler ancak gerçek entegrasyon ve tarih bilgisiyle sunulmalı.

## 9. Önerilen çalışma planı ve tamamlanma ölçütleri

| Sıra | Teslim edilecek iş | Tamamlandı sayılması için |
|---|---|---|
| 1 | Cihaz kabul raporu | Kritik kullanıcı akışları fiziksel cihazda geçer; hata ve sürüm kaydı tutulur |
| 2 | Kategori sözlüğü ve sayım raporu | 790 kaydın her biri gözden geçirilmiş kategori veya açık inceleme durumuna sahip olur |
| 3 | Belirsiz formül kuyruğu | Her bekleyen kayıtta eksik kanıt, incelenen kaynak ve karar bulunur |
| 4 | Kaynaklı açıklama yayını | Her kuralda gerekçe, kaynak, inceleme tarihi ve onay durumu bulunur |
| 5 | Katkı/moderasyon kabulü | Bekleyen veri halka açılmaz; erişim ve onay yetkileri canlı ortamda sınanır |
| 6 | Pilot sürüm | Belirlenen ürün örnekleminde doğru eşleşme, bulunamama ve OCR başarısı ölçülür |

Takvim ve maliyet bu dokümanda kesinleştirilmemiştir. Önce kabul örneklemi, hedef platformlar ve sorumlu kişiler belirlenmelidir.

## 10. İzlenmesi önerilen ölçümler

- Barkod okutmalarında doğru ürün ve tam içerik bulunma oranı.
- Kategoriye göre kabul edilmiş, bekleyen, reddedilen ve güncelliği geçmiş kayıt sayısı.
- OCR'da kullanıcı düzeltmesi gereken kelime oranı ve kritik madde kaçırma oranı.
- Sabit etiket örnekleminde yanlış pozitif/yanlış negatif kural eşleşmeleri.
- Katkı gönderimi başarı oranı ve moderasyon bekleme süresi.
- Kaynak bağlantısı geçerliliği ve formül çelişkisi sayısı.
- Cihazda çökme oranı ve temel akışın tamamlanma süresi.

Bunlar önerilen göstergelerdir; mevcut projede hepsinin üretim ölçümü toplandığı varsayılmamalıdır.

## 11. Doğrulama ve mevcut durumun yorumu

Bu rapor hazırlanırken katalog sayıları doğrudan JSON dosyalarından, özellikler ise koddan kontrol edildi. Otomatik analiz ve tam test çalışmasının sonucu aşağıdaki doğrulama notunda ayrıca kaydedilir. Canlı servislerin tamamı, fiziksel kamera/OCR, iOS derlemesi veya mağaza yayını bu incelemede doğrulanmadı.

Navilo'nun ürün yakalama, içerik inceleme, kaynaklı sonuç ve yerel kütüphane çekirdeği kodda mevcut. Yayına geçişte ağırlık, daha fazla ürün eklemenin yanında veri doğruluğu, kategori düzeni, formül sürümleri, cihaz kabulü ve ortak katalog yönetimine verilmelidir.

### İlgili proje belgeleri

- `README.md` — genel kurulum ve tarihsel geliştirme notları; bazı durum ifadeleri eskidir.
- `docs/MOBILE_UX_FLOW.md`, `docs/PHOTO_LOCAL_FLOW.md` — ekran ve fotoğraf akışları.
- `docs/ANDROID_TESTING.md` — fiziksel cihaz kontrolleri.
- `docs/ROADMAP.md` — geniş ürün vizyonu; işlerin güncel durumu kodla karşılaştırılmalıdır.
- `docs/SUPABASE_SETUP.md` — ortak katalog altyapısı; tarihsel bölümleri birbiriyle çelişebiliyor.
- `docs/OLD_SPICE_DEEP_REVIEW_20261015.md` — son formül belirsizliği incelemesi.
- `docs/PROCESSED_MEAT_SOURCE_REVIEW_20261015.md` — şarküteri kaynak incelemesi.

### 15 Ekim 2026 otomatik kontrol sonuçları

- **Tam Flutter test çalışması:** 78 test geçti, 2 test başarısız oldu. Testlerin tamamı başarılı değildir.
- **Flormar katalog testi:** `test/flormar_catalog_test.dart:35`, olası pigment alanında `MAY CONTAIN` ifadesini bekliyor; mevcut metin doğrudan CI pigmentleriyle başlıyor. Veri temsilinin ve test beklentisinin birlikte incelenmesi gerekir. Bu hata tek başına ürünün barkodunun veya bütün içeriklerinin yanlış olduğunu göstermez.
- **Katkı gezinme testi:** `test/contribution_navigation_test.dart`, “Centered navigation, nested criteria and editable contribution” senaryosu başarısız. Tek başına yeniden çalıştırıldığında da 52. satırda `Bad state: No element` oluştu; test beklediği widget'ı bulamıyor. Yayın öncesi kullanıcı akışı ve test beklentisi karşılaştırılmalı.
- **Flutter analyze:** 1 bilgi düzeyi biçim uyarısı; `lib/data/local_product_store.dart:150` içindeki `if` ifadesinin süslü parantez içine alınması isteniyor. Komut sıfırdan farklı çıkış kodu verdi; “analiz tamamen temiz” olarak raporlanamaz.
- Bu dokümantasyon çalışmasında uygulama kodu veya test beklentileri değiştirilmedi. Bulgular mevcut durumun parçası olarak kaydedildi.
