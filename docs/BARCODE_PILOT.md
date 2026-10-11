# Barcode pilot — 2026-10-11

Direct official API checks for the user's failed scans:

| Barcode | Provider | Result |
|---|---|---|
| 8681630799919 | Open Food Facts | Product found: Nutzilla Fındık Kreması; no ingredients_text fields in full response |
| 4061461279493 | Open Food Facts | Product found: Zwiebelsuppe; no ingredients_text fields in full response |
| 8683979249261 | Open Food Facts | HTTP 404 |
| 8690577001764 | Open Food Facts | HTTP 404 |
| 8683979480152 | Open Food Facts | HTTP 404 |
| 8691190142261 | Open Beauty Facts | HTTP 404 |

These findings demonstrate missing usable source data, not barcode camera failure. USDA responses have not been independently checked in this pilot. Phone screenshots report no usable match for four food codes and an unspecified service failure for 8683979480152; the latter is not proof of a quota error.

The flour screenshot shows no matching dictionary ingredient; this is not a verified low-FODMAP classification. The visible editor is scrollable; the screenshot alone cannot establish whether its content is truncated.

Next coverage work requires manufacturer or licensed regional product feeds with exact GTIN and full ingredient lists. Additional sources should be measured against this pilot before claiming improved Turkish coverage. Do not hardcode product contents from these examples into the production catalog.
