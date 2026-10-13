import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Reviewed Harras barcodes resolve offline and keep different package formulas',
      () async {
    final all =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'))
            as List;
    final rows =
        all.where((r) => r['catalog_batch'] == 'harras-20261013').toList();
    expect(rows.length, 5);
    expect(all.map((r) => r['code']).toSet().length, all.length);
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final product = await repo.find(row['code'] as String);
      expect(product.name, row['name']);
      expect(product.ingredients, row['ingredients']);
      expect(product.ingredients, isNot(contains('Karbonhidrat (g)')));
      expect(product.ingredients, isNot(contains('Serin, kuru')));
      expect(product.nameMatched, isFalse);
    }
    expect(calls, 0);
    final small = await repo.find('8695077129444');
    final large = await repo.find('8695077129468');
    expect(small.ingredients, contains('Fındık (%18)'));
    expect(large.ingredients, contains('Fındık (%15)'));
    expect(large.ingredients, isNot(small.ingredients));
    expect(small.traces, containsAll(['en:pistachios', 'en:almonds']));
    final milk = await repo.find('8695077112583');
    expect(milk.ingredients, 'Yarım yağlı inek sütü, laktoz enzimi.');
    final spread = await repo.find('8695077141453');
    expect(spread.ingredients, contains('kakao (%4)'));
    expect(spread.ingredients, isNot(contains('emülgatör')));
    for (final quarantined in [
      '8695077122285',
      '8695077029423',
      '8695077109484',
      '8684992004226',
      '8695077141033'
    ]) {
      await expectLater(
          repo.find(quarantined), throwsA(isA<ProductLookupException>()));
    }
  });
}
