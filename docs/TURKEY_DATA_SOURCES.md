# Turkey product data acquisition

Research date: 2026-10-11. This is a source assessment, not a claim that new feeds are connected. No provider has been contacted, no subscription purchased, and no credentials obtained.

## Recommended priorities

| Priority | Candidate | Verified capability | Still to establish |
|---|---|---|---|
| 1 | GS1 Türkiye / TOBBsenkron | Turkish GDSN data pool and product subscriptions/synchronisation; documentation includes allergen/nutrition/diet modules | Eligibility for consumer apps, actual Turkish GTIN coverage, populated ingredient fields, licensing, API/message format and cost |
| 1 | Direct manufacturers: Züber, Söke; Solagron next | Züber and Söke publish ingredient statements on their official product pages | Exact GTIN-to-variant mapping, bulk feed/export, display/cache/analysis rights and update agreement |
| 2 | NIQ Brandbank Content Licensing | Product-content licensing and GTIN-based extraction service | Turkey-specific ingredient/INCI coverage, pilot responses, consumer-app use rights and price |
| 3 | Camgöz / JoJ | Turkish barcode/product/price API advertised by the provider | Full ingredient field not verified; commercial rights, provenance and exact coverage require confirmation |

### GS1 Türkiye

UDY describes a local product-information platform and transfer to TOBBsenkron. Do not equate Verified by GS1 identity verification with a complete ingredient database. Nor does a GDSN field existing prove that brands populate it.

- https://www.gs1tr.org/view/menu/goster.php?Guid=cf1bb7a9-5dbe-11ed-847d-0242ac110003
- https://www.gdsn.org.tr/Home/Education
- https://www.gs1.org/services/gdsn
- Published contact on GS1 Türkiye's UDY page: info@gs1tr.org

### Manufacturer evidence

Züber's official Nutzilla 315 g page has an ingredient section; its contents qualitatively align with the user's hazelnut-spread label. The reviewed page does not itself establish a verified GTIN mapping or bulk reuse license. Request the full catalog, not a one-product exception.

- https://www.zuber.com/products/nutzilla-findik-kremasi-315g-x-1-adet
- https://www.zuber.com/pages/iletisim (published contact: zuber@zuber.com)

Söke publishes separate Gluten-Free Flour and Gluten-Free Bread Flour pages with different formulations. The user's photographed ingredient panel resembles the bread-flour formulation. A retailer's barcode/name association is insufficient to overwrite that evidence. Ask Söke to confirm GTIN 8690577001764, exact variant, packaging generation and current formulation.

- https://soke.com.tr/urun/soke-glutensiz-un
- https://soke.com.tr/urun/soke-glutensiz-ekmek-unu?language=tr

Solagron is identified on the user's raspberry packaging. The official homepage was located but could not be fetched reliably in this session; a complete official ingredient/GTIN feed was not verified.

- https://solagron.com.tr/

### Licensed and local catalog candidates

NIQ advertises content licensing. Its extraction service exposes GetProductDataForGTINs, but that is not public unauthenticated product access. No Turkey-specific success rate or quotation verified.

- https://nielseniq.com/global/en/products/content-licensing/
- https://api.brandbank.com/svc/feed/extractdata.asmx

Camgöz's official documentation directs API access to JoJ. Published capabilities emphasise names, barcodes, prices and images. Do not infer full food ingredients or cosmetic INCI from product identity or images. No paid trial started.

- https://m.camgoz.net/
- https://m.camgoz.net/swagger

## Pilot before integration

Send a 50-GTIN pilot basket: 30 Turkish foods, 10 cosmetics/personal care products, 10 supplements. Include the six known failing scans. Have the supplier return records, not only coverage claims.

Evaluate separately: identity match rate, full ingredient availability, exact pack/variant match, Turkish language availability, source date, trace/allergen evidence, and update latency. Compare with package photos. Fail the pilot if the provider guesses ingredients from the product name or returns conflicting variants without identifying them.

Known GTINs: 8681630799919, 8683979249261, 8690577001764, 8683979480152, 4061461279493, 8691190142261. The German item is a secondary European coverage check, not part of Turkish-brand coverage statistics.

## Required data contract

Each record needs: GTIN, brand, exact variant, net quantity/unit, target market, original ingredient text plus language, declared allergens, trace statements, label claims, source URL/provider ID, provider update time, retrieval time, and rights metadata. Unknown is different from an empty verified list. Cosmetic INCI must remain separate from food ingredients.

Ask for an API or CSV/JSON/XML/SFTP export, delta updates and deleted/discontinued records. A reviewed scheduled server import should validate schema, GTIN/variant mapping and licensing, retain source-specific versions and quarantine formulation conflicts. Flutter should query Navilo's catalog endpoint; private provider credentials must stay on the server. Update frequency is to be agreed with each provider, not guessed.

Public ingredient pages can support research, but are not evidence of an API or a bulk redistribution agreement. No website crawler or unlicensed catalog has been enabled in the app. Product ingredients alone are also not laboratory FODMAP measurements.

## Outreach draft — not sent

Konu: Navilo için GTIN bazlı ürün içeriği veri erişimi ve pilot talebi

Merhaba,

Türkiye pazarına yönelik Navilo mobil uygulamasında kullanıcıların ürün etiketlerini kendi içerik tercihleriyle karşılaştırmasını geliştiriyoruz. GTIN/barkod bazında tam içerik veya INCI listesi, alerjen/iz beyanları, ambalaj miktarı, ürün çeşidi ve güncelleme tarihi içeren bir veri kaynağı arıyoruz.

API veya düzenli CSV/JSON/XML aktarımınız var mı? Tüketici uygulamasında gösterim, önbellekleme, içerik eşleştirmesi ve türetilmiş uyarılar üretme hakları hangi sözleşme kapsamında sağlanıyor? Türkiye kapsamı, güncelleme yöntemi, kota ve ücretler hakkında bilgi rica ediyoruz.

Önce 50 barkodluk bir örnek liste için tam kayıtlarla kapsam ve doğruluk testi yapmak istiyoruz. Ürün adı/görseli mevcut olup içerik listesi bulunmayan kayıtların ayrı belirtilmesi bizim için önemlidir. Üreticiler için ayrıca GTIN–ürün çeşidi–formül sürümü eşleşmesini doğrulayacak katalog paylaşımı rica ediyoruz.

Teşekkürler.
