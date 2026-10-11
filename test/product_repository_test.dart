import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  test(
      'Empty translated field falls back, preserves original ingredients and evidence',
      () {
    final p = ProductRecord.parse('12345678', {
      'status': 1,
      'product': {
        'ingredients_text_tr': '',
        'ingredients_text': 'Dimethicone, Parfum',
        'allergens_tags': ['en:milk'],
        'traces_tags': ['en:gluten'],
        'labels_tags': ['en:lactose-free'],
        'last_modified_t': 1000
      }
    });
    expect(p.ingredients, 'Dimethicone, Parfum');
    expect(p.allergens, ['en:milk']);
    expect(p.traces, ['en:gluten']);
    expect(p.modified, isNotNull);
  });
  test('Unknown product or missing ingredients never yields analysis data', () {
    expect(() => ProductRecord.parse('12345678', {'status': 0}),
        throwsFormatException);
    expect(() => ProductRecord.parse('12345678', {'status': 1, 'product': {}}),
        throwsFormatException);
  });
}
