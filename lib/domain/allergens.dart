import 'dart:convert';

import 'policy.dart';

/// One of the 14 regulated allergens (TGK Etiketleme Yönetmeliği Ek-1,
/// FSA Annex II), from assets/allergens.json.
class AllergenEntry {
  final String id, source;
  final String? note;
  final Map<String, String> names;
  final List<String> aliases, exclude, offTags;
  AllergenEntry(Map<String, dynamic> j)
      : id = j['id'] as String,
        source = j['source'] as String,
        note = j['note'] as String?,
        names = Map<String, String>.from(j['names'] as Map),
        aliases = List<String>.from(j['aliases'] as List),
        exclude = List<String>.from(j['exclude'] as List? ?? const []),
        offTags = List<String>.from(j['off_tags'] as List? ?? const []);

  String name(bool english) => names[english ? 'en' : 'tr']!;

  /// Exempt or look-alike phrases (coconut milk, wheat glucose syrup) are
  /// removed before matching.
  bool matches(String text) {
    var value = normalize(text);
    for (final phrase in exclude) {
      value = value.replaceAll(normalize(phrase), ' ');
    }
    return aliases.any((alias) => containsIngredient(value, alias));
  }

  static List<AllergenEntry> decodeAll(String json) =>
      ((jsonDecode(json) as Map<String, dynamic>)['entries'] as List)
          .map((e) => AllergenEntry(e as Map<String, dynamic>))
          .toList();
}

/// Words that start a precautionary ("may contain") statement.
final _precautionary = RegExp(
    r'içerebilir|icerebilir|eser miktar|iz miktar|aynı tesiste|ayni tesiste|'
    r'aynı hatta|ayni hatta|may contain|traces of|same facility|'
    r'kann spuren|spuren von');

/// Splits label text into the ingredient part and precautionary
/// statements. Sentences are split on full stops (not decimals), line
/// breaks and exclamation marks.
({String ingredients, String precautionary}) splitPrecautionary(String text) {
  final ingredients = <String>[];
  final precautionary = <String>[];
  for (final sentence in text.split(RegExp(r'(?<!\d)\.(?!\d)|\n|!'))) {
    if (sentence.trim().isEmpty) continue;
    (_precautionary.hasMatch(normalize(sentence))
            ? precautionary
            : ingredients)
        .add(sentence);
  }
  return (
    ingredients: ingredients.join('. '),
    precautionary: precautionary.join('. ')
  );
}

class AllergenFindings {
  /// Named in the ingredients or declared by the product database.
  final List<AllergenEntry> contains;

  /// Only named in a precautionary statement or database trace tag.
  final List<AllergenEntry> mayContain;
  const AllergenFindings(this.contains, this.mayContain);
  static const empty = AllergenFindings([], []);

  bool get isEmpty => contains.isEmpty && mayContain.isEmpty;
  bool containsId(String id) => contains.any((e) => e.id == id);
  bool mayContainId(String id) => mayContain.any((e) => e.id == id);
}

/// [text] is the reviewed ingredient text. [extra] (e.g. the whole OCR
/// text of the label) contributes only its precautionary statements, so
/// serving suggestions or marketing copy never count as ingredients.
AllergenFindings findAllergens(String text, List<AllergenEntry> entries,
    {String extra = '',
    List<String> allergenTags = const [],
    List<String> traceTags = const []}) {
  final own = splitPrecautionary(text);
  final parts = (
    ingredients: own.ingredients,
    precautionary:
        '${own.precautionary}. ${splitPrecautionary(extra).precautionary}'
  );
  final contains = entries
      .where((e) =>
          e.matches(parts.ingredients) || e.offTags.any(allergenTags.contains))
      .toList();
  final mayContain = entries
      .where((e) =>
          !contains.contains(e) &&
          (e.matches(parts.precautionary) || e.offTags.any(traceTags.contains)))
      .toList();
  return AllergenFindings(contains, mayContain);
}

/// Stored preference value for an allergen the user avoids.
String allergenPreference(String id) => 'Alerji:$id';
String? allergenIdOf(String preference) =>
    preference.startsWith('Alerji:') ? preference.substring(7) : null;
