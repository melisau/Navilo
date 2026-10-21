import 'dart:convert';

String normalize(String value) => value
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .replaceAll('ı', 'i')
    .toLowerCase()
    .replaceAll('i\u0307', 'i')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final _eNumber = RegExp(
    r'(?<![a-z0-9])(?<!vitamin )e\s?[-‐.]?\s?([0-9o]{3,4})(?:\s?([a-i]))?(?![a-z0-9])');

/// The form both label text and aliases take before matching:
/// [normalize], then Turkish letters folded (OCR often drops ş, ğ, ü, ö,
/// ç) and E numbers written as one token ("E 120", "E-120", "E.120" and
/// the OCR misread "E12O" all become "e120").
String matchForm(String value) => normalize(value)
    .replaceAll('ç', 'c')
    .replaceAll('ğ', 'g')
    .replaceAll('ö', 'o')
    .replaceAll('ş', 's')
    .replaceAll('ü', 'u')
    .replaceAll('â', 'a')
    .replaceAll('î', 'i')
    .replaceAll('û', 'u')
    .replaceAllMapped(_eNumber, (m) {
      final digits = m[1]!;
      // Only treat "o" as a zero when most characters are real digits.
      if (RegExp(r'\d').allMatches(digits).length < digits.length - 1) {
        return m[0]!;
      }
      return 'e${digits.replaceAll('o', '0')}${m[2] ?? ''}';
    });

// Negation belongs to the immediately named substance, never the entire label.
bool containsIngredient(String text, String alias) {
  final value = matchForm(text);
  final name = RegExp.escape(matchForm(alias));
  final negative = RegExp(
      r'(?:contains\s+no|free\s+from|without|does\s+not\s+contain)\s+' +
          name +
          r'(?![a-z0-9çğöşü])|(?<![a-z0-9çğöşü])' +
          name +
          r'\s*(?:[- ]free|içermez|icermez|içermiyor|icermiyor)(?![a-z0-9çğöşü])');
  final remaining = value.replaceAll(negative, ' ');
  return RegExp(r'(?<![a-z0-9çğöşü-])' + name + r'(?![a-z0-9çğöşü])')
      .hasMatch(remaining);
}

class IngredientRule {
  final String id, name, category, englishName;
  final List<String> aliases;
  // Optional metadata: older in-memory rules can lack these after hot reload.
  final String? summaryTr, summaryEn, sourceUrl;
  IngredientRule(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        englishName = (json['name_en'] ?? json['name']) as String,
        category = json['category'] as String,
        summaryTr = _optionalText(json['summary_tr']),
        summaryEn = _optionalText(json['summary_en']),
        sourceUrl = _optionalText(json['source_url']),
        aliases = List<String>.from(json['aliases'] as List);
}

String? _optionalText(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;

class Policy {
  final String version;
  final List<IngredientRule> rules;
  Policy(this.version, this.rules);
  factory Policy.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return Policy(
        json['version'] as String,
        (json['groups'] as List)
            .map((item) => IngredientRule(item as Map<String, dynamic>))
            .toList());
  }
  // Kept for callers; never invent ingredients or replace text with group names.
  String correctOcrText(String text) => text;
  List<IngredientRule> evaluate(String label, String category) => rules
      .where((rule) =>
          rule.category == category &&
          rule.aliases.any((alias) => containsIngredient(label, alias)))
      .toList();
}
