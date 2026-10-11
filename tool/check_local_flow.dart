import 'dart:io';
import 'package:navilo/data/local_product_store.dart';
import 'package:navilo/domain/ingredient_text.dart';
import 'package:navilo/domain/policy.dart';

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('navilo_store_test_');
  final store = LocalProductStore(dir);
  LocalProduct record(String text, [String category = 'food']) => LocalProduct(
      barcode: '8681630799919',
      category: category,
      name: 'Test',
      ingredients: text,
      reviewedAt: DateTime.utc(2026, 10, 11));
  try {
    check(await store.find('8681630799919', 'food') == null, 'Missing lookup');
    await store.save(record('Süt tozu, hindiba kökü lifi'));
    final reopened = LocalProductStore(Directory(dir.path));
    check(
        (await reopened.find('8681630799919', 'food'))!
            .ingredients
            .contains('hindiba'),
        'Restart persistence');
    check(await reopened.find('8681630799919', 'cosmetic') == null,
        'Category isolation');
    await store.save(record('Updated ingredients'));
    check(
        (await reopened.find('8681630799919', 'food'))!.ingredients ==
            'Updated ingredients',
        'Overwrite');
    await store.save(record('Aqua, Parfum', 'cosmetic'));
    await store.remove('8681630799919', 'food');
    check(await store.find('8681630799919', 'food') == null, 'Delete');
    check(await store.find('8681630799919', 'cosmetic') != null,
        'Delete isolation');
    try {
      await store.save(record(''));
      throw StateError('Empty accepted');
    } on ArgumentError {/* expected */}
    try {
      await store.find('../bad', 'food');
      throw StateError('Invalid path accepted');
    } on ArgumentError {/* expected */}
    final flour = IngredientText.parse(
        'İÇİNDEKİLER: Mısır nişastası, pirinç unu, guar gam.\nGluten miktarı 20mg/kg geçmez.');
    check(flour.headingFound && !flour.ingredients.contains('Gluten miktarı'),
        'Turkish uppercase extraction');
    check(IngredientText.reviewIssues('Milk (powder').contains('parentheses'),
        'Truncated list');
    check(IngredientText.reviewIssues('Süt, hindiba kökü lifi').isEmpty,
        'Valid list');
    check(containsIngredient('Tam Yağlı Süt\nTozu', 'süt tozu'),
        'Line wrapped ingredient');
    check(!containsIngredient('trans yağ içermez', 'trans yağ'),
        'Negative claim');
    stdout.writeln(
        'PASS: 13 persistence, isolation, validation, extraction and ingredient checks.');
  } finally {
    // Only individual files from our freshly-created temp test directory.
    await for (final entity in dir.list()) {
      if (entity is File) await entity.delete();
    }
    await dir.delete();
  }
}
