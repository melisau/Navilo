import 'policy.dart';

class DietaryEntry {
  final String id, kind, source;
  final Map<String, String> names;
  final List<String> aliases;
  DietaryEntry(Map<String, dynamic> j)
      : id = j['id'],
        kind = j['kind'],
        source = j['source'],
        names = Map<String, String>.from(j['names']),
        aliases = List<String>.from(j['aliases']);
  String name(bool english) => names[english ? 'en' : 'tr']!;
  bool matches(String text) =>
      aliases.any((alias) => containsIngredient(text, alias));
}

// Match exact ingredient names after Turkish I folding; never guess OCR words.
List<String> glutenFreeIngredients(String text, {bool english = false}) {
  const ingredients = <String, List<String>>{
    'Mısır nişastası|Maize starch': [
      'mısır nişastası',
      'misir nisastasi',
      'corn starch',
      'maize starch'
    ],
    'Pirinç unu|Rice flour': ['pirinç unu', 'pirinc unu', 'rice flour'],
    'Patates nişastası|Potato starch': [
      'patates nişastası',
      'patates nisastasi',
      'potato starch'
    ],
  };
  return ingredients.entries
      .where((e) => e.value.any((a) => containsIngredient(text, a)))
      .map((e) => e.key.split('|')[english ? 1 : 0])
      .toList();
}

bool hasGlutenFreeClaim(String text) => RegExp(
        r'(?<![a-zçğöşü])(?:glutensiz|gluten[- ]free|glutenfrei)(?![a-zçğöşü])')
    .hasMatch(normalize(text));

// Positive evidence requires every ingredient to be recognized, not just absence
// of a warning. Unknown words, flavourings and incomplete compound lists fail closed.
bool isSimpleRiceList(String text) {
  var value = normalize(text.replaceAll(RegExp(r'\r?\n'), ';'))
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ü', 'u')
      .trim();
  value = value.replaceFirst(
      RegExp(r'^(?:icindekiler|ingredients|zutaten)\b\s*[:：]?\s*'), '');
  value = value.replaceAll(RegExp(r'\(\s*%?\s*\d+(?:[.,]\d+)?\s*%?\s*\)'), '');
  value = value.replaceFirst(RegExp(r'[.;]\s*$'), '');
  final parts = value.split(RegExp(r'[,;\n]+')).map((v) => v.trim()).toList();
  const rice = {
    'pirinc',
    'kahverengi pirinc',
    'esmer pirinc',
    'tam tahil pirinc',
    'tam tahilli pirinc',
    'rice',
    'brown rice',
    'wholegrain rice',
    'reis',
    'vollkornreis'
  };
  const salt = {'tuz', 'deniz tuzu', 'salt', 'sea salt', 'salz', 'meersalz'};
  return parts.isNotEmpty &&
      parts.any(rice.contains) &&
      parts.every((v) => rice.contains(v) || salt.contains(v));
}

/// Sugars and sugar syrups listed as ingredients. Not a measurement of the
/// product's total sugars. Fruit-based sweeteners and non-sugar sweeteners
/// are reported separately and never called "added sugar".
List<String> listedSugarAdditions(String text) {
  const aliases = <String>[
    'şeker',
    'seker',
    'sugar',
    'zucker',
    'sakkaroz',
    'sukroz',
    'sucrose',
    'glikoz',
    'glukoz',
    'glucose',
    'dekstroz',
    'dextrose',
    'fruktoz',
    'fructose',
    'invert şeker',
    'invert şeker şurubu',
    'invert sugar',
    'glikoz şurubu',
    'glukoz şurubu',
    'glikoz-fruktoz şurubu',
    'glukoz-fruktoz şurubu',
    'fruktoz-glikoz şurubu',
    'glucose syrup',
    'glucose-fructose syrup',
    'fructose-glucose syrup',
    'corn syrup',
    'high fructose corn syrup',
    'mısır şurubu',
    'misir surubu',
    'fruktoz şurubu',
    'bal',
    'honey',
    'molasses',
    'agave syrup',
    'agave şurubu',
    'akçaağaç şurubu',
    'maple syrup',
  ];
  return aliases.where((alias) => containsIngredient(text, alias)).toList();
}

/// Sweetening ingredients made from fruit (apple extract, dates, grape
/// molasses, juice concentrates). They contain natural sugars but are not
/// labelled here as added sugar.
List<String> listedFruitSweeteners(String text) {
  const aliases = <String>[
    'elma özü',
    'elma ekstraktı',
    'apple extract',
    'elma suyu konsantresi',
    'apple juice concentrate',
    'üzüm suyu konsantresi',
    'grape juice concentrate',
    'meyve suyu konsantresi',
    'fruit juice concentrate',
    'hurma',
    'hurma ezmesi',
    'hurma özü',
    'hurma şurubu',
    'dates',
    'date paste',
    'date syrup',
    'pekmez',
    'üzüm pekmezi',
    'keçiboynuzu pekmezi',
  ];
  return aliases.where((alias) => containsIngredient(text, alias)).toList();
}

/// Non-sugar sweeteners (stevia, polyols, intense sweeteners).
List<String> listedNonSugarSweeteners(String text) {
  const aliases = <String>[
    'stevia',
    'steviol glikozit',
    'steviol glikozitleri',
    'steviol glycosides',
    'e960',
    'eritritol',
    'erythritol',
    'e968',
    'ksilitol',
    'xylitol',
    'e967',
    'sorbitol',
    'e420',
    'maltitol',
    'e965',
    'sukraloz',
    'sucralose',
    'e955',
    'aspartam',
    'aspartame',
    'e951',
    'asesülfam k',
    'acesulfame k',
    'e950',
    'sakarin',
    'saccharin',
    'e954',
    'keşiş meyvesi',
    'monk fruit',
  ];
  return aliases.where((alias) => containsIngredient(text, alias)).toList();
}
