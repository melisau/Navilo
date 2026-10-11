# Navilo

**Find what fits you.**

Navilo is a Flutter mobile app project for discovering and evaluating food, cosmetics, and personal care products against transparent ingredient rules and personal preferences.

## Status

Development prototype. The main flow now separates product capture, ingredient-text review and results. Native camera, cropping and OCR must still be validated on a physical Android device; static analysis is not a device test.

## Implemented

- Skippable first-use introduction, remembered on this device.
- A focused home screen with barcode scan, camera and gallery actions.
- A separate review screen with source text, specific reading warnings and explicit completeness confirmation.
- A separate results screen with ingredient chips, distinct gluten/lactose/sugar claim colours and expandable sources/limitations.
- Open Food Facts / Open Beauty Facts lookup, with photo fallback when product ingredients are unavailable.
- On-device Latin-script OCR with crop/rotate and manual correction of misread text.
- Device-local reviewed product records and the five most recently saved products.
- Persistent language, self-reported skin type and dietary preferences. Preferences do not yet filter results or generate recommendations.
- A versioned avoidance dictionary with separate margarine, hydrogenated-oil and trans-fat records and explicit cosmetic ingredient lists.
- Larger touch targets, scalable system text, scrollable layouts, text labels alongside colours and Turkish/English interface copy.

See [Mobile UX flow](docs/MOBILE_UX_FLOW.md) for the screen structure and device acceptance checks.

## Product principles

1. A no-match result says **No ingredient from our list was detected**. The Turkish UI uses **Listemizdeki madde tespit edilmedi**. This is not a safety guarantee.
2. A match means **Does not meet our ingredient policy**, not a medical finding.
3. Personal preferences, scientific evidence, and regulatory status are separate records.
4. Labels cannot rule out lead, cadmium, or arsenic contamination. No heavy-metal-free claim is generated without relevant verified laboratory evidence.
5. FODMAP classifications require serving information and verified data with appropriate usage rights. Ingredient lists alone are insufficient.
6. Gluten-free, vegan, lactose-free, sugar-free, no-added-sugar, and refined-sugar-free are distinct attributes. Missing evidence remains unknown.
7. Health and cycle interests are optional. Navilo does not provide medical advice; its language and functionality must reflect this purpose.

## Getting started

Install the Flutter stable SDK and Android tools using the [official guide](https://docs.flutter.dev/install). From the repository root:

```sh
flutter doctor -v
flutter create --platforms=android,ios --project-name navilo --no-overwrite .
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

The no-overwrite option preserves existing sources; inspect the Git diff after platform generation. Local iOS builds require macOS and Xcode. Android is the first development target on Windows. Final application identifiers must be configured before publishing.

### Checks

- Select a clear ingredient-label image with the gallery button or capture it with the camera. Review the extracted text before evaluation. A label containing `Maltitol, Palm Yağı` should match two groups.
- Enter `Margarin` and expect only the margarine rule.
- Cosmetics: enter `Di-HEMA Trimethylhexyl Dicarbamate` and expect Di-HEMA, not HEMA.
- Leave completeness unchecked in the review screen: the result button remains disabled and explains the required confirmation.

## Structure

```text
lib/main.dart             Mobile capture, review and results flow
lib/domain/policy.dart    Policy model and exact-token matching
assets/policy.json        Versioned draft avoidance dictionary
test/policy_test.dart     Critical matching scenarios
docs/ROADMAP.md           Detailed roadmap in Turkish
```

## Dictionary limitations

The dictionary is a draft based on the founder's avoidance criteria, pending expert review. It does not cover every synonym or entire chemical family. Colorant names and CI codes are independent entries, without unverified equivalences. Detecting fragrance does not establish synthetic origin.

Matching currently uses complete names separated by commas, semicolons, or line breaks. Spaced E numbers, functional descriptions, nested ingredients, percentages, and OCR errors are not yet parsed. Nutrition statements such as `trans fat: 0 g` must not be submitted as ingredient tokens. A future parser will separate nutrition facts, claims, and ingredients. A no-match result does not establish complete label coverage.

## Planned architecture

Flutter → repository layer → product/policy API → PostgreSQL.

Local profiles first, followed by optional account-backed storage. Photo retention will be optional and time-limited. On-device OCR will be evaluated before choosing a server fallback. API secrets must remain on the server, with user-level access controls. Any AI explanations will use verified information; evaluation rules and scores will remain deterministic and versioned. A web panel will manage product evidence, dictionary reviews, and policy releases.

## Roadmap

See [the detailed roadmap](docs/ROADMAP.md) for dependencies, acceptance criteria, and estimates. The following features are not implemented yet:

1. Flutter setup and first Android device run.
2. Dictionary review and robust label parsing.
3. Skin questionnaire and persistent profiles.
4. Camera/OCR device validation, lost-image recovery, barcode scanning, and stronger ingredient-section extraction.
5. Product search, dietary filters, scoring, and comparisons.
6. Alternatives and administration.
7. Verified, serving-specific FODMAP integration.
8. Reviewed IBS, PCOS, heart-health, menopause, and cycle-interest collections.
9. Recipes, pilot testing, and store releases.

Photo-based skin analysis is a separate future validation project. The first profile will be questionnaire-based.

## References

- [Flutter installation](https://docs.flutter.dev/install)
- [CosIng and its limitations](https://single-market-economy.ec.europa.eu/sectors/cosmetics/cosmetic-ingredient-database_en)
- [Monash FODMAP guidance](https://www.monashfodmap.com/get-app-help/)
- [EFSA: hazard versus risk](https://www.efsa.europa.eu/en/glossary/hazard)
- [KVKK: special categories of personal data](https://www.kvkk.gov.tr/Icerik/2051/Ozel-Nitelikli-Kisisel-Veriler)

Citing a source does not grant permission to copy or commercially reuse its database. Provider licenses must be reviewed before integration.


## Photo scanning status

Camera/gallery and on-device OCR are implemented. Real-image OCR accuracy and native builds are not yet verified. Photograph the ingredients panel closely; full packaging can include unrelated text. Ingredient-heading extraction is heuristic and requires user review. OCR supports Android/iOS only. New native dependencies require a full stop and restart rather than hot reload. iOS requires deployment target 15.5 or newer and must be verified on macOS. Android minSdk is 24. Photos are not uploaded by this implementation.


## Languages and dietary reference data

The in-app EN/TR switch translates interface text and ingredient display names without translating or modifying the original OCR text. Turkish and English aliases resolve to stable rule IDs. Language choice is currently session-only; automatic translation, persistent locale and a full product catalog are not implemented.

`assets/dietary.json` contains source-attributed reference entries with bilingual aliases. FSA cereal guidance is reused under OGL v3.0 (Crown copyright; contains public sector information licensed under the Open Government Licence v3.0). Oats receive a separate review flag. The FODMAP seed does not reproduce the Monash app database, portion thresholds or the full ACG table. It only indicates potential sources and never certifies low/high FODMAP status of a scanned product. No-match is unknown. Run `USDA_API_KEY=<key> dart run tool/sync_dietary.dart` periodically to attach USDA FoodData Central FDC IDs to each entry. The command uses an atomic file replacement and leaves the previous data untouched if the request fails. USDA search results are evidence links, not automatic gluten, lactose or FODMAP classifications. Monash data is not copied; only its official reference link may be retained. Confirm commercial reuse terms before expanding third-party content. Original translations and aliases are maintained by Navilo, not endorsed by source organizations.

## October 11 reliability changes

Barcode responses now preserve original ingredient text and expose source date, allergens, trace warnings and claims separately. Empty translated fields fall back to another available language. OCR no longer rewrites ingredients into avoidance-group names, and detecting a heading no longer marks a photo complete. Negation applies to the named occurrence rather than suppressing the entire label. Lactose-free claims no longer suppress wheat references. Android INTERNET permission is included for non-debug builds too. See [Android phone testing](docs/ANDROID_TESTING.md). Taxonomy synchronization and serving-specific FODMAP integration remain planned.


### Barcode data sources (current development configuration)
- Food uses Open Food Facts only. Cosmetics use Open Beauty Facts.
- USDA demo fallback has been removed; missing ingredients lead to the label photo flow.
- Source names, links and missing-content/service diagnostics remain visible.
- No paid providers or GS1 subscriptions are connected. Manufacturer/licensed feeds are research candidates only.
- Open Food Facts data reuse must follow its ODbL attribution and applicable share-alike obligations: https://openfoodfacts.github.io/documentation/docs/Product-Opener/api/tutorials/license-be-on-the-legal-side/

### Turkey catalog acquisition
See [Turkey data sources](docs/TURKEY_DATA_SOURCES.md) for the researched manufacturer/licensed-feed shortlist, unresolved GTIN mappings, pilot criteria, data contract and an unsent outreach draft. These candidates are not live integrations.


### Photo review and offline product recall
Camera/gallery input now opens a crop/rotate editor before on-device OCR. Reviewed ingredient lists can be linked to a barcode and saved on the device; rescanning checks these records before online lookup. Editing clears confirmation, structural OCR warnings block saving, and food/cosmetic records are isolated. See [workflow and phone checks](docs/PHOTO_LOCAL_FLOW.md). Physical camera/OCR accuracy remains to be validated on device.
