# Camgoz free-tier pilot

Verified 2026-10-11:
- Provider plan page advertises $0/month, 500 credits and no card requirement: https://jojapi.com/hub/api/product-barcode-api/pricing
- The official OpenAPI search response examples include barcode, name and ingredients: https://jojapi.com/hub/api/product-barcode-api/openapi.json
- Requests use X-JoJAPI-Key and the query parameter. Prices/history are disabled in the pilot to reduce unnecessary credit use. Search can return multiple records; credits are not necessarily equal to requests.

Create a JoJ account, select only the $0 subscription for Product Barcode API - camgoz.net, and obtain its API key. This step has not been performed by the agent. No paid subscription is authorised.

Set JOJ_API_KEY in the local terminal environment, then run `python tool/check_camgoz.py` from the project directory. Never put the key into Git, Flutter source or chat. The script performs six lookups, accepts only exact barcodes, and reports ingredient availability separately from identity matches. It stops on authentication or quota errors.

Status: pilot tool prepared; live product coverage not tested because credentials are not available. The mobile app has not been switched to this provider. After a successful pilot, connect via a server-side adapter and confirm provider terms for display/cache/derived analysis. Missing ingredients must retain the photo flow. Do not infer FODMAP classification from this provider's identity or nutrition fields.


## Local key setup
Open `.env.local` in the project root and replace `BURAYA_YAPISTIR` with the new key only (without Bearer). The file is ignored by Git. `python tool/check_camgoz.py` reads it automatically; an existing JOJ_API_KEY environment variable takes precedence. This configures the local pilot, not the Flutter app or Codex MCP settings.
