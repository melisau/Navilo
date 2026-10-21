import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sarıyer dairy batch resolves offline with source-matched GTINs',
      () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .where((row) => row['catalog_batch'] == 'sariyer-dairy-20261021')
        .toList();
    expect(rows, hasLength(11));
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      throw StateError('Network must not be needed');
    });
    for (final row in rows) {
      // GTIN, ingredients and nutrition come from the same retailer page.
      expect(row['field_sources']['code'], [row['source_url']]);
      expect(row['field_sources']['ingredients'], [row['source_url']]);
      final product = await repo.find(row['code'] as String);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(product.allergens, ['en:milk']);
      final n = product.nutrition!;
      expect(n.source, 'catalogue');
      expect(n.energyInconsistent, isFalse, reason: row['name'] as String);
    }
    expect(calls, 0);
  });
}
