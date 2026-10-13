import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Reviewed sauces resolve offline and preserve source-declared nut allergens',
      () async {
    final all =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'))
            as List;
    final rows = all
        .where((r) => r['catalog_batch'] == 'breakfast-sauces-20261013')
        .toList();
    expect(rows.length, 4);
    expect(all.map((r) => r['code']).toSet().length, all.length);
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final code = row['code'] as String;
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += int.parse(code[i]) * (i.isEven ? 1 : 3);
      }
      expect((10 - sum % 10) % 10, int.parse(code[12]));
      final product = await repo.find(code);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(product.sourceUrl, row['source_url']);
      expect(product.nameMatched, isFalse);
    }
    expect(calls, 0);
    final cokca = await repo.find('8699118055419');
    expect(cokca.ingredients, contains('ceviz içi'));
    expect(cokca.ingredients, contains('çemen unu'));
    expect(cokca.ingredients, contains('baharatlar, koruyucular'));
    expect(cokca.ingredients, isNot(contains('sodyum benzoat')));
    expect(cokca.allergens, contains('en:nuts'));
    final tat = await repo.find('8690635260393');
    expect(tat.ingredients, contains('yer fıstığı(%5), ceviz(%1)'));
    expect(tat.allergens, containsAll(['en:peanuts', 'en:nuts']));
    final tukas = await repo.find('8690508004246');
    expect(tukas.ingredients, contains('ceviz'));
    final olives = await repo.find('8690103131347');
    expect(olives.traces, contains('en:nuts'));
  });

  test('All 100 submissions are audited and unresolved formulas are excluded',
      () async {
    final audit = jsonDecode(
        await File('docs/breakfast_sauces/audit.json').readAsString()) as List;
    expect(audit.length, 100);
    expect(audit.where((r) => r['gtin_valid'] == false).length, 57);
    expect(audit.map((r) => r['index']).toSet(),
        {for (var i = 101; i <= 200; i++) i});
    final repo = ProductRepository(loader: (_) async => {'status': 0});
    for (final row in audit.where((r) => r['gtin_valid'] == false)) {
      await expectLater(
          repo.find(row['code'] as String), throwsFormatException);
    }
    for (final code in [
      '8690575171513',
      '8690575171520',
      '8696027016913',
      '8680395186828',
      '8691573082801'
    ]) {
      await expectLater(
          repo.find(code), throwsA(isA<ProductLookupException>()));
    }
  });
}
