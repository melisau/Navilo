import 'dart:io';
import 'package:navilo/data/product_repository.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  for (final category in ['food', 'cosmetic']) {
    var calls = 0;
    final host = category == 'food'
        ? 'world.openfoodfacts.org'
        : 'world.openbeautyfacts.org';
    final repo = ProductRepository(loader: (uri) async {
      calls++;
      check(uri.host == host, 'Incorrect provider');
      return {
        'status': 1,
        'product': {'ingredients_text': 'Original ingredients'}
      };
    });
    final p = await repo.find('12345678', category: category);
    check(
        calls == 1 &&
            p.ingredients == 'Original ingredients' &&
            p.sourceUrl.contains(host),
        'Source and preservation');
  }
  var calls = 0;
  try {
    await ProductRepository(loader: (uri) async {
      calls++;
      return {
        'status': 1,
        'product': {'product_name': 'Test'}
      };
    }).find('12345678');
    throw StateError('Missing ingredients accepted');
  } on ProductLookupException catch (e) {
    check(
        calls == 1 &&
            e.attempts.length == 1 &&
            e.attempts.single.contains('Ürün bulundu'),
        'Missing content / single provider');
  }
  check(
      ProductRepository.failureMessage(ProductServiceException(429))
          .contains('429'),
      'Quota diagnostics');
  stdout.writeln(
      'PASS: food provider, cosmetic provider, original text, provenance, missing-content diagnostics and no secondary requests.');
}
