import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'Manufacturer sunscreen records resolve offline with complete original INCI',
      () async {
    final all =
        jsonDecode(await rootBundle.loadString('assets/curated_cosmetics.json'))
            as List;
    final rows =
        all.where((r) => r['catalog_batch'] == 'sunscreens-20261013').toList();
    expect(rows.length, 18);
    expect(all.map((r) => r['code']).toSet().length, all.length);
    final repo =
        ProductRepository(loader: (_) async => throw StateError('Offline'));
    for (final row in rows) {
      final code = row['code'] as String;
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += int.parse(code[i]) * (i.isEven ? 1 : 3);
      }
      expect((10 - sum % 10) % 10, int.parse(code[12]));
      final product = await repo.find(code, category: 'cosmetic');
      expect(product.ingredients, row['ingredients']);
      expect(product.name, row['name']);
      expect(product.ingredients, isNot(contains('But friendship Extract')));
      expect(product.ingredients.length, greaterThan(300));
      expect(product.sourceUrl, row['source_url']);
      expect(product.nameMatched, isFalse);
    }
    final cosrx = await repo.find('8809416470191', category: 'cosmetic');
    expect(cosrx.ingredients,
        startsWith('Aqua/Water, Ethylhexyl Methoxycinnamate'));
    expect(cosrx.ingredients, endsWith('Benzyl Alcohol, Tocopherol'));
    expect(cosrx.code, isNot('8809641712219'));
    final mineral = await repo.find('8684083321423', category: 'cosmetic');
    expect(mineral.name, contains('SPF 30'));
    final mini = await repo.find('8684083320785', category: 'cosmetic');
    final full = await repo.find('8682773091687', category: 'cosmetic');
    expect(mini.name, contains('15 Ml'));
    expect(full.name, contains('50 Ml'));
    expect(mini.code, isNot(full.code));
    await expectLater(repo.find('8809641712219', category: 'cosmetic'),
        throwsA(isA<ProductLookupException>()));
  });
}
