# GS1 Türkiye / TOBBsenkron onboarding for Navilo

Prepared: 2026-10-11. Status: access inquiry prepared; not submitted. No live connector or credentials exist yet.

## Verified starting point

The official 2026 GS1 Türkiye rules, Article 29, describe TOBBsenkron access for members through a participation agreement and user protocol supplied on request. Recipient pricing is based on product/subscription matches. The applicable amount, eligibility and rights for Navilo require an individual response; a public free ingredient-lookup API has not been verified.

Source: https://gs1tr.org/userfiles/files/GS1_Usul_ve_Esaslar_08032026.pdf
Education and user guide: https://www.gdsn.org.tr/Home/Education
UDY contact source: https://www.gs1tr.org/view/menu/goster.php?Guid=cf1bb7a9-5dbe-11ed-847d-0242ac110003

Do not start a producer barcode-prefix purchase to solve data-recipient access. Ask GS1 for the correct membership/recipient route first. Verified by GS1 identity lookup and TOBBsenkron ingredient subscriptions are distinct services.

## Ready-to-send inquiry (not sent)

Alıcı: info@gs1tr.org
Konu: Navilo — TOBBsenkron veri alıcısı erişimi, pilot ve teknik entegrasyon talebi

Merhaba,

Navilo adlı, Türkiye pazarına yönelik Flutter mobil uygulamasını geliştiriyoruz. Kullanıcıların taradığı ürün barkodlarını ürünün özgün içerik listesiyle eşleştirip kişisel içerik tercihleri bakımından değerlendirmek istiyoruz. Üretici/marka sahibi olarak barkod tahsisinden ziyade ürün verisi alıcısı erişimi arıyoruz.

TOBBsenkron için aşağıdaki konularda bilgi ve mümkünse teknik görüşme rica ediyoruz:

1. Bir tüketici uygulaması hangi üyelik/veri alıcısı modeliyle erişebilir? Şirket kuruluşu, GLN veya başka bir ön koşul var mı? Katılım anlaşması ve kullanıcı protokolünü paylaşabilir misiniz?
2. Türkiye hedef pazarındaki gıda, kozmetik ve takviyelerde GTIN bazlı tam içindekiler/INCI, alerjen ve iz beyanları, net miktar, ürün çeşidi ve formül güncelleme tarihi sağlanıyor mu? Bu alanların doluluk oranları nedir?
3. Kullanıcıya gösterim, sunucuda saklama/önbellekleme ve içeriklerden türetilmiş tercih uyarıları üretme hakkı hangi lisans kapsamında veriliyor? Üretici bazlı yayın/erişim izinleri gerekiyor mu?
4. Veri aktarımı API, GDSN mesajlaşması veya dosya aktarımıyla mı yapılıyor? Test ortamı, kimlik doğrulama, şema, örnek kayıt ve değişiklik/silme bildirimleri belgelerini paylaşabilir misiniz?
5. 2026 yılı veri alıcısı ücretlendirmesi, başlangıç bedeli, asgari abonelik ve ürün/abonelik eşleşmesinin hesaplanması nasıldır?
6. Ekteki altı GTIN için önce içerik alanları da dahil örnek kayıt/pilot erişimi sağlayabilir misiniz? Daha sonra 50 GTIN ile kapsam testi yapmak istiyoruz. Kaydı olup içeriği boş ürünlerin ayrı belirtilmesini rica ediyoruz.

Özellikle 8690577001764 için ambalaj çeşidi ve güncel formül eşleşmesini teyit etmek istiyoruz. Yalnız ürün adı veya fotoğrafı, içerik analizi için yeterli olmayacaktır.

Teşekkürler,
Melisa
Navilo

Gönderim öncesi gerekirse eklenecek bilgiler: başvuru sahibinin tam adı, dönüş e-postası, varsa şirket unvanı ve mevcut GS1 üyeliği/GLN. Bilinmeyen şirket bilgileri doldurulmamıştır.

## Pilot attachment

Use gs1-pilot-gtins.csv in this folder. These are test requests, not confirmed GS1 catalog records. The Austrian soup is a separate European coverage probe.

## Work after the response

1. Confirm recipient eligibility, actual populated ingredient coverage and display/analysis rights before paying or signing.
2. Review a sample payload and official technical specification; document the exact mapping. Do not invent a TOBBsenkron REST endpoint.
3. Implement a server-side adapter for the supplied interface, with secrets stored on the server.
4. Import source-specific versions keyed by GTIN, market and variant; quarantine missing ingredients and conflicting formulations.
5. Serve normalized, attributed records to Flutter and retain photo OCR fallback.
6. Run the six-product pilot, then expand to 50 representative GTINs; measure identity, ingredient completeness and package agreement separately.

No external message, membership submission, paid action or live synchronization has been performed as part of this preparation.
