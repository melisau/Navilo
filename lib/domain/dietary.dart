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

/// Listed additions, not a measurement of the product's total sugars.
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
    'invert sugar',
    'glikoz şurubu',
    'glukoz şurubu',
    'glucose syrup',
    'corn syrup',
    'mısır şurubu',
    'misir surubu',
    'fruktoz şurubu',
    'bal',
    'honey',
    'pekmez',
    'molasses',
    'agave syrup',
    'agave şurubu',
    'akçaağaç şurubu',
    'maple syrup',
    'hurma şurubu',
    'date syrup',
    'elma suyu konsantresi',
    'apple juice concentrate',
    'üzüm suyu konsantresi',
    'grape juice concentrate',
  ];
  return aliases.where((alias) => containsIngredient(text, alias)).toList();
}
