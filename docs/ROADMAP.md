# Geliştirme roadmap'i

Başlangıç: 10 Ekim 2026. Aşamalar bağımlılık sırasındadır; süreler tek geliştirici ve yeni Flutter öğrenimi için planlama tahminleridir. Veri lisansı, uzman incelemesi ve cihaz testleri takvimi etkileyebilir. Tam kapsam tek MVP'ye sıkıştırılmayacak.

## 0 — Kapsam ve temel kararlar (2–4 gün)

- [x] Flutter kararı; Android ilk geliştirme hedefi, iOS ikinci doğrulama hedefi.
- [x] README, roadmap, kaynak prototipi ve taslak politika.
- [ ] İlk pazar/ülke, dil, hedef kullanıcı ve çalışma adını kesinleştir.
- [ ] Yayın için paket kimliği, hesap sahipliği, mağaza hesaplarını belirle.
- [ ] Flutter stable, Android SDK, emülatör ve fiziksel cihaz kurulumunu tamamla.
- [ ] Platform klasörlerini üret, format/analyze/test çalıştır.

Çıkış ölçütü: başlangıç uygulaması fiziksel Android cihazda açılır; seçilen SDK sürümü ve bağımlılık kilidi kaydedilir.

## 1 — İçerik politikasını üretime hazırlama (1–2 hafta)

- Her maddeye kalıcı kimlik, kategori, açık INCI/TR/EN adları, E/CI kodları, kaynak ve inceleme durumu ekle.
- Paraben, alüminyum ve silikon kapsamını tek tek gözden geçir; son ek/alt dize eşleşmesi kullanma.
- Hidrojenize/kısmen hidrojenize yağları ayrı alt türlerde tut; trans yağla eşitleme.
- Kullanıcının bütün özgün maddelerini kapsama tablosunda izleyip eksik eş anlamlıları doğrula.
- E924/E924a gibi alternatif kodların ve renklendirici adlarının doğruluğunu uzman/kaynak incelemesine gönder.
- Formaldehit reçinelerini formaldehitten, Di-HEMA'yı HEMA'dan ayrı tut.
- Politika ve bilimsel içerik için ayrı onay/sürüm/yürürlük süreçleri kur.
- İçerik listesi, besin tablosu ve pazarlama beyanlarını ayrı ayrıştır.
- Negasyon (`içermez`), miktar (`0 g`), yüzdeler, parantezli içerik ve E kodu boşluklarını ele al.

Çıkış ölçütü: sabit doğrulama kümesinde kritik yanlış eşleşme yok; her uyarı hangi token ve hangi kuraldan geldiğini açıklıyor. Bilinmeyen maddeler kapsama oranını düşürür, güvenlik puanını yükseltmez.

## 2 — Profil ve ürün veri modeli (1–2 hafta)

- Onboarding: kullanım amacı → cilt/beslenme tercihleri → isteğe bağlı ilgi alanları.
- Cilt anketi: yağlanma, kuruluk, bölgesel farklılık, gerginlik; ayrı hassasiyet/sivilce eğilimi alanları. Kullanıcı sonucu düzeltebilir.
- Profilde kesin ele / tercih / bilgi ver seçenekleri; varsayılan uygulama politikası ayrı korunur.
- Ürünler: barkod, marka, kategori, ülke, formül sürümü, içerik, besin değerleri, kaynak, güncellenme tarihi.
- Özellikler: true/false/unknown + kanıt türü. Şekersiz/ilave şekersiz/rafine şekersiz ayrımı.
- Analiz kaydı: ürün sürümü, politika sürümü, profil sürümü, eşleşmeler, eksik bilgi.
- İlk etapta yerel repository; ardından Supabase/PostgreSQL, migration ve erişim kuralları.
- Tercihler için kalıcı yerel saklama, silme ve sıfırlama.

Çıkış ölçütü: uygulama yeniden açıldığında tercihler korunur; kullanıcı değiştirdiğinde sonuç yeniden hesaplanır; başka kullanıcının verisine erişilemez.

## 3 — Kamera, barkod ve OCR (2–3 hafta)

- Flutter kamera/galeri/barkod paketlerini SDK ve lisans uyumuyla seç.
- Kamera izni reddi, galeri sınırlı erişimi, iptal, çevrimdışı ve düşük ışık durumlarını tasarla.
- Barkod → katalog arama; bulunamazsa içerik fotoğrafına geç.
- Fotoğraf kırpma, döndürme, parlama/odak kontrolü; birden fazla yüz/etiket desteği.
- Cihazda OCR için Türkçe, INCI ve küçük etiket veri kümesinde ölçüm; gerekirse sunucu alternatifi.
- İçerik/besin tablosu ayrımı; düşük güvenli kelimeleri kullanıcıya doğrulat.
- Etikette eşleşen metni işaretle; kaynak ve tarih göster.
- Fotoğraf kaydetmeden analiz seçeneği; yükleme varsa saklama süresi ve silme akışı.

Çıkış ölçütü: kamera/galeriden gerçek ürün → doğrulanmış metin → açıklanabilir sonuç akışı iki platformda çalışır. Eksik fotoğraf uygunluk garantisine dönüşmez.

## 4 — Keşfet, filtreler, puan ve karşılaştırma (2–3 hafta)

- Gerçek ve kurgusal verileri ayrı tut; ilk doğrulanmış ürün koleksiyonunu oluştur.
- Ad/marka/kategori arama, filtreleri birlikte kullanma, boş sonuç ve sıralama.
- Vegan, glutensiz, laktozsuz, şekersiz, ilave şekersiz, rafine şekersiz, az yağlı için pazara uygun tanım ve kanıt politikası.
- Ketojenik tercih için porsiyon/karbonhidrat kriterini açıkça göster; yalnızca ürün adına dayanma.
- Politika uyumu, kişisel uyum ve veri yeterliliğini ayrı göster.
- Sayısal puan metodolojisini örneklerle incele: kesin eleme nasıl etkiler, bilinmeyen bilgi nasıl gösterilir? Onaylanmadan rastgele 0–100 puan yayınlama.
- İki ürünü aynı kategori ve profil sürümüyle karşılaştır.
- Favoriler, listeler, ülke/para birimi/birim fiyat desteği.

Çıkış ölçütü: filtre sonuçları doğrulanmış özelliklerle eşleşir; bilinmeyen özellik olumlu kabul edilmez. Aynı girdiler aynı puanı üretir.

## 5 — Alternatifler ve yönetim paneli (2–3 hafta)

- Önce aynı amaç/kategoride uygun alternatif; ardından bütçe, ülke ve erişilebilirlik.
- Her öneride neden önerildiğini ve fiyatın tarihini göster.
- Stok/fiyat entegrasyonu yokken güncel bulunabilirlik iddia etme.
- Web paneli: ürün doğrulama, kaynak ekleme, kullanıcı düzeltmeleri, kural incelemesi, sürüm yayınlama ve geri alma.
- Formül değişikliğini sürümle; bildirim yalnızca doğrulanmış ürün değişiminde.
- Sponsorlu yerleşimler varsa açık etiketle; içerik puanı satın alınabilir olmasın.

Çıkış ölçütü: alternatifler bütün kesin filtreleri karşılar; kaynak ve sürüm denetlenebilir.

## 6 — FODMAP (veri anlaşmasına bağlı, 2–4 hafta)

- Kullanım hakkı olan test/sertifika verisini seç; Monash verisini izinsiz kopyalama.
- Model: ürün/ülke/formül, porsiyon gramı, düşük/orta/yüksek, kaynak ve test tarihi.
- Doğrulanmış sınıflandırma ile olası FODMAP kaynak uyarısını ayrı göster.
- Veri yoksa bilgi yetersiz; düşük FODMAP ≠ herkes için IBS'ye uygun.
- Bir öğündeki toplam tüketimi ve kişisel toleransın sınırlarını açıklayan içerikleri incelet.

Çıkış ölçütü: her kesin FODMAP etiketi belirli porsiyon ve kanıta bağlanır; lisans doğrulanmadan özellik yayınlanmaz.

## 7 — İlgi alanları ve dönemsel içerik (3–5 hafta)

- IBS, PCOS, kalp sağlığı ve menopoz için uzman incelemesinden geçen koleksiyonlar.
- Hastalığa uygunluk garantisi yerine açık beslenme hedefleri ve listeleme gerekçeleri.
- Döngü girişi isteğe bağlı; takvimden evre yalnızca tahmin. Düzensiz döngü ve eksik veri durumları.
- Evreye göre zorunlu beslenme iddiaları üretmeden kaynaklı bilgilendirme.
- Hassas profil alanları için KVKK/GDPR işleme, saklama, silme ve gerekiyorsa aktarım değerlendirmesi; yalnızca AB bölgesi seçmek uyum garantisi değildir.
- Sağlık/döngü/fotoğraf verilerini analiz ve hata kayıtlarına göndermeme.

Çıkış ölçütü: her içerik kaynak/tarih/editör taşır; kullanıcı bu alanları kullanmadan da temel uygulamayı kullanabilir.

## 8 — Tarifler (2–4 hafta)

- Doğrulanmış tarif, porsiyon, alerjen ve besin değeri modeli.
- Kullanıcı filtreleriyle tarif arama; alternatif malzeme sonrası hesaplama ve yeniden kontrol.
- FODMAP tarif etiketi için tarifin porsiyon ve toplam bileşimini doğrula.
- Yapay zekâ önerilerini doğrulanmış tarif/kural katmanından geçir; serbest sağlık iddiası üretme.

Çıkış ölçütü: tarifin hiçbir malzemesi kesin kaçınma kurallarını ihlal etmez; bilinmeyen malzeme görünür kalır.

## 9 — Pilot ve yayın (2–3 hafta; MVP sonrası)

- 10–15 hedef kullanıcıyla mağaza senaryosu: tarama, sonucu anlama, iki ürün seçimi.
- Erişilebilirlik: metin büyütme, ekran okuyucu, renk dışında durum açıklaması.
- Fiziksel Android/iOS testleri; kamera/izin, hesap silme, çevrimdışı ve API hata senaryoları.
- Ölçümler: etiket başarı oranı, kritik yanlış negatifler, bilinmeyen madde oranı, sonuca ulaşma süresi. Sayısal hedefler pilot veriyle belirlenir.
- API maliyeti, hız limitleri, erişim kontrolü, anahtar yönetimi ve yedek geri yükleme.
- Mağaza gizlilik beyanları, uygulama açıklaması, destek kanalı, kullanım koşulları.
- Android kapalı test / iOS TestFlight → hata düzeltme → kademeli yayın.

## MVP sınırı ve bağımlılıklar

İlk pilot için aşama 0–4 gerekir. Alternatifler ve yönetim panelinin asgari doğrulama işlevleri pilotta kısıtlı olabilir. FODMAP kesin sınıflandırması veri anlaşmasına; sağlık/döngü önerileri uzman incelemesine bağlıdır. Fotoğraflı cilt analizi ayrı doğrulama projesidir ve ilk MVP'ye dahil değildir; anket tabanlı profil önce gelir.

## Sonraki somut iş listesi

1. Flutter SDK kurulumu ve Android cihazda ilk açılış.
2. Mevcut kaynakların format, analiz ve testlerini çalıştırma.
3. Etiket ayrıştırıcı ve doğrulanmış sözlük kapsam tablosu.
4. Cilt anketi ve kalıcı profil repository'si.
5. Kamera/galeri → metin doğrulama → değerlendirme dikey akışı.
