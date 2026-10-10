# Navilo

**Find what fits you.**

Navilo is a Flutter mobile app project for discovering and evaluating food, cosmetics, and personal care products against transparent ingredient rules and personal preferences.

## Status

Early source prototype. Android and iOS platform projects have been generated with Flutter 3.47.7 / Dart 3.13.5. All five Flutter tests passed on October 10, 2026. Android SDK and licenses are configured; no Android device or emulator was connected during verification. A device build has not yet been verified. This is not a production-ready application.

## Implemented

- Three Turkish-language Material 3 screens: Evaluate, My Profile, and Criteria.
- Camera/gallery input with on-device Latin-script OCR, image preview, optional text correction, and category-specific policy evaluation.
- A versioned draft dictionary with 34 ingredient rule groups.
- Separate rules for margarine, hydrogenated oils, and trans fats.
- Explicit name lists for selected aluminum compounds, silicones, and parabens.
- Empty-input handling, a label-completeness checkbox, and policy version display.
- Self-reported skin type and dietary preferences held in session memory.
- Test sources covering false positives, category boundaries, and HEMA/Di-HEMA separation.

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
- Leave completeness unchecked and enter an unmatched ingredient: expect insufficient information.

## Structure

```text
lib/main.dart             Prototype screens and session state
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

`assets/dietary.json` contains 12 independently curated, source-attributed reference entries with bilingual aliases. FSA cereal guidance is reused under OGL v3.0 (Crown copyright; contains public sector information licensed under the Open Government Licence v3.0). Oats receive a separate review flag. The FODMAP seed summarizes six factual examples from ACG; it does not reproduce the Monash app database, portion thresholds or the full ACG table. It only indicates potential sources and never certifies low/high FODMAP status of a scanned product. No-match is unknown. No live API or automatic source update is configured. Source date: 2026-10-10. Confirm commercial reuse terms before expanding third-party content. Original translations and aliases are maintained by Navilo, not endorsed by source organizations.
