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
    final tokens = text
        .split(RegExp(r'[,;\n]'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .length;
    if (text.trim().isNotEmpty && tokens < 2) issues.add('too_short');
    return issues;
  }

  // Only typography is repaired automatically; ingredient names are never guessed.
  static String cleanOcr(String text) => text
      .replaceAll('i\u0307', 'i')
      .replaceAll('\u00ad', '')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAllMapped(
          RegExp(r'([a-zA-ZçÇğĞıİöÖşŞüÜ])[-‐]\s*\n\s*([a-zA-ZçÇğĞıİöÖşŞüÜ])'),
          (m) => '${m[1]}${m[2]}');

  factory IngredientText.parse(String raw) {
    final heading = RegExp(
        r'(?<![a-z])(?:icindekiler|icerikler|ingredients|zutaten|ingr[eé]dients|ingredientes|ingredienti)\s*[:：]?',
        caseSensitive: false);
    // Folding preserves offsets into the untouched original text.
    final searchText = raw
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g');
    final starts = heading.allMatches(searchText).toList();
    if (starts.isEmpty) return IngredientText(raw, cleanOcr(raw.trim()), false);
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
    return IngredientText(raw, cleanOcr(sections.join('\n\n')), true);
  }
}
