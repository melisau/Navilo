import 'dietary.dart';
import 'policy.dart';

/// What the reviewed ingredient text says about gluten, lactose, sugar and
/// FODMAP. Shared by the result screen and the catalogue so both reach the
/// same conclusion from the same text.
class DietaryAnalysis {
  final List<DietaryEntry> gluten, lactose, fodmap, milkAllergens;
  final bool glutenClaim,
      lactoseClaim,
      lactoseFreeByEnzyme,
      explicitlyListsLactose,
      lactoseFree,
      sugarClaim,
      simpleRice,
      riceGluten,
      riceLactose,
      complete;
  final List<String> sugarAdditions;

  const DietaryAnalysis._({
    required this.gluten,
    required this.lactose,
    required this.fodmap,
    required this.milkAllergens,
    required this.glutenClaim,
    required this.lactoseClaim,
    required this.lactoseFreeByEnzyme,
    required this.explicitlyListsLactose,
    required this.lactoseFree,
    required this.sugarClaim,
    required this.simpleRice,
    required this.riceGluten,
    required this.riceLactose,
    required this.complete,
    required this.sugarAdditions,
  });

  /// [matched] are the reference entries already matched against [text].
  /// [evidence] is extra text where label claims may appear (raw OCR,
  /// product name); [labels] are database tags such as `en:gluten-free`.
  factory DietaryAnalysis.of(List<DietaryEntry> matched,
      {required String text,
      String evidence = '',
      List<String> labels = const [],
      bool complete = false}) {
    final gluten = matched
        .where((e) => e.kind == 'gluten_cereal' || e.kind == 'oats_check')
        .toList();
    final lactose = matched.where((e) => e.kind == 'lactose_check').toList();
    final lactoseEnzyme = ['laktaz enzimi', 'lactase enzyme', 'lactase', 'laktaz']
        .any((alias) => containsIngredient(text, alias));
    final explicitlyListsLactose = lactose.any((e) => e.id == 'lactose');
    final lactoseFreeByEnzyme = lactoseEnzyme && !explicitlyListsLactose;
    final normalized = normalize('$evidence $text');
    final glutenClaim = hasGlutenFreeClaim(normalized) ||
        labels.any((tag) =>
            ['en:gluten-free', 'tr:glutensiz', 'de:glutenfrei'].contains(tag));
    bool claim(List<String> words, List<String> tags) =>
        words.any((word) => RegExp(r'(?<![a-zçğöşü])' +
                RegExp.escape(word) +
                r'(?![a-zçğöşü])')
            .hasMatch(normalized)) ||
        labels.any(tags.contains);
    final lactoseClaim = claim(
        ['laktozsuz', 'lactose-free', 'lactose free', 'laktosefrei'],
        ['en:lactose-free', 'tr:laktozsuz']);
    final fodmap = matched
        .where((e) =>
            e.kind == 'fodmap_potential' ||
            (e.kind == 'lactose_check' &&
                (!lactoseClaim || explicitlyListsLactose) &&
                !lactoseFreeByEnzyme))
        .toList();
    final sugarClaim = claim(
        ['şekersiz', 'sekersiz', 'sugar-free', 'sugar free', 'zuckerfrei'],
        ['en:sugar-free', 'tr:şekersiz']);
    final simpleRice = complete && isSimpleRiceList(text);
    final riceGluten = simpleRice && gluten.isEmpty;
    final riceLactose = simpleRice && lactose.isEmpty;
    final lactoseFree = !explicitlyListsLactose &&
        (lactoseClaim || lactoseFreeByEnzyme || riceLactose);
    return DietaryAnalysis._(
      gluten: gluten,
      lactose: lactose,
      fodmap: fodmap,
      milkAllergens: lactose.where((e) => e.id != 'lactose').toList(),
      glutenClaim: glutenClaim,
      lactoseClaim: lactoseClaim,
      lactoseFreeByEnzyme: lactoseFreeByEnzyme,
      explicitlyListsLactose: explicitlyListsLactose,
      lactoseFree: lactoseFree,
      sugarClaim: sugarClaim,
      simpleRice: simpleRice,
      riceGluten: riceGluten,
      riceLactose: riceLactose,
      complete: complete,
      sugarAdditions: listedSugarAdditions(text),
    );
  }
}
