import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Every reviewed expansion record retains its complete formula offline', () async {
    final all = jsonDecode(await rootBundle.loadString('assets/curated_products.json')) as List;
    final rows = all.where((row) => row['catalog_batch'] == 'food-expansion-20261013').toList();
    expect(rows.length, greaterThanOrEqualTo(30));
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      throw StateError('Network must not be needed');
    });
    for (final row in rows) {
      final product = await repo.find(row['code'] as String);
      expect(product, isNotNull, reason: row['code']);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(row['ingredient_evidence'], 'full_label_transcription');
      for (final field in ['code', 'name', 'ingredients']) {
        expect(row['field_sources'][field], isNotEmpty);
      }
    }
    expect(calls, 0);
  });
}
