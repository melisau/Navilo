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
