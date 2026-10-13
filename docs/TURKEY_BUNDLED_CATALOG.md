# Bundled Turkish product catalogue

`assets/curated_products.json` is shipped in the app and checked before external
Open Facts requests. It is independent of user contributions and available
offline. It contains 186 food records. Earlier dated additions include Eti, Activia, Pınar
Protein, İçim Fit, Sütaş, Altınkılıç and Yörsan. See the
[expansion evidence table](TURKEY_CATALOG_EXPANSION_20261013.md) for every GTIN,
ingredient source and separately recorded barcode source.

## Records added on 2026-10-13

| GTIN | Product | Evidence |
| --- | --- | --- |
| 8683200063055 | Fellas %100 Fıstık Ezmesi 300 g | Özel Beslenme |
| 8683200063314 | Fellas Ballı Fıstık Ezmesi 300 g | Özel Beslenme |
| 8684207695027 | Fellas Yer Fıstığı ve Kakaolu Meyve Bar 35 g | Özel Beslenme |
| 8681185086267 | Fellas Elmalı ve Tarçınlı Vitamin & Meyve Bar 35 g | Özel Beslenme |
| 8681185086281 | Fellas Turna Yemişi ve Kabak Çekirdeği Vitamin & Meyve Bar 35 g | Özel Beslenme |
| 8681630301013 | Züber Lokma Hindistan Cevizi Kaplı Kakaolu Fındık Ezmeli Meyve Topu 96 g | Doğa Evinizde |
| 8683555359605 | Fropie Fındık Ezmeli Protein Topları 80 g | Karaca |
| 8683555560803 | Fropie Original Fıstık Ezmesi 325 g | ToptanTR |
| 8683555561787 | Fropie Kakaolu Fındık Kreması 315 g | Özel Beslenme |
| 8682368978676 | Saf Nutrition Vegan Peynir Aromalı Protein Cips 50 g | Vegan Bakkal |

Each record stores its exact evidence URL, check date, ingredient text and
explicitly supported label claims. A valid GTIN checksum does not prove that a
formula is current. Empty trace arrays mean no trace statement was transcribed,
not that cross-contact is absent. Claims such as vegan were not imported where
the listing conflicts with ingredients (e.g. propolis).

## Records added in the 2026-10-13 expansion

Fifty food products were added from exact GTIN and complete same-product label
evidence. The batch includes Eti and Ülker snacks, Pınar and Sütaş chilled foods,
İçim drinks, Tamek and Dimes juices/pantry items, plus Sinangil flour and Yudum
olive oil. Full GTINs, ingredient lists, allergens, and per-field evidence are in
`assets/curated_products.json` (`catalog_batch: food-expansion-20261013`);
reviewed source records are in
[`docs/catalog_analysis/reviewed_food_expansion_retailer.json`](catalog_analysis/reviewed_food_expansion_retailer.json)
and related reviewed files. Nine further Eti candidates remain pending package
confirmation and are not in the catalogue.

## Further reviewed records

The follow-up submitted-list reviews added 36 further foods: Pınar, Tat and
Knorr items, additional Eti and Ülker snacks, and eleven Filiz pasta varieties.
They also matched existing valid GTINs to submitted product names without
creating duplicate records. Per-record evidence and unresolved barcode reasons
are in the [catalogue analysis report](catalog_analysis/REPORT.md) and its
`reviewed_food_*` and `repair_results_*` files.

Fellas' 2026 manufacturer PDF was also examined. Its extracted text did not
provide GTIN mappings, so no barcode was inferred from that catalogue and its
formulas were not substituted into records of potentially older variants.

## Updating the catalogue

1. Find an explicit GTIN, product variant/weight and ingredient list together
   on the current label or a manufacturer/retailer product record.
2. Retain factual ingredient data and its evidence URL/date; do not copy
   marketing text or unlicensed product photographs. These sources are not
   represented as licensed automatic data feeds.
3. Add or update the exact GTIN record. Do not derive a formula from a product
   name, guess missing ingredients, or copy a multi-pack barcode to a single pack.
4. Run `flutter test test/turkey_catalog_test.dart`. This checks GTINs,
   uniqueness, metadata and offline barcode resolution. It does not certify
   current manufacturer formulations.
5. Rebuild/restart the app to include changed assets.

There is no automatic retailer scraping or scheduled sync. Broader coverage
still requires more evidenced records or a manufacturer/licensed feed. Missing
barcodes continue to use external providers and the photo review flow.

## Submitted snack list audit

Three additional sourced records (Metro 36 g, Nero 110 g, Mood 125 g) were added on 2026-10-13. Invalid submitted barcodes were not imported. See [the 25-record audit](SUBMITTED_SNACKS_AUDIT_20261013.md) for the pending entries and source links.

## Dairy and staples submission

Four sourced products added: Sütaş full-fat milk 1 L, İçim plain kefir 1 L, Pastavilla spaghetti 500 g, Duru rice-sized bulgur 1 kg. See [40-record audit](SUBMITTED_DAIRY_STAPLES_AUDIT_20261013.md).

## Products 66–100 submission

Added Balparmak Yayla flower honey 460 g, Tamek tomato paste 700 g and Ofçay Efsane 1 kg using sourced GTINs. See [35-record audit](SUBMITTED_PRODUCTS_66_100_AUDIT_20261013.md).

## Protein powder submissions

Added ProteinOcean chocolate whey 400 g, GTIN 8682696010031, with the manufacturer ingredient list and separate barcode evidence. See [23-record audit](SUBMITTED_PROTEIN_POWDERS_AUDIT_20261013.md). Submitted codes were not made aliases.

## Later submitted food lists

Eleven sourced records were added after auditing the biscuit, nuts/pasta, bread/dairy, and crisp submissions. Across the six supplied files, 719 product rows were parsed; 527 submitted barcode occurrences fail the GTIN-13 checksum. The remaining rows still require product identity evidence before import. See [the full audit and preserved source lists](SUBMITTED_FOOD_LISTS_AUDIT_20261013.md).
