# Gönderilen şarküteri listesi denetimi — 13 Ekim 2026

50 satır incelendi. Gönderilen barkodların 40 tanesi GTIN kontrol basamağını geçmiyor; kalan 10 barkod için kaynaklarda tam ürün eşleşmesi doğrulanamadı. Kontrol basamağı geçmesi ürün kimliğinin doğrulandığı anlamına gelmez.

- **Eklendi (1):** 2. satırdaki Pınar Klasik Dana Kangal Sucuk 225 g. Gönderilen `8690526032415` yerine aynı ürünün kaynaklardan doğrulanan `8690527021149` barkodu kullanıldı. İçindekiler de gönderilen listeden kopyalanmadı; CarrefourSA etiket alanından alındı.
- **Zaten mevcut (1):** 31. satırdaki Pınar Aç Bitir Macar Salam 60 g, katalogda `8690527010938` barkoduyla mevcut. Gönderilen barkod ve metinle değiştirilmedi.
- **Eklenmedi (48):** Doğrulanmış aynı ürün/gramaj barkodu ile tam etiket kaynağı elde edilemedi. Bunlar araştırma dosyasında tutulur; uygulamanın ürün kataloğuna dahil edilmez.

Kaynaklar:
- [Pınar Klasik 225 g barkod bilgisi](https://www.asyasanalmarket.com/pinar-225-gr-sucuk--klasik--fermente--18988)
- [Pınar Klasik 225 g içerik bilgisi](https://www.carrefoursa.com/pinar-klasik-sucuk-225-g-p-30123642)

Satır bazında sonuçlar: `catalog_analysis/processed_meat_audit_20261013.json`.

Bu denetim fiziksel ambalaj incelemesi değildir. Bilgiler perakendeci etiket alanlarından alınmıştır; uygunluk değerlendirmesi uygulamanın mevcut içerik kurallarıyla yapılır.
