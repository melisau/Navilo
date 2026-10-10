# Navilo

**Find what fits you.**

Navilo is a Flutter mobile app project for discovering and evaluating food, cosmetics, and personal care products against transparent ingredient rules and personal preferences.

## Status

Early source prototype. Flutter/Dart were not available in the development environment, so compilation, static analysis, and Flutter tests have **not yet been run**. Android/iOS platform projects have not been generated. This is not a production-ready application.

## Implemented

- Three Turkish-language Material 3 screens: Evaluate, My Profile, and Criteria.
- Manual ingredient entry with category-specific exact-token matching.
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

### Manual checks

- Food: enter `Su, Maltitol, Palm Yağı` and expect two matching groups.
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
4. Camera, barcode, OCR, and label confirmation.
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
