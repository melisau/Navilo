# Mobile UX flow

## Screen structure

1. First launch: a short introduction with Start, Choose preferences, and Skip. Camera access is not requested here.
2. Home: category selection, barcode/camera/gallery actions, and up to five records saved on this phone. No raw OCR form or analysis card is shown on home.
3. Review: photo or source text, specific reading issues, editable ingredient text, and a completeness checkbox. The result action requires a nonempty, structurally valid list and user confirmation. This check cannot establish OCR accuracy automatically.
4. Results: avoided ingredients and dietary screening, followed by edit/save/new-product actions and expandable source/limitation sections.

Back from results returns to review; back from review returns home with a Continue current product action. A new capture clears the previous product association. A photo fallback after a failed barcode lookup retains that barcode. Linking a barcode to a result returns to review for confirmation.

## Visual and accessibility choices

- Calm green primary colour, white content cards, dark text and restrained status colours.
- Gluten-free claim: purple; lactose-free claim: blue; sugar-free claim: pink. Text identifies every state independently of colour. Unknown states remain neutral and possible ingredient flags use amber.
- Full-width, labelled capture actions with icons and supporting text.
- 56 logical-pixel primary buttons, generous card hit areas and 16-point body text.
- System text scaling remains enabled. Main content scrolls and has no fixed-height text containers. Content width is bounded on wide devices.
- Technical source errors are expandable, with a short photo-fallback explanation first.

## Persistence

`navilo_settings.json` stores intro completion, language and stated preferences locally. Preference writes are serialized. The existing `navilo_products` directory stores reviewed text by barcode/category. Saved-product history ignores malformed JSON records. Photos are not permanently stored.

Preferences are visible configuration only and are explicitly labelled as not yet affecting results. No health recommendations or unverified product-level FODMAP classification are added.

## Required physical-device acceptance checks

- Clean first launch, skip/start/preferences paths, and subsequent launch without the introduction.
- Camera permission granted, denied and canceled; barcode not found and photo fallback.
- Crop cancellation, OCR failure, partial parentheses and text edit removing confirmation.
- Review -> results -> back -> edit -> reconfirm, including a saved record and barcode linking.
- Save, relaunch, open recent record, delete, and language/preferences persistence.
- Narrow device and landscape layout; largest system text; TalkBack reading order and target labels.
- Distinct labelled dietary colours without implying unknown products are free of an ingredient.

Static checks and filesystem checks do not replace native rendering, accessibility, or real OCR tests.

## Verification on 2026-10-11

- Static analysis: no issues in application sources and the new flow test sources.
- Six settings/history checks, thirteen existing local-storage/extraction checks and seven existing summary/Turkish-letter checks passed.
- Three widget tests were authored for onboarding, confirmation/edit transitions and 320-pixel layouts with 200% system text. Execution was blocked before tests could run by Windows Application Control preventing `flutter_tester.exe` from starting. Native rendering and TalkBack checks remain unverified.
- Use hot restart (uppercase `R` in a running Flutter terminal), rather than hot reload, to initialize the new first-launch settings state.
