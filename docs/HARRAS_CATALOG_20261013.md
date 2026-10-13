# Harras kataloğu — 13 Ekim 2026

100 satırlık gönderinin tamamı barkod kontrolünden ve Open Food Facts kaynak sorgusundan geçirildi. EAN-13 kontrol basamaklarının tamamı geçerli; bu, ürün kimliğinin doğru olduğunu kanıtlamıyor. 8 barkodda kaynak kaydı bulundu, 92 barkodda bu kaynakta kayıt bulunmadı. 100 satırın tamamı ve sonuçları `docs/harras/audit.json` içinde tutulur.

Gıda kataloğuna 5 ürün eklendi (toplam 73 gıda kaydı):

| Barkod | Ürün | İçerik kanıtı |
|---|---|---|
| 8695077129444 | Bütün Fındıklı Sütlü Çikolata 65 g | OFF metni: %82 çikolata, %18 fındık |
| 8695077129468 | Bütün Fındıklı Sütlü Çikolata 130 g | OFF metni: %85 çikolata, %15 fındık |
| 8695077043641 | Bitter Tablet Çikolata %60 Kakao 80 g | OFF Türkçe içerik metni |
| 8695077112583 | Laktozsuz Yarım Yağlı UHT İçme Sütü 1 L | OFF metni, ayrıca çevrimiçi ambalaj fotoğrafı |
| 8695077141453 | Özel Lezzet Kakaolu Fındık Ezmesi 350 g | Perakende barkodu + 2024 tarihli ambalaj fotoğrafı |

İlk dört kayıt topluluk tarafından aktarılmış, güncel fiziksel ambalajla doğrulanmamış kayıtlardır. Uygulama bunları Open Food Facts kaynağı ve doğrulanmamış topluluk verisi açıklamasıyla gösterir. OFF metinleri kaynakta olduğu gibi korunur; alerjen/iz ve besin/saklama metinleri içerik alanından ayrılır. Özellikle 130 g çikolataya 65 g formülü kopyalanmadı. Laktozsuz süt ambalajında “laktoz enzimi” yazıyor; bu ifade “laktaz enzimi” olarak sessizce değiştirilmedi. Bu bir enzim kimliği doğrulaması değildir.

Ezme barkodu, gönderilen 100 kayıt arasında olmayan ayrı bir kaynaktan bulundu. Gönderilen `8695077122285` OFF kaydının tek fotoğrafı sade kefir gösteriyor; doğru ezme barkodu yerine takma eşleşme yapılmadı. Ezmenin etiketi Fındık (%35), şeker, fındık yağı, yağsız süt tozu, kakao (%4) bildiriyor. Ek dosyadaki emülgatör ve vanilya bu etikette yer almıyor. 2024 fotoğrafı güncel formül teyidi sayılmaz.

Diğer önemli uyuşmazlıklar:

- `8695077029423`: OFF metninde %3,1 yağlı süt; gönderilen dosyada en az %3,5. Miktar metadata'sında da 835 g/1000 ml birlikteliği var. Kataloğa alınmadı.
- `8695077109484`: Harras Crunchies 145 g ürün kimliği mevcut, tam içerik metni yok. Dosyadaki genel bisküvi formülü eklenmedi.
- `8684992004226`: Şikayet metni barkod ve ürün adını bildiriyor; tam içerik kanıtı sağlamıyor. %100 pirinç varsayımıyla eklenmedi.
- `8695077141033`: Kaynakta Aknaz Yarım Yağlı Tost Peyniri; gönderilen Harras Gurme Mantı eşleştirmesi kullanılmadı.

Kaynaklar:

- https://world.openfoodfacts.org/product/8695077129444
- https://world.openfoodfacts.org/product/8695077129468
- https://world.openfoodfacts.org/product/8695077043641
- https://world.openfoodfacts.org/product/8695077112583
- https://laktozsuz.org/file-harras-laktozsuz-sut-1-l/
- https://www.trendyol.com/harras/kakaolu-findik-ezmesi-p-958670708
- https://gidadedektifi.com/urun-incelemeleri/krema-sos-ve-ezmeler/harras-ozel-lezzet-kakaolu-findik-ezmesi-826

Open Food Facts kaynaklı metinlerin atfı: © Open Food Facts contributors, ODbL 1.0, https://opendatacommons.org/licenses/odbl/1-0/ . Atıf ve lisans kayıt bazında saklanır. Fotoğraflar kullanıcı arayüzüne ürün resmi olarak eklenmedi; araştırma kanıtı olarak tutulur.

Toplama: `python tool/collect_harras.py`. Kaynak sorguları önbelleğe alınır; 429 alınırsa toplama durur. İncelenmiş beş kaydı yükleme: `python tool/import_harras_reviewed.py`. Diğer ürün kayıtları korunur.
