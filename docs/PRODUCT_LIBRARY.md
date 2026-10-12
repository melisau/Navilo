# Product library

Reviewed products are saved only when the user chooses Save to library and enters a product name. The library has separate Food and Cosmetics sections, searches names/barcodes, and opens full ingredient text without an online lookup. Barcode-less photos receive a local ID. Legacy barcode-keyed records remain compatible. Editing and saving an opened record updates that same record.

The complete library is separate from the five recently saved products on home. A repeated barcode uses the saved local text first, with packaging review before evaluation. This is user-controlled storage rather than an automatically populated network cache. Clearing app data removes device-local records.

## Community catalogue: pending backend connection

Personal save and public contribution must be separate explicit actions. A future contribution should include a barcode, product name, category, original-language ingredient text, evidence/source, market, and revision date. Keep contributor identity private. Submitted OCR should enter a pending review queue, not overwrite published products. Only approved product revisions should be publicly readable by exact barcode; rejected/pending submissions should not be served as verified contents.

Backend requirements: authenticated submissions, rate limiting, private pending records, separate reviewer privileges, public approved catalogue, correction/report workflow and versioned lookup responses. Do not ship administrator/service credentials in Flutter. Product ingredient text is shared only after explicit consent; health and dietary preferences are never included.

No common server, database credentials, deployment or public contribution action is configured yet. An existing backend may be reused only after its quota and access boundaries are reviewed and its owner chooses it.
