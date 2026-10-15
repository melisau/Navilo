import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

String normalizedLipInci(String text) => text
    .trim()
    .replaceFirst(RegExp(r'^INGREDIENTS\s*:', caseSensitive: false), '')
    .toUpperCase()
    .replaceAll(RegExp(r'[^A-Z0-9]'), '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('100 additional lip products resolve by published barcode without network',
      () async {
    final rows = jsonDecode(
        File('docs/lip_research_extra_20261015/selected_100.json').readAsStringSync())
        as List;
    expect(rows, hasLength(100));
    expect(rows.map((r) => (r['code'] as String).padLeft(14, '0')).toSet(),
        hasLength(100));
    expect(rows.map((r) => r['retailer']).toSet(),
        {'Eve', 'Gratis', 'Rossmann', 'Watsons'});
    var networkCalls = 0;
    final repository = ProductRepository(loader: (_) async {
      networkCalls++;
      return {'status': 0};
    });
    for (final row in rows) {
      final product = await repository.find(row['code'], category: 'cosmetic');
      expect(product.code, row['code']);
      expect(product.name, row['name']);
      expect(normalizedLipInci(product.ingredients),
          normalizedLipInci(row['ingredients']), reason: row['code']);
      expect(normalizedLipInci(product.mayContain),
          normalizedLipInci(row['may_contain'] ?? ''), reason: row['code']);
      expect(product.sourceUrl, row['source_url']);
      expect(product.verificationStatus, 'verified');
      expect(product.nameMatched, isFalse);
    }
    expect(networkCalls, 0);
    final catalogue = await repository.listCurated(category: 'cosmetic');
    final codes = catalogue.map((p) => p.code).toSet();
    expect(rows.every((row) => codes.contains(row['code'])), isTrue);
  });
}
