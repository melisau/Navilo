import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';
import 'package:navilo/domain/barcode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bundled Turkish products have unique valid GTINs and source evidence',
      () async {
    final rows =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'))
            as List;
    final codes = <String>{};
    for (final row in rows) {
      final code = row['code'] as String;
      expect(isValidGtin(code), isTrue, reason: code);
      expect(codes.add(code), isTrue, reason: 'Duplicate $code');
      expect((row['ingredients'] as String).trim(), isNotEmpty);
      expect((row['name'] as String).trim(), isNotEmpty);
      expect(Uri.parse(row['source_url'] as String).scheme, 'https');
      expect(DateTime.tryParse(row['checked_at'] as String), isNotNull);
    }
  });

  test('New Turkish brand barcodes resolve offline with their original content',
      () async {
    var networkCalls = 0;
    final repo = ProductRepository(loader: (_) async {
      networkCalls++;
      throw StateError('Offline');
    });
    for (final sample in {
      '8682696010031': 'sukraloz',
      '8690998112124': 'çiçek balı',
      '8690575010812': 'domates',
      '8690368023012': 'siyah çay',
      '8681324005449': 'inek sütü',
      '8690504429210': 'kefir',
      '8690684001039': 'irmiği',
      '8691440101000': 'bulgur',
      '8683200063314': 'bal',
      '8681630301013': 'fındık',
      '8683555359605': 'bezelye proteini',
      '8682368978676': 'şeker',
      '8690526011073': 'laktoz',
      '8696368011349': 'çilek',
      '8696368202457': 'yulaf',
      '8690565017531': 'vanilya',
      '8692971435664': 'kahve',
      '8692971435626': 'çilek',
      '8690767160127': 'yoğurt mayası',
      '8692886411265': 'laktaz',
      '8684000453503': 'inek sütü',
      '8684000451240': 'yoğurt kültürü',
    }.entries) {
      final product = await repo.find(sample.key);
      expect(product.code, sample.key);
      expect(product.ingredients.toLowerCase(), contains(sample.value));
      expect(product.nameMatched, isFalse);
      expect(product.sourceUrl, startsWith('https://'));
    }
    expect(networkCalls, 0);
  });

  test('Coffee and strawberry protein milks keep distinct GTINs and formulas',
      () async {
    final repo = ProductRepository(loader: (_) async => {'status': 0});
    final coffee = await repo.find('8692971435664');
    final strawberry = await repo.find('8692971435626');
    expect(coffee.name, contains('Kahveli'));
    expect(coffee.ingredients, contains('kahve'));
    expect(strawberry.name, contains('Çilekli'));
    expect(strawberry.ingredients, contains('çilek'));
    expect(strawberry.ingredients, isNot(contains('kahve')));
    for (final milk in [coffee, strawberry]) {
      expect(milk.allergens, contains('milk'));
      expect(milk.labels, contains('en:lactose-free'));
    }
  });

  test('Curated image retains its separate OFF attribution and milk formula',
      () async {
    final repo =
        ProductRepository(loader: (_) async => throw StateError('Offline'));
    final product = await repo.find('8695077112583');
    expect(
        product.imageUrl,
        startsWith(
            'https://images.openfoodfacts.org/images/products/869/507/711/2583/'));
    expect(product.imageSourceUrl,
        'https://world.openfoodfacts.org/product/8695077112583');
    expect(product.ingredients, isNotEmpty);
    expect(product.ingredients.toLowerCase(), contains('süt'));
    final cosmetics = await repo.listCurated(category: 'cosmetic');
    final withImages = cosmetics.where((p) => p.imageUrl != null).toList();
    expect(withImages, isNotEmpty);
    expect(withImages.every((p) => p.imageSourceUrl?.startsWith('https://') == true),
        isTrue);
  });
}
