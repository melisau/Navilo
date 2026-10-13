import 'dart:convert';

String normalize(String value) => value
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .replaceAll('ı', 'i')
    .toLowerCase()
    .replaceAll('i\u0307', 'i')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

// Negation belongs to the immediately named substance, never the entire label.
bool containsIngredient(String text, String alias) {
  final value = normalize(text);
  final name = RegExp.escape(normalize(alias));
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
