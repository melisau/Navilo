# Son gönderilen 150 şarküteri kaydı — hata ve eksik incelemesi

13 Ekim 2026. Kapsam: ilk gönderimdeki 1–50 ve son gönderimdeki 51–150. Bunlar 150 gönderim satırıdır; 150 yeni ürünün uygulamaya eklendiği anlamına gelmez. Bu işlem katalog verisini değiştirmez.

**Kesin bulgu: 116/150 satırda (%77,3) barkod kontrol basamağı hatalı.** İlk 50 satırda 40; son 100 satırda 76. Kalan 34 satırda barkod matematiksel kontrolü geçer; bu kontrol gerçek ürün kimliği veya içerik doğrulaması değildir. Bir barkodun son rakamını hesaplayıp değiştirmek, o numarayı ürüne ait doğrulanmış barkod yapmaz.

**Gönderilen 150 içerik metninin hiçbirinde doğrudan etiket kaynağı, etiket fotoğrafı veya kaynak tarihi bulunmuyor.** Bu, içeriklerin hepsinin yanlış olduğunun kanıtı değildir; “resmî ambalaj içeriği” diye kabul etmek için kanıtın eksik olduğu anlamına gelir. Önceki işlemde 2. satır bağımsız kaynaklardan düzeltildi; 31. satırdaki ürün zaten katalogdaydı.

Ek bulgular (bir satır birden fazla grupta olabilir; sayılar toplanmamalıdır):

- 32 ve 126: aynı barkod ve ürünün tekrar gönderimi. 150 satırda 149 farklı barkod bulunur.
- 11 satırda gramaj eksik: 5, 9, 10, 11, 14, 36, 39, 40, 47, 48, 72. Genel içerik değerlendirmesinde engel değildir; yalnızca miktara göre FODMAP sonucu için ek kanıt gerekir.
- 15 satırda katkı maddesi ismi/E kodu yerine yalnızca “emülgatör”, “stabilizatör”, “antioksidan” gibi işlev yazıyor: 26, 41, 42, 93, 107, 108, 109, 114, 118, 119, 129, 134, 136, 139, 142. Bu, mevzuat ihlali tespiti değil; uygulamanın bileşen değerlendirmesi için yetersiz ayrıntı tespitidir.
- 64 ve 143: karışık şarküteri paketinin bileşen ürünleri için tam alt içerik ayrı verilmemiş.
- 10 ve 79: “dekstroz”; 97: “süt proteini”; 115: “muskat” olarak kullanıcı isteğiyle düzeltildi. Özgün metinler korunur.
- 12 satırda içindekiler alanına proses/ambalaj açıklaması veya ayrı bir iddia karışmış: 38, 56, 60, 61, 63, 70, 81, 86, 101, 115, 120, 144. Örneğin “katkı maddesi içermeyen”, “nişasta ve glukoz içermez”, “gaz paketleme” bir bileşen adı değildir; kaynakla teyit edilerek ayrı alanda tutulmalıdır.

Somut kaynak karşılaştırmaları:

- **2 — Pınar Klasik Dana Kangal Sucuk 225 g:** gönderilen `8690526032415` geçersiz. [Asya Market](https://www.asyasanalmarket.com/pinar-225-gr-sucuk--klasik--fermente--18988) aynı ürünün barkodunu `8690527021149` olarak veriyor. [CarrefourSA etiket alanı](https://www.carrefoursa.com/pinar-klasik-sucuk-225-g-p-30123642) askorbik asit bildiriyor; gönderilen metin sodyum askorbat yazıyor. Bu farklı bileşen adı olduğundan gönderim aynen alınmadı; doğrulanan kayıt eklendi.
- **31 — Pınar Aç Bitir Macar Salam 60 g:** gönderilen `8690526012110` geçersiz. Katalogdaki kaynaklı kayıt `8690527010938`. Gönderilen metin, mevcut kaynak metnindeki soya proteini, ayçiçek yağı ve diğer bazı bileşenleri taşımıyor. Mevcut kayıt korundu. Bu fark aynı ambalajın incelendiğini kanıtlamaz; yeniden etiket teyidi gerektirir.
- **51 — Pınar İllaki Dana Kasap Sucuk 240 g:** barkod geçersiz. [Resmî mağazada 240 g ürün “İllaki Dana Sucuk”](https://www.pinaronline.com/urun/pinar-illaki-dana-sucuk-240-g-152903096) olarak geçiyor. “Kasap” çeşidi ile karışmış olabileceğinden ad–gramaj eşleşmesi teyit bekler; yalnızca bu bulguyla kesin olarak ürünün mevcut olmadığı söylenmez.

Barkod kontrolünü geçen 34 satır:

3, 4, 5, 6, 12, 18, 19, 27, 46, 49, 54, 55, 56, 57, 58, 59, 60, 61, 62, 64, 65, 83, 84, 85, 95, 98, 99, 110, 111, 116, 121, 125, 141, 148.

## Kullanıcının son talebine göre güncelleme

10 ve 79: “deksitroz” → “dekstroz”; 97: “süt proteni” → “süt proteini”; 115: “hindistan cevizi cevizi (muskat)” → “muskat”. Özgün metinler ve değişiklik geçmişi karantinada saklandı. Bu düzeltmeler kayıtların doğrulandığı veya yayımlandığı anlamına gelmez.

Gramaj eksikliği/farklılığı, genel içerik değerlendirmesinde tek başına ret nedeni değildir. Farklı ambalajlarda içerik metni gerçekten aynıysa aynı madde kuralları uygulanır. FODMAP için ayrıca kaynaklı gram/porsiyon aralıkları gerekir. Düşük bir miktar bilgisinden hareketle daha yüksek tüm miktarların otomatik olarak yüksek olduğu varsayılmaz; yalnızca kaynakta doğrulanan aralıklar kullanılabilir. Son 150 kayıt hâlâ tamamen karantinadadır; daha önce düzeltilerek eklenen 2. satır da kullanıcının sonraki talebiyle geri çekilmiştir.

## Satır bazında bütün ürünler

Her satırın tam adı, gönderilen barkodu ve bulunan sorunlar aşağıdadır. “Kaynak yok” ifadesi gönderilen metne ilişkindir; internet üzerinde hiçbir kaynak olmadığı iddiası değildir.

| No | Ürün | Gönderilen barkod | Barkod kontrolü | Bulgular |
|---:|---|---|---|---|
| 1 | Pınar İllaki Dana Fermente Sucuk (220g) | `8690526006768` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 2 | Pınar Klasik Dana Kangal Sucuk (225g) | `8690526032415` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Önceki işlemde 8690527021149 ile düzeltilmişti; kullanıcının sonraki talebiyle geri çekildi, karantinada |
| 3 | Namet Klasik Dana Fermente Sucuk (225g) | `8690623223010` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 4 | Namet Isıl İşlem Görmüş Dana Sucuk (240g) | `8690623120159` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 5 | Şahin Kayseri Geleneksel Fermente Sucuk | `8691536001016` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 6 | Şahin Altın Seri Dana Fermente Sucuk (200g) | `8691536001153` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 7 | Cumhuriyet Afyon Geleneksel Sucuk (225g) | `8690743001027` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 8 | Torku Doğal Dana Fermente Sucuk (225g) | `8690123021128` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 9 | Torku Pratiko Isıl İşlem Görmüş Sucuk | `8690123004114` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 10 | Polonez Geleneksel Dana Fermente Sucuk | `8690632001145` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir; Kullanıcının isteğiyle yazım düzeltildi; özgün metin saklandı; kaynak doğrulaması yapılmış sayılmaz |
| 11 | Coşkun Geleneksel Dana Fermente Sucuk | `8690765001111` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 12 | Aytaç Klasik Dana Fermente Sucuk (220g) | `8690841001124` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 13 | Maret Pratik Isıl İşlem Görmüş Sucuk (200g) | `8690504141115` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 14 | Danet Afyon Geleneksel Fermente Sucuk | `8693214002153` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 15 | Erpiliç Piliç Isıl İşlem Görmüş Sucuk (200g) | `8690754211125` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 16 | Pınar Uzun Dana Sosis (430g) | `8690526011434` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 17 | Pınar Kokteyl Dana Sosis (200g) | `8690526011403` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 18 | Namet Dana Kokteyl Sosis (300g) | `8690623141017` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 19 | Namet Pratik Dilimli Dana Sosis (200g) | `8690623141154` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 20 | Polonez %100 Dana Kasap Sosis (300g) | `8690632001855` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 21 | Torku Doğal Dana Uzun Sosis (300g) | `8690123014113` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 22 | Maret Büfe Tipi Dana Uzun Sosis (400g) | `8690504141153` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 23 | Banvit Piliç Kokteyl Sosis (400g) | `8693240003308` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 24 | Banvit Piliç Uzun Sosis (380g) | `8693240003353` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 25 | Erpiliç Piliç Kokteyl Sosis (400g) | `8690754111227` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 26 | Erpiliç Piliç Uzun Sosis (380g) | `8690754111357` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 27 | Aytaç Klasik Dana Uzun Sosis (300g) | `8690841002152` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 28 | Coşkun Geleneksel Dana Sosis (250g) | `8690765002156` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 29 | Danet Dana Uzun Sosis (300g) | `8693214003112` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 30 | Maret Büfe Tipi Piliç Sosis (430g) | `8690504141207` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 31 | Pınar Aç Bitir Dana Macar Salam (60g) | `8690526012110` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Aynı ürün katalogda 8690527010938 ile mevcut; gönderilen metinde mevcut kaynakta bulunan soya proteini gibi bileşenler eksik |
| 32 | Pınar Aç Bitir Dana Fıstıklı Salam (50g) | `8690526012158` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; 32 ve 126 aynı ürün adı/barkoduyla tekrar edilmiş; iki ayrı ürün sayılmaz |
| 33 | Pınar Klasik Dilimli Dana Salam (150g) | `8690526012301` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 34 | Namet Gurme Dana Macar Salam (150g) | `8690623151011` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 35 | Namet Pratik Dana Macar Salam (60g) | `8690623151158` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 36 | Polonez Dilimli Hindi Füme Göğüs Eti | `8690632002111` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 37 | Polonez Dana Füme Et (100g) | `8690632002159` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 38 | Polonez Fit Yağsız Hindi Füme (60g) | `8690632002227` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 39 | Torku Pratiko Dilimli Dana Macar Salam | `8690123015127` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 40 | Maret Pratik Dilim Dana Macar Salam | `8690504141306` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 41 | Banvit Piliç Dilimli Macar Salam (60g) | `8693240003407` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 42 | Banvit Piliç Büfe Salam (750g) | `8693240003452` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 43 | Erpiliç Piliç Dilimli Macar Salam (60g) | `8690754311122` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 44 | Erpiliç Piliç Büfe Salam (800g) | `8690754311252` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 45 | Danet Blok Dana Macar Salam (200g) | `8693214004119` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 46 | Şahin Dana Blok Macar Salam (250g) | `8691536002112` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 47 | Cumhuriyet Blok Dana Macar Salam | `8690743002154` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 48 | Coşkun Geleneksel Dana Macar Salam | `8690765003115` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 49 | Aytaç Dilimli Dana Macar Salam (75g) | `8690841003159` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 50 | Namet Gurme Dana Füme Kaburga (100g) | `8690623151400` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 51 | Pınar İllaki Dana Kasap Sucuk (240g) | `8690526006782` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Ürün adı/gramaj şüphesi: resmî mağazada İllaki Dana Sucuk 240 g ve İllaki Dana Kasap Sucuk 300 g ayrı ürünler; 240 g “Kasap” eşleşmesi teyit edilmeli |
| 52 | Pınar İllaki Dana Kasap Köfte (290g) | `8690526008120` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 53 | Pınar Klasik Dilimli Dana Sucuk (150g) | `8690526032507` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 54 | Namet Gurme Geleneksel Dana Kangal Sucuk (200g) | `8690623223126` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 55 | Namet Isıl İşlem Görmüş Dana Parmak Sucuk (240g) | `8690623120227` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 56 | Namet Klasik Dana Kavurma (150g) | `8690623190114` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 57 | Namet Gurme Çemenli Dilimli Dana Pastırma (100g) | `8690623210119` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 58 | Şahin Evlik Tipi Geleneksel Dana Fermente Sucuk (400g) | `8691536001054` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 59 | Şahin Çemenli Dilimli Dana Pastırma (100g) | `8691536002013` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 60 | Şahin Çemensiz Dilimli Dana Pastırma (100g) | `8691536002051` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 61 | Şahin Hazır Dilimli Dana Kavurma (150g) | `8691536003010` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 62 | Şahin Dana Parmak Sucuk (220g) | `8691536001221` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 63 | Pınar İllaki Dana Kasap Burger (320g) | `8690526008151` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 64 | Namet Karışık Gurme Şarküteri Paketi (120g) | `8690623250115` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Karışık pakette her bileşen ürünün tam alt içeriği ayrı verilmemiş; tam etiket kabul edilemez |
| 65 | Şahin Gurme Çemensiz Blok Pastırma (200g) | `8691536002105` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 66 | Cumhuriyet Geleneksel Dana Parmak Sucuk (200g) | `8690743001058` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 67 | Cumhuriyet Dilimli Dana Fermente Sucuk (150g) | `8690743001157` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 68 | Cumhuriyet Afyon Evlik Tipi Dana Sucuk (400g) | `8690743001201` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 69 | Cumhuriyet Çemenli Afyon Pastırması (100g) | `8690743003014` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 70 | Torku Doğal Dana Kavurma (150g) | `8690123021159` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 71 | Torku Doğal Dilimli Dana Pastırma (100g) | `8690123021203` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 72 | Torku Pratiko Isıl İşlem Görmüş Dana Parmak Sucuk | `8690123004152` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Gramaj belirtilmemiş: genel içerik değerlendirmesine engel değil; FODMAP için gram/porsiyon kanıtı gerekir |
| 73 | Polonez Isıl İşlem Görmüş Dana Sucuk (200g) | `8690632001206` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 74 | Polonez Dana Mangal Tipi Sucuk (350g) | `8690632001350` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 75 | Polonez Karabiberli Dana Füme Et (100g) | `8690632002204` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 76 | Polonez Gurme Dana Füme Kaburga (100g) | `8690632002303` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 77 | Cumhuriyet Dana Sac Kavurma (150g) | `8690743001355` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 78 | Torku Doğal Dana Kasap Sucuk (240g) | `8690123021258` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 79 | Coşkun Klasik Dana Parmak Sucuk (220g) | `8690765001159` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Kullanıcının isteğiyle yazım düzeltildi; özgün metin saklandı; kaynak doğrulaması yapılmış sayılmaz |
| 80 | Coşkun Dilimli Dana Fermente Sucuk (150g) | `8690765001227` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 81 | Coşkun Blok Dana Kavurma (200g) | `8690765003153` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 82 | Coşkun Çemenli Geleneksel Pastırma (100g) | `8690765004112` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 83 | Aytaç Isıl İşlem Görmüş Dana Sucuk (200g) | `8690841001254` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 84 | Aytaç Klasik Dana Kavurma (150g) | `8690841003012` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 85 | Aytaç Dana Parmak Sucuk (220g) | `8690841001308` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 86 | Maret Pratik Dilim Dana Kavurma (100g) | `8690504141351` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 87 | Danet Geleneksel Dana Parmak Sucuk (220g) | `8693214002221` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 88 | Danet Dilimli Dana Pastırma (100g) | `8693214002504` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 89 | Danet Dana Blok Kavurma (150g) | `8693214002603` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 90 | Danet Isıl İşlem Görmüş Dana Sucuk (200g) | `8693214002115` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 91 | Danet Dana Evlik Sucuk (400g) | `8693214002184` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 92 | Erpiliç Piliç Parmak Sucuk (220g) | `8690754211255` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 93 | Erpiliç Göynük Tipi Piliç Sucuk (300g) | `8690754211309` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 94 | Coşkun Mangal Tipi Dana Sucuk (350g) | `8690765001357` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 95 | Aytaç Klasik Çemenli Pastırma (100g) | `8690841003111` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 96 | Pınar Büfe Dana Sosis (400g) | `8690526011458` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 97 | Pınar Aç Bitir Dana Sosis (140g) | `8690526011502` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Kullanıcının isteğiyle yazım düzeltildi; özgün metin saklandı; kaynak doğrulaması yapılmış sayılmaz |
| 98 | Namet Dana Uzun Sosis (360g) | `8690623141208` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 99 | Namet Gurme Dana Sosis Cheddarlı (250g) | `8690623141352` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 100 | Polonez Dana Kokteyl Sosis (250g) | `8690632001909` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 101 | Polonez Gurme Dana Sosis Soyulmuş (200g) | `8690632001954` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 102 | Torku Dana Kokteyl Sosis (250g) | `8690123014151` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 103 | Torku Pratiko Piliç Kokteyl Sosis (400g) | `8690123004206` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 104 | Maret Dana Kokteyl Sosis (250g) | `8690504141405` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 105 | Maret Büfe Tipi Piliç Kokteyl Sosis (430g) | `8690504141450` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 106 | Banvit Piliç Kokteyl Sosis Mini (200g) | `8693240003322` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 107 | Banvit Piliç Sosis (Mangal Tipi - 500g) | `8693240003384` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 108 | Erpiliç Piliç Finger Sosis (250g) | `8690754111401` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 109 | Erpiliç Piliç Sosis (Mangal Tipi - 450g) | `8690754111555` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 110 | Aytaç Dana Kokteyl Sosis (250g) | `8690841002206` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 111 | Aytaç Piliç Kokteyl Sosis (400g) | `8690841002350` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 112 | Coşkun Geleneksel Dana Kokteyl Sosis (200g) | `8690765002200` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 113 | Danet Dana Kokteyl Sosis (250g) | `8693214003150` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 114 | Maret Akdeniz Baharatlı Dana Sosis (250g) | `8690504141504` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 115 | Pınar İllaki Gurme Dana Sosis (300g) | `8690526011557` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış; Kullanıcının isteğiyle yazım düzeltildi; özgün metin saklandı; kaynak doğrulaması yapılmış sayılmaz |
| 116 | Namet Piliç Kokteyl Sosis (400g) | `8690623141505` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 117 | Polonez Hindi Kokteyl Sosis (250g) | `8690632001985` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 118 | Banvit Piliç Tombik Sosis (150g) | `8693240003421` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 119 | Erpiliç Piliç Cocktail Sosis Mini (200g) | `8690754111456` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 120 | Torku Doğal Dana İnce Spagetti Sosis (240g) | `8690123014205` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 121 | Aytaç Dana Tombik Sosis (200g) | `8690841002251` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 122 | Coşkun Aynalı Dana Uzun Sosis (400g) | `8690765002255` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 123 | Danet Piliç Kokteyl Sosis (400g) | `8693214003204` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 124 | Pınar Çocuk Sosis (Yüksek Kalsiyumlu - 180g) | `8690526011601` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 125 | Namet Gurme Dana Sosis Trüflü (200g) | `8690623141604` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 126 | Pınar Aç Bitir Dana Fıstıklı Salam (50g) | `8690526012158` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; 32 ve 126 aynı ürün adı/barkoduyla tekrar edilmiş; iki ayrı ürün sayılmaz |
| 127 | Pınar Büfe Dana Blok Macar Salam (250g) | `8690526012202` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 128 | Namet Blok Dana Macar Salam (200g) | `8690623151059` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 129 | Namet Pratik Dana Fıstıklı Salam (60g) | `8690623151202` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 130 | Polonez Fıstıklı Dana Salam (150g) | `8690632002128` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 131 | Polonez Dilimli Dana Jambon (100g) | `8690632002402` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 132 | Torku Doğal Dana Macar Salam (130g) | `8690123015158` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 133 | Torku Doğal Dana Fıstıklı Salam (130g) | `8690123015202` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 134 | Maret Pratik Dilim Dana Fıstıklı Salam (60g) | `8690504141313` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 135 | Maret Dana Blok Macar Salam (200g) | `8690504141559` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 136 | Banvit Piliç Jambon (120g) | `8693240003483` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 137 | Banvit Hindi Baton Salam (400g) | `8693240003551` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 138 | Erpiliç Piliç Blok Salam (250g) | `8690754311221` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 139 | Erpiliç Piliç Büfe Salam (800g) | `8690754311351` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 140 | Danet Dilimli Dana Macar Salam (60g) | `8693214004157` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 141 | Aytaç Dilimli Piliç Salam (100g) | `8690841003203` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 142 | Coşkun Fıstıklı Blok Dana Salam (250g) | `8690765003207` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Katkının adı/E kodu yerine yalnızca işlev sınıfı yazılmış; değerlendirme için belirsiz |
| 143 | Cumhuriyet Karışık Şarküteri Tabağı (120g) | `8690743002208` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; Karışık pakette her bileşen ürünün tam alt içeriği ayrı verilmemiş; tam etiket kabul edilemez |
| 144 | Pınar Aç Bitir Hindi Füme Göğüs Eti (60g) | `8690526012403` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok; İçindekiler alanına proses/ambalaj açıklaması veya ayrıca doğrulanması gereken iddia karışmış |
| 145 | Namet Gurme Hindi Füme Göğüs Eti (150g) | `8690623161010` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 146 | Banvit Hindi Füme Göğüs Eti (150g) | `8693240003605` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 147 | Danet Dilimli Dana Jambon (100g) | `8693214004300` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 148 | Aytaç Piliç Blok Salam (250g) | `8690841003258` | Geçer — kimlik teyidi değil | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 149 | Coşkun Dilimli Hindi Füme (100g) | `8690765003306` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
| 150 | Pınar Dilimli Karabiberli Dana Füme Et (100g) | `8690526012557` | HATALI | Gönderimde içerik kaynağı/etiket fotoğrafı ve kaynak tarihi yok |
