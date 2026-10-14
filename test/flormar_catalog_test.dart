import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Every Flormar variant resolves offline with separate possible pigments',
      () async {
    final rows = (jsonDecode(
                await rootBundle.loadString('assets/curated_cosmetics.json'))
            as List)
        .where((row) => (row['source_name'] as String).startsWith('Flormar'))
        .toList();
    expect(rows.length, greaterThanOrEqualTo(7));
    final seen = <String>{};
    var calls = 0;
    final repo = ProductRepository(loader: (_) async {
      calls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final code = row['code'] as String;
      expect(seen.add(code), isTrue);
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += int.parse(code[i]) * (i.isEven ? 1 : 3);
      }
      expect((10 - sum % 10) % 10, int.parse(code[12]));
      final result = await repo.find(code, category: 'cosmetic');
      expect(result.name, row['name']);
      expect(result.ingredients, row['ingredients']);
      expect(result.ingredients, isNot(contains('MAY CONTAIN')));
      expect(result.mayContain, contains('MAY CONTAIN'));
      expect(result.sourceUrl, contains(code));
      expect(result.nameMatched, isFalse);
    }
    expect(calls, 0);
    final latte = await repo.find('8682536104678', category: 'cosmetic');
    expect(latte.name, contains('Latte'));
    expect(latte.ingredients, contains('LITHOTHAMNION CALCAREUM EXTRACT'));
    expect(latte.ingredients, isNot(contains('MAY CONTAIN')));
    expect(latte.mayContain, contains('CI 77266'));
    final white = await repo.find('8682536035880', category: 'cosmetic');
    expect(white.name, contains('319'));
    final brown = await repo.find('8682536036115', category: 'cosmetic');
    expect(brown.name, contains('HOT CHOCOLATE'));
    await expectLater(repo.find('8682536035880', category: 'food'),
        throwsA(isA<ProductLookupException>()));
  });
}
