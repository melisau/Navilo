# Products Navilo cannot find in Open Food Facts / Open Beauty Facts

The app looks a barcode up in its own catalogue first, then in Open Food
Facts, Open Beauty Facts and Open Products Facts. This folder holds batches of
Turkish products that those databases do not have, or have without an
ingredient list.

1. **Find barcodes.** Brand listings on Market Karşılaştır
   (`marketkarsilastir.com/marka/<brand>`) show each product's GTIN. Regional
   and dairy brands (Tahsildaroğlu, Koska, Kebir, Ekici, Tire Süt Kooperatifi…)
   are least covered.
2. **Check coverage.** Put the barcodes in a `queue_*.json` file here. The
   `Open Facts coverage` workflow (`tool/off_presence.py`) runs on the pull
   request and reports `not_in_open_facts`, `open_facts_without_ingredients` or
   `in_open_facts` for each one.
3. **Read ingredients.** For the first two verdicts, open the product page
   `marketkarsilastir.com/fiyat/<GTIN>-<slug>`, which shows the GTIN and the
   ingredient text together. Products without an ingredient text there are
   skipped (about half of them).
4. **Import.** `tool/import_not_in_open_facts.py` adds the rows to
   `assets/curated_products.json` with `source_type=retailer`,
   `evidence_status=retailer_reported_pending_package_check` and the coverage
   verdict in `open_facts_coverage`.

Pages are read one at a time and cited per product; nothing is crawled in
bulk. Nutrition values are not on these pages and are left empty.

## Batch 2026-10-25

139 barcodes checked: 60 not in Open Facts, 41 there without ingredients,
38 already complete. 33 products had an ingredient text and were added
(17 not in Open Facts, 16 without ingredients there). Cosmetics (Duru, Rebul)
had no INCI list on these pages and were not added.
