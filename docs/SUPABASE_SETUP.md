# Supabase shared catalogue setup

Project base URL: `https://wonrwishivggpxojqpxw.supabase.co`. The supplied `/rest/v1/` suffix is an API endpoint, not the base URL.

## Catalogue connection

The additive SQL migration creates a public, read-only reviewed catalogue and a separate private contribution queue. It does not change existing application tables. Check migration deployment in the Dashboard before running it again. Public rows contain product data, never contributor IDs or preferences. Contribution inserts require a signed-in user and explicit sharing consent. Only a trusted reviewer can approve a pending record.

## Connect

1. Open the new project in Supabase Dashboard.
2. Review and run `supabase/migrations/202610120001_navilo_catalog.sql` once in SQL Editor. Confirm the tables and RLS policies exist.
3. In Settings / API Keys, copy the **publishable** key into `SUPABASE_PUBLISHABLE_KEY` in `config/supabase.local.json`. This file is Git-ignored. Never put a secret/service-role key or database password in Flutter or chat.
4. Start Flutter with `C:\flutter\bin\flutter.bat run --dart-define-from-file=config/supabase.local.json`. A full stop and relaunch is required after changing these compile-time settings; hot reload does not load them.

## Web research

Web research opens the device browser with only the product name and barcode.
No Bing account, search API key, or server-side search function is required.
The user reads the result, copies the complete ingredient list, and reviews it
in Navilo before saving. Browser results are not automatically verified.
5. Barcode lookup checks the personal library, then the reviewed Supabase catalogue, then Open Food Facts / Open Beauty Facts. A missing record or catalogue outage falls back to the existing provider. Only an exact barcode/category record with ingredients is accepted.

The read client is implemented. Sign-in, contributions and photo sharing are not enabled yet. Personal saves never upload automatically. A new catalogue is empty until reviewed products are added.

## Before public use

Verify anon read access only exposes approved catalogue rows; a user cannot read another user's submissions, change status or overwrite catalogue rows. Add sign-in, abuse controls and a review workflow. A human-reviewed ingredient list is not a laboratory result or proof of gluten-free/low-FODMAP status. Do not automatically upload private library records.


## Library contributions

When a user saves a reviewed product with a barcode, the app queues the barcode,
product name and ingredient text for `navilo_submissions` automatically. Personal
photos and preferences are not uploaded. If the device is offline, the queue is
kept in the local product store and retried when the app starts or resumes after
the connection returns. Enable **Authentication → Sign In / Providers →
Anonymous Sign-ins** in the Supabase dashboard. Sessions are currently
memory-only; this prototype does not implement persistent contributor accounts or
contribution management. Configure abuse protection before a public rollout.
The `202610140001_submission_upsert.sql` migration makes a later save of the same
barcode replace that contributor's pending version instead of creating a stale
duplicate.

Submissions remain pending until a trusted reviewer approves them with
`navilo_approve_submission`. Only approved records are returned to other users.
Local saves work even when submission or authentication fails. Library barcode
lookup also supports photo-first records whose file ID differs from the barcode.
