import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Schar gluten-free breads resolve offline with allergen traces', () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .where((row) => row['catalog_batch'] == 'schar-gluten-free-bread-20261014')
        .toList();
    expect(rows, hasLength(3));

    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      throw StateError('Network must not be needed');
    });
    for (final row in rows) {
      final product = await repo.find(row['code'] as String);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(row['labels'], contains('tr:gluten-free'));
    }
    expect(rows.first['allergens'], contains('soybeans'));
    expect(rows.first['traces'], containsAll(['sesame', 'mustard', 'eggs']));
    expect(rows.last['traces'], containsAll(['lupin', 'mustard']));
    expect(calls, 0);
  });
}
