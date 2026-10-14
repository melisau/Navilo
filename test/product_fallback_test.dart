import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  test('Food checks OFF first and preserves source text', () async {
    final hosts = <String>[];
    final repo = ProductRepository(loader: (uri) async {
      hosts.add(uri.host);
      return {
        'status': 1,
        'product': {'ingredients_text': 'Milk, sugar'}
      };
    });
    final p = await repo.find('12345670');
    expect(hosts, ['world.openfoodfacts.org']);
    expect(p.ingredients, 'Milk, sugar');
    expect(p.sourceName, 'Open Food Facts');
  });
  test('Missing food products use only food-compatible databases', () async {
    final hosts = <String>[];
    final repo = ProductRepository(loader: (uri) async {
      hosts.add(uri.host);
      return {
        'status': 0,
      };
    });
    await expectLater(
        repo.find('12345670'),
        throwsA(isA<ProductLookupException>()
            .having((e) => e.attempts.length, 'attempt count', 4)));
    expect(hosts, [
      'world.openfoodfacts.org',
      'world.openproductsfacts.org',
      'world.openpetfoodfacts.org'
    ]);
  });

  test('A cosmetic barcode lookup does not query food databases', () async {
    final hosts = <String>[];
    final repo = ProductRepository(loader: (uri) async {
      hosts.add(uri.host);
      return {
        'status': 1,
        'product': {'ingredients_text': 'Aqua, Parfum'}
      };
    });
    expect((await repo.find('12345670', category: 'cosmetic')).sourceName,
        'Open Beauty Facts');
    expect(hosts, ['world.openbeautyfacts.org']);
  });

  test('Accepts a later source only when status and ingredients are present',
      () async {
    final hosts = <String>[];
    final repo = ProductRepository(loader: (uri) async {
      hosts.add(uri.host);
      if (uri.host != 'world.openpetfoodfacts.org') {
        return {
          'status': 1,
          'product': {'product_name': 'No ingredients'}
        };
      }
      return {
        'status': 1,
        'product': {
          'product_name': 'Example product',
          'ingredients_text': 'Rice, salt'
        }
      };
    });
    final product = await repo.find('12345670');
    expect(hosts, [
      'world.openfoodfacts.org',
      'world.openproductsfacts.org',
      'world.openpetfoodfacts.org'
    ]);
    expect(product.sourceName, 'Open Pet Food Facts');
    expect(product.ingredients, 'Rice, salt');
  });

  test(
      'Barcode name lookup offers ingredient candidates without auto-selecting',
      () async {
    final calls = <Uri>[];
    final repo = ProductRepository(loader: (uri) async {
      calls.add(uri);
      if (uri.host == 'api.upcitemdb.com') {
        expect(uri.path, '/prod/trial/lookup');
        return {
          'code': 'OK',
          'items': [
            {'title': 'Oat Drink', 'brand': 'Sample Brand'}
          ]
        };
      }
      if (uri.host == 'world.openfoodfacts.org') {
        expect(uri.path, '/cgi/search.pl');
        expect(uri.queryParameters['search_terms'], 'Sample Brand Oat Drink');
        expect(
            uri.queryParameters['countries_tags_en'], anyOf('turkey', isNull));
        return {
          'products': [
            {
              'code': '036000291452',
              'product_name': 'Sample Brand Oat Drink',
              'ingredients_text': 'Water, oats, salt',
              'last_modified_t': 1791782400
            },
            {'code': '8691234567007', 'product_name': 'Missing ingredients'}
          ]
        };
      }
      return {'products': []};
    });

    final candidates =
        await repo.findNameCandidates(barcode: '10012345000017', english: true);
    expect(candidates, hasLength(1));
    expect(candidates.single.code, '036000291452');
    expect(candidates.single.nameMatched, isTrue);
    expect(candidates.single.nameLookupSource, 'UPCitemdb');
    expect(candidates.single.sourceName, 'Open Food Facts');
    expect(calls.length, 7);
    final searches =
        calls.where((uri) => uri.path == '/cgi/search.pl').toList();
    expect(
        searches.take(3).every(
            (uri) => uri.queryParameters['countries_tags_en'] == 'turkey'),
        isTrue);
    expect(
        searches.skip(3).every(
            (uri) => !uri.queryParameters.containsKey('countries_tags_en')),
        isTrue);
    expect(searches.map((uri) => uri.host).toSet(), hasLength(3));
  });
}
