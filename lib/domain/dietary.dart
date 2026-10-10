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
  bool matches(String text) {
    // Token boundaries preserve phrases; no fuzzy matches or safety conclusions.
    final tokens = text.split(RegExp(r'[,;\n()]')).map(normalize).toSet();
    return aliases.any((alias) => tokens.contains(normalize(alias)));
  }
}
