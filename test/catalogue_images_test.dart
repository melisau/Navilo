import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  test('Evidence images require an exact catalogue identity and HTTPS', () {
    final row = <String, dynamic>{
      'code': '8691190419103',
      'image_url': 'https://shop.goldenrose.com.tr/product.jpg',
      'image_source_url': 'https://shop.goldenrose.com.tr/product',
      'image_evidence': 'catalogue_product_page',
      'image_matched_code': '8691190419103',
      'image_match_method': 'barcode',
    };
    expect(ProductRecord.curatedImage(row), row['image_url']);
    expect(ProductRecord.curatedImage({...row, 'image_match_method': 'name'}),
        row['image_url']);
    expect(ProductRecord.curatedImage({...row, 'image_matched_code': 'other'}),
        isNull);
    expect(ProductRecord.curatedImage({...row, 'image_match_method': 'guess'}),
        isNull);
    expect(
        ProductRecord.curatedImage(
            {...row, 'image_url': 'http://example.com/image.jpg'}),
        isNull);
    expect(
        ProductRecord.curatedImage({...row, 'image_evidence': null}), isNull);
    expect(ProductRecord.curatedImage({'code': row['code']}), isNull);
  });
}
