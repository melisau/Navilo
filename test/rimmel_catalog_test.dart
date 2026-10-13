import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'Rimmel barcode resolves offline with sourced INCI and possible pigments',
      () async {
    var networkCalls = 0;
    final repo = ProductRepository(loader: (_) async {
      networkCalls++;
      return {'status': 0};
    });
    final product = await repo.find('3616303392086', category: 'cosmetic');
    expect(product.name, 'Rimmel Kind & Free Clean Mascara 001 Black');
    expect(product.ingredients, contains('PHENETHYL ALCOHOL'));
    expect(product.ingredients,
        contains('LEUCONOSTOC/RADISH ROOT FERMENT FILTRATE'));
    expect(product.ingredients, contains('BIOTIN'));
    expect(product.ingredients, isNot(contains('PHENOXYETHANOL')));
    expect(product.ingredients, isNot(contains('CI 77499')));
    expect(product.mayContain, contains('CI 77499'));
    expect(product.sourceUrl, startsWith('https://www.rimmellondon.com/'));
    expect(networkCalls, 0);
    await expectLater(repo.find('3607349631611', category: 'cosmetic'),
        throwsA(isA<ProductLookupException>()));
  });
}
