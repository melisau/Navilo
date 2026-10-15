# Canlı Supabase aktarımı — 15 Ekim 2026

Proje: Navilo (`wonrwishivggpxojqpxw`). Bu konuşmada eklenen 30 ürünün tamamı aktarıldı: Vegeat’s 5, Topzcorn 4, protein tozu 21.

Barkod, ürün adı, tam içerik, kaynak türü/adresi ve doğrulama zamanı `navilo_catalog` alanlarında; alan bazında kaynaklar, alerjenler, FODMAP ve diğer yerel kayıt bilgileri `catalogue_metadata` içinde korunur. Var olan farklı bir ürün/formülün üstüne yazılmaz. Barkodlar metin olarak korunur; 12 haneli UPC de desteklenir.

**Yayın durumu:** kaynak incelemesi `status=verified`; fiziksel etiket onayı verilmediği için `label_verified=false`, `publication_status=draft`, `valid_until=null`. Mevcut etiket onayı ve geçerlilik tarihi isteyen RLS kuralları korunmuştur. Bu nedenle bu 30 kayıt anonim/uygulama uzak sorgularında henüz yayımlanmaz; yerel APK kataloğunda bulunurlar. Aktarım, canlı yayın olarak raporlanmamalıdır.

Yeni 17 bekleyen kayıt (Vegeat’s 2, Topzcorn 2, protein 13) kullanıcı rollerine kapalı `navilo_unverified_catalog` tablosuna aktarıldı. Önceki 150 ham şarküteri satırı ve 5 kaynak inceleme kaydı da özel tabloda korundu. Ham şarküteri satırlarının güncel onarım/araştırma bilgileri metadata alanına eklendi. Önceki yasaklı barkodlar ve üç çelişkili cips barkodu engel tablosunda tutulur.

Uygulanan SQL: 202610130002, 202610130003, 202610130004 ve 202610150005. Mevcut canlı şema ayrıca yayın kontrol alanları içerdiğinden 202610120001 yeniden uygulanmadı. Supabase Management API üzerinden CLI ile çalıştırıldı; eski migration takip tablosu mevcut değildi.

Aktarım sonrası 30 satır geri okunarak barkod, ad, tam içerik ve kaynak adreslerinin birleşik MD5 özeti yerel veriyle karşılaştırıldı ve eşleşti. Doğrulanan özet: `8f1ef1e9c4a3b2788a21dadb7193c415`. Özel tabloda 172 satır doğrulandı. Anonim API sorgusunda özel tabloya erişim 401 ile reddedildi; canlı ürün sorgusu 200 ile 0 yayımlanmış kayıt döndürdü.

Yeniden üretim: `python -m tool.build_catalogue_sync`. Oluşturulan SQL yeniden çalıştırıldığında aynı kayıtlar çoğaltılmaz; farklı içerikli bir mevcut kayıt varsa işlem hata vererek durur.
