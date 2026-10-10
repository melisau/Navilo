import 'dart:convert';

String normalize(String value) => value
    .replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ').trim();

class IngredientRule {
  final String id, name, category;
  final List<String> aliases;
  IngredientRule(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String,
        category = json['category'] as String,
        aliases = List<String>.from(json['aliases'] as List);
}

class Policy {
  final String version;
  final List<IngredientRule> rules;
  Policy(this.version, this.rules);
  factory Policy.decode(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return Policy(json['version'] as String, (json['groups'] as List)
        .map((item) => IngredientRule(item as Map<String, dynamic>)).toList());
  }

  // Exact token matching only. OCR uncertainty and claim parsing are separate work.
  List<IngredientRule> evaluate(String label, String category) {
    final tokens = label.split(RegExp(r'[,;\n]')).map(normalize).toSet();
    return rules.where((rule) => rule.category == category &&
        rule.aliases.any((alias) => tokens.contains(normalize(alias)))).toList();
  }
}
