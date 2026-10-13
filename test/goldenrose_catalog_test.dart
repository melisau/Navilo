import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Golden Rose official products resolve offline and retain INCI evidence',
      () async {
    final all =
        jsonDecode(await rootBundle.loadString('assets/curated_cosmetics.json'))
            as List;
    final rows = all
        .where((r) => (r['source_name'] as String).startsWith('Golden Rose'))
        .toList();
    expect(rows.length, greaterThanOrEqualTo(39));
    expect(all.map((r) => r['code']).toSet().length, all.length);
    var networkCalls = 0;
    final repo = ProductRepository(loader: (_) async {
      networkCalls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final code = row['code'] as String;
      expect(RegExp(r'^\d{13}$').hasMatch(code), isTrue);
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        sum += int.parse(code[i]) * (i.isEven ? 1 : 3);
      }
      expect((10 - sum % 10) % 10, int.parse(code[12]), reason: code);
      final record = await repo.find(code, category: 'cosmetic');
      expect(record.name, row['name']);
      expect(record.ingredients, row['ingredients']);
      expect(record.ingredients, isNotEmpty);
      expect(record.ingredients, isNot(contains('MAY CONTAIN')));
      expect(record.ingredients, isNot(contains('Base +')));
      expect(record.mayContain, row['may_contain']);
      expect(Uri.parse(record.sourceUrl).host, 'shop.goldenrose.com.tr');
      expect(record.nameMatched, isFalse);
    }
    expect(networkCalls, 0);
  });

  test(
      'Conflicting supplied names and barcodes never override manufacturer data',
      () async {
    final repo = ProductRepository(loader: (_) async => {'status': 0});
    final clear = await repo.find('8691190703004', category: 'cosmetic');
    final iceWhite = await repo.find('8691190703028', category: 'cosmetic');
    expect(clear.name, contains('Clear'));
    expect(clear.ingredients, contains('CI 60725'));
    expect(clear.mayContain, isEmpty);
    expect(iceWhite.name, contains('02'));
    expect(iceWhite.name, isNot(contains('Clear')));
    expect(iceWhite.code, isNot(clear.code));
    final gel04 = await repo.find('8691190419103', category: 'cosmetic');
    expect(gel04.name, contains('04'));
    expect(gel04.name, isNot(contains('Crimson Red')));
    final mini101 = await repo.find('8691190643010', category: 'cosmetic');
    expect(mini101.name, contains('101'));
    expect(mini101.code, isNot('8691190504014'));
    await expectLater(repo.find('8691190703004', category: 'food'),
        throwsA(isA<ProductLookupException>()));
  });

  test('Velvet Matte uses source GTINs and separates possible pigments',
      () async {
    final repo = ProductRepository(loader: (_) async => {'status': 0});
    final product = await repo.find('8691190466015', category: 'cosmetic');
    expect(product.name, contains('Velvet Matte Lipstick - 01'));
    expect(product.ingredients, startsWith('PPG-3 HYDROGENATED CASTOR OIL'));
    expect(product.ingredients, isNot(contains('Base +')));
    expect(product.ingredients, isNot(contains('CI 77891')));
    expect(product.mayContain, contains('CI 77891'));
    expect(product.sourceUrl, contains('velvet-matte-lipstick-01'));
    await expectLater(repo.find('8691190070120', category: 'cosmetic'),
        throwsA(isA<ProductLookupException>()));
  });
  test('Eye products retain official shade names and full INCI', () async {
    final repo = ProductRepository(loader: (_) async => {'status': 0});
    final gray = await repo.find('8691190142025', category: 'cosmetic');
    expect(gray.name, contains('402'));
    expect(gray.sourceUrl, contains('dark-gray'));
    expect(gray.ingredients, startsWith('PPG-3 HYDROGENATED CASTOR OIL'));
    expect(gray.ingredients, isNot(contains('Base +')));
    final white = await repo.find('8691190142056', category: 'cosmetic');
    expect(white.sourceUrl, contains('405-white'));
    final dipliner = await repo.find('8691190198831', category: 'cosmetic');
    expect(dipliner.ingredients, contains('DIAZOLIDINYL UREA'));
    expect(dipliner.ingredients, contains('CI 77499'));
    expect(dipliner.mayContain, isEmpty);
  });
}
