import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Sinangil gluten-free toast bread resolves offline', () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .where((row) => row['catalog_batch'] == 'sinangil-gluten-free-bread-20261014')
        .toList();
    expect(rows, hasLength(1));

    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      throw StateError('Network must not be needed');
    });
    final row = rows.single;
    final product = await repo.find('8697702984183');
    expect(product.name, row['name']);
    expect(product.ingredients, contains('glutensiz buğday nişastası'));
    expect(product.ingredients, contains('yumurta'));
    expect(row['allergens'], contains('eggs'));
    expect(row['labels'], contains('tr:gluten-free'));
    expect(calls, 0);
  });
}
