# Katalogda kaynak doğrulaması

Son 150 şarküteri gönderimi kullanıcı isteğiyle yayından dışlandı. Ham kayıtlar `data/quarantine/processed_meat_150.json` içinde tutulur; Flutter varlığı değildir. Önceden bu gönderimden düzeltilerek eklenen `8690527021149` kaydı da kaldırıldı ve arşivlendi. Daha önce bağımsız kaynakla katalogda bulunan `8690527010938` kaydı korunur.

Katalog alanları:

| Alan | Kullanım |
|---|---|
| `source_type` | `label_photo`, `manufacturer`, `retailer`, `open_food_facts` |
| `source_url` | Ürün/etiket kanıtının geçerli HTTPS adresi |
| `verified_at` | Kaynak incelemesinin saat dilimli gerçek tarihi; doğrulanmadıysa `null` |
| `status` | `verified` = doğrulandı; `unverified` = doğrulanmadı |

`verified`, fiziksel ambalajın mutlaka elde incelendiği veya ürünün sağlığa uygun olduğu anlamına gelmez. Kaydın belirtilen kaynak düzeyinde incelendiğini ifade eder. Mevcut kaynaklı katalog kayıtlarının önceki `checked_at` tarihleri korunarak yeni alanlara taşındı; bugün yeniden inceleme yapılmış gibi tarih üretilmedi. Bu metaveri taşıma işlemi yeni bir ürün araştırması değildir.

Yeni içe aktarma:

```text
python -m tool.import_verified_catalogue reviewed.json --category food
```

GTIN-8/12/13/14 kontrol basamağı geçerli olmalı. Başlangıç sıfırları korunur; barkodun son rakamı tahminen değiştirilmez. `status=verified`, geçerli kaynak türü/adresi, geçmişteki gerçek `verified_at`, ürün adı ve içerik, alan bazında `field_sources` kanıtları ve `ingredient_evidence=full_label_transcription` gerekir. Eksik/geçersiz kayıtlar kataloğa alınmadan ayrı ret dosyasına yazılır. Aynı barkodda çelişkili isim/içerik varsa kaynak önceliğiyle örtbas edilmez; incelemeye ayrılır. Mevcut farklı bir kayıt sessizce değiştirilmez.

Kaynak sırası: **aynı ambalajın etiket fotoğrafı → üretici → perakendeci → Open Food Facts**. Etiket fotoğrafında OCR yalnızca metni çıkartır. Barkod, çeşit, net miktar ve tam içerik aynı ambalajla karşılaştırılmadan `verified` verilmez. Fotoğraf referansı erişim kontrollü HTTPS kanıtı olabilir; kişisel fotoğrafın kamuya açılması gerekmez. Perakendeci ve OFF içeriklerinin de tam ürün ve gramajla eşleşmesi incelenir. Çelişkiler manuel incelemeye gider.

Uygulama, doğrulanmamış/kaynaksız/tarihsiz veya dışlanan kaydı paket dosyasına yanlışlıkla eklenmiş olsa bile kullanmaz. Dışlanan barkodlar çevrim içi arama/ürün adı adaylarıyla da geri getirilemez. Katalog topluluk kayıtları da aynı kaynak koşullarından geçer. Open Facts ağ sonuçlarının kaynak bilgisi korunur; otomatik olarak insan incelemesi yapılmış `verified` damgası verilmez.

Sunucu için `202610130002_catalogue_provenance.sql` ve `202610130003_quarantine_processed_meat.sql` hazırlandı. Kaynaksız kayıtların okunmasını RLS ile sınırlar; içerik/kaynak değişince doğrulamayı sıfırlar; kontrol basamağını katalog ve başvuru yazımında denetler; karantina tablosunu anonim/normal kullanıcı okumalarına kapatır. Eski metin tabanlı onay fonksiyonu kaynak incelemesi olmadan yayınlayamaz. Yeni bir kayıt önce kaynak alanlarıyla kaydedilir, ardından yetkili kaynak incelemesinden sonra `status=verified` ve gerçek `verified_at` ile işaretlenir.

**Bu SQL migration dosyaları canlı Supabase'e uygulanmadı:** bu oturumda yönetici veritabanı bağlantısı veya Supabase CLI oturumu bulunmuyor. Uygulama tarafındaki kaynak filtresi aktiftir; eski şemadan kaynak alanları gelmezse topluluk kaydı sonuç olarak kabul edilmez.

## Yazım düzeltmesi, gramaj ve FODMAP

Kullanıcının onayladığı dört satırda açık metin düzeltmesi uygulanır: 10/79 “deksitroz” → “dekstroz”, 97 “süt proteni” → “süt proteini”, 115 “hindistan cevizi cevizi (muskat)” → “muskat”. `ingredients_original` ve `text_corrections` saklanır; `status` ve `verified_at` değişmez. Benzer görünen her kelimeye otomatik yaklaşık eşleşme uygulanmaz.

**Gramaj eksikliği veya farklılığı genel içerik değerlendirmesinde tek başına ret nedeni değildir.** İçerik aynıysa aynı madde kuralları uygulanır. Aynı adla farklı formül/varyant bulunması hâlâ ayrı inceleme gerektirir; barkodun ürün kimliğini yanlış ürüne bağlamak kabul edilmez.

FODMAP için isteğe bağlı `fodmap_servings` ayrı kanıtlar tutar. Her kanıtta `grams_min`, `grams_max`, `level` (`low`/`moderate`/`high`), `source_type`, `source_url`, `verified_at`, `status` ve `evidence_basis=source_reported_serving_assessment` bulunur. İsteğe bağlı `portion_label` ve `portion_grams` kullanıcıya porsiyonu açıklar. Gram aralığı ve doğrulanmış kaynak zorunludur. Düşük dozun üstündeki her miktar otomatik yüksek kabul edilmez; orta/yüksek aralık ayrıca kaynakta bildirilmelidir. Veri yoksa miktara göre sonuç bilinmiyor olarak kalır. Bu değişiklikle ürünlere FODMAP eşikleri eklenmedi; arayüzün mevcut içerik taraması miktara göre düşük/yüksek değerlendirmesine dönüştürülmedi.
