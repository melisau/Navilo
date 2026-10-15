import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

String normalizedInci(String text) => text
    .trim()
    .replaceFirst(RegExp(r'^INGREDIENTS\s*:', caseSensitive: false), '')
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9]'), '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All reviewed eyeshadow GTINs resolve offline with the source formula',
      () async {
    final rows = jsonDecode(
        File('docs/eyeshadow_research_20261015/reviewed_combined.json')
            .readAsStringSync()) as List;
    expect(rows, hasLength(103));
    var networkCalls = 0;
    final repository = ProductRepository(loader: (_) async {
      networkCalls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final product = await repository.find(row['code'], category: 'cosmetic');
      expect(product.code, row['code']);
      expect(normalizedInci(product.ingredients),
          normalizedInci(row['ingredients']),
          reason: row['code']);
      expect(normalizedInci(product.mayContain),
          normalizedInci(row['may_contain'] ?? ''),
          reason: row['code']);
      expect(product.sourceUrl, row['source_url']);
      expect(product.nameMatched, isFalse);
    }
    expect(networkCalls, 0);
  });

  test('Corrected Pastel variants keep genuine GTINs and full label content',
      () async {
    final repository = ProductRepository(loader: (_) async => {'status': 0});
    final pastel63 =
        await repository.find('8690644014635', category: 'cosmetic');
    expect(pastel63.name, contains('63'));
    expect(pastel63.ingredients.toUpperCase(), contains('PARFUM'));
    expect(pastel63.mayContain, isNotEmpty);
    final glow = await repository.find('8690644002236', category: 'cosmetic');
    expect(glow.name, contains('223'));
    expect(glow.ingredients.toUpperCase(), contains('SQUALANE'));
    expect(glow.ingredients.toUpperCase(), contains('BUTYLENE GLYCOL'));
    expect(glow.ingredients.toUpperCase(), isNot(contains('ISODODECANE')));
    final catalogue = await repository.listCurated(category: 'cosmetic');
    final codes = catalogue.map((product) => product.code).toSet();
    expect(codes.contains('8690644002007'), isFalse);
    expect(codes.contains('3600531701819'), isFalse);
  });
}
