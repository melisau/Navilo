import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  test('Food uses OFF only, preserving source text', () async {
    final hosts = <String>[];
    final repo = ProductRepository(loader: (uri) async {
      hosts.add(uri.host);
      return {
        'status': 1,
        'product': {'ingredients_text': 'Milk, sugar'}
      };
    });
    final p = await repo.find('12345678');
    expect(hosts, ['world.openfoodfacts.org']);
    expect(p.ingredients, 'Milk, sugar');
    expect(p.sourceName, 'Open Food Facts');
  });
  test('Missing ingredients does not query additional paid/demo services',
      () async {
    var calls = 0;
    final repo = ProductRepository(loader: (uri) async {
      calls++;
      return {
        'status': 1,
        'product': {'product_name': 'Test'}
      };
    });
    await expectLater(
        repo.find('12345678'),
        throwsA(isA<ProductLookupException>().having(
            (e) => e.attempts.single, 'details', contains('Ürün bulundu'))));
    expect(calls, 1);
  });
  test('Cosmetics query beauty source', () async {
    final repo = ProductRepository(loader: (uri) async {
      expect(uri.host, 'world.openbeautyfacts.org');
      return {
        'status': 1,
        'product': {'ingredients_text': 'Aqua, Parfum'}
      };
    });
    expect((await repo.find('12345678', category: 'cosmetic')).sourceName,
        'Open Beauty Facts');
  });
}
