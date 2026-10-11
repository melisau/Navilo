class IngredientText {
  final String raw, ingredients;
  final bool headingFound;
  IngredientText(this.raw, this.ingredients, this.headingFound);
  static List<String> reviewIssues(String text) {
    final issues = <String>[];
    var balance = 0;
    var broken = false;
    for (final rune in text.runes) {
      if (rune == 40) balance++;
      if (rune == 41) {
        balance--;
        if (balance < 0) broken = true;
      }
    }
    if (balance != 0 || broken) issues.add('parentheses');
    if (text.contains('�')) issues.add('unreadable');
    if (text.trim().isEmpty) issues.add('empty');
    return issues;
  }

  factory IngredientText.parse(String raw) {
    final heading = RegExp(
        r'(?:içindekiler|icindekiler|içerikler|ingredients|zutaten)\s*[:：]?',
        caseSensitive: false);
    final searchText = raw.replaceAll('İ', 'i');
    final starts = heading.allMatches(searchText).toList();
    if (starts.isEmpty) return IngredientText(raw, raw.trim(), false);
    final sections = <String>[];
    final stop = RegExp(
        r'(?:alerjen\s*(?:beyanı)?|allergens?|kann\s+spuren|besin\s+(?:değerleri|öğeleri)|enerji\s+ve|nutrition|gıda\s+işletmecisi|üretici|saklama|storage|tavsiye\s+edilen|kullanıcı\s+grubu|gluten\s+miktarı|trocken,|mindestens\s+haltbar|hergestellt|net\s+miktar)',
        caseSensitive: false);
    for (var i = 0; i < starts.length; i++) {
      var section = raw.substring(starts[i].end,
          i + 1 < starts.length ? starts[i + 1].start : raw.length);
      final end = stop.firstMatch(section);
      if (end != null) section = section.substring(0, end.start);
      // Keep every language section: no product-specific scoring or guessing.
      if (section.trim().isNotEmpty) sections.add(section.trim());
    }
    return IngredientText(raw, sections.join('\n\n'), true);
  }
}
