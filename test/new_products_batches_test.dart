import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

/// Batches of Turkish products that Open Food Facts / Open Beauty Facts do
/// not have, or have without an ingredient list (docs/new_products).
const batches = {
  'not-in-open-facts-20261026',
  'off-photo-transcription-20261026',
  'danet-not-in-open-facts-20261026',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('new product batches resolve offline with cited sources', () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .where((row) => batches.contains(row['catalog_batch']))
        .toList();
    expect(rows, isNotEmpty);
    final repo = ProductRepository(loader: (_) async {
      throw StateError('Network must not be needed');
    });
    for (final row in rows) {
      final code = row['code'] as String;
      expect(['not_in_open_facts', 'open_facts_without_ingredients'],
          contains(row['open_facts_coverage']),
          reason: code);
      expect(row['field_sources']['code'], [row['source_url']]);
      expect(row['field_sources']['ingredients'], [row['source_url']]);
      if (row['source_type'] != 'manufacturer') {
        // Market Karşılaştır and Open Food Facts URLs carry the GTIN.
        expect(row['source_url'] as String, contains(code));
      }
      final product = await repo.find(code);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(product.ingredients, isNotEmpty);
      if (row['nutrition'] != null) {
        expect(product.nutrition!.energyInconsistent, isFalse, reason: code);
      }
    }
  });

  test('allergens follow the ingredient text', () async {
    final rows = {
      for (final row in (jsonDecode(await rootBundle
              .loadString('assets/curated_products.json')) as List)
          .where((r) => batches.contains(r['catalog_batch'])))
        row['code']: row
    };
    // Harras peanut butter: peanuts only; tree nuts are a trace.
    expect(rows['8695077125651']['allergens'], ['en:peanuts']);
    expect(rows['8695077125651']['traces'], contains('en:nuts'));
    // Çokça mayonnaise: egg yolk and mustard seed flavouring.
    expect(rows['8699118060963']['allergens'],
        containsAll(['en:eggs', 'en:mustard']));
    // Namet pastırma: çemen with wheat flour.
    expect(rows['8692415400548']['allergens'], ['en:gluten']);
    // Rennet ("peynir mayası") alone is not a milk mention, but the milk is.
    expect(rows['8692095341155']['allergens'], ['en:milk']);
  });
}
