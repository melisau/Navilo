import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Saf Nutrition vegan cheese protein chips resolve offline', () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .where((row) =>
            row['catalog_batch'] == 'saf-nutrition-protein-chips-20261014')
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
      expect(product.ingredients, contains('bezelye proteini (%15,5)'));
      expect(product.ingredients, isNotEmpty);
    }
    final seasonal = rows.singleWhere((row) => row['code'] == '8682368978669');
    expect(seasonal['ingredients'], contains('mevsim yeşillikli çeşnisi (%6,5)'));
    expect(seasonal['traces'], containsAll(['gluten', 'peanuts', 'walnuts', 'soybeans']));
    final spicy = rows.singleWhere((row) => row['code'] == '8682368978645');
    expect(spicy['name'], contains('Acılı'));
    expect(spicy['ingredients'], contains('acı baharat çeşnisi (%6,5)'));
    expect(spicy['traces'], containsAll(['gluten', 'peanuts', 'walnuts', 'soybeans']));
    expect(calls, 0);
  });
}
