import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'New source-reviewed meat batch resolves offline without old quarantined rows',
      () async {
    final all =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'))
            as List;
    final rows = all
        .where((r) => r['catalog_batch'] == 'source-verified-meat-20261013')
        .toList();
    expect(rows, hasLength(6));
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final product = await repo.find(row['code']);
      expect(product.ingredients, row['ingredients']);
      expect(product.verificationStatus, 'verified');
      expect(product.verifiedAt, isNotNull);
    }
    final banvit = await repo.find('8690451706426');
    expect(banvit.allergens, ['soybeans']);
    expect(banvit.traces, containsAll(['milk', 'eggs', 'celery', 'gluten']));
    expect(banvit.allergens, isNot(contains('milk')));
    final longSausage = await repo.find('8697403890400');
    expect(longSausage.ingredients, contains('soya proteini'));
    expect(longSausage.ingredients, contains('süt proteini'));
    expect(longSausage.ingredients, isNot(contains('aynı içerik')));
    await expectLater(repo.find('8690527021149'), throwsFormatException);
    for (final code in ['8697471727219', '8691520104198', '8696024317020']) {
      await expectLater(repo.find(code), throwsFormatException);
      await expectLater(
          repo.findNameCandidates(barcode: code), throwsFormatException);
    }
    expect(calls, 0);
  });
}
