import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('products missing from Open Facts resolve offline from the catalogue',
      () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .where((row) => row['catalog_batch'] == 'not-in-open-facts-20261025')
        .toList();
    expect(rows, hasLength(33));
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      throw StateError('Network must not be needed');
    });
    for (final row in rows) {
      expect(['not_in_open_facts', 'open_facts_without_ingredients'],
          contains(row['open_facts_coverage']));
      // GTIN and ingredients come from the same product page.
      expect(row['field_sources']['code'], [row['source_url']]);
      expect(row['field_sources']['ingredients'], [row['source_url']]);
      expect((row['source_url'] as String),
          startsWith('https://marketkarsilastir.com/fiyat/${row['code']}-'));
      final product = await repo.find(row['code'] as String);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(product.ingredients, isNotEmpty);
    }
    expect(calls, 0);
  });

  test('declared allergens of the batch are tagged', () async {
    final rows = {
      for (final row in (jsonDecode(await rootBundle
              .loadString('assets/curated_products.json')) as List)
          .where((r) => r['catalog_batch'] == 'not-in-open-facts-20261025'))
        row['code']: row
    };
    // Koska Cevizli Yaz Helvası: irmik, tahin, ceviz.
    expect(rows['8690710001286']['allergens'],
        containsAll(['en:gluten', 'en:sesame-seeds', 'en:nuts']));
    // Koska Amerikan Fıstık Krokan: yer fıstığı and susam.
    expect(rows['8690710136155']['allergens'],
        containsAll(['en:peanuts', 'en:sesame-seeds']));
    // Tire Şiş Köfte contains flour.
    expect(rows['8699197160288']['allergens'], ['en:gluten']);
    // Cheese and butter are milk products.
    expect(rows['8692963150810']['allergens'], ['en:milk']);
  });
}
