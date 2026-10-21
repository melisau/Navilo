import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProductRecord> find(String code) {
    var networkCalls = 0;
    final repository = ProductRepository(loader: (_) async {
      networkCalls++;
      return {'status': 0};
    });
    return repository.find(code, category: 'food').then((p) {
      expect(networkCalls, 0, reason: 'catalogue products resolve offline');
      return p;
    });
  }

  test('Harras jalapeño spread resolves offline with its label table',
      () async {
    final p = await find('8695077152299');
    expect(p.name, contains('Jalapeno'));
    expect(p.ingredients, contains('jalapeno biberi (%4)'));
    expect(p.allergens, ['en:milk']);
    final n = p.nutrition!;
    expect(n.source, 'catalogue');
    expect(n.energyKcal, 231);
    expect(n.fat, 21);
    expect(n.saturatedFat, 14);
    expect(n.salt, 1);
    expect(n.energyInconsistent, isFalse);
  });

  test('Aknaz labne resolves offline with its label table', () async {
    final p = await find('8695077007018');
    expect(p.name, contains('Labne'));
    expect(p.ingredients, contains('yoğurt kültürü'));
    final n = p.nutrition!;
    expect(n.energyKcal, 194);
    expect(n.fat, 18);
    expect(n.sugars, 3.5);
    expect(n.energyInconsistent, isFalse);
  });
}
