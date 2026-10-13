import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';
import 'package:navilo/domain/barcode.dart';

Map<String, dynamic> row(String code, {String name = 'Sample'}) => {
      'code': code,
      'name': name,
      'ingredients': 'Su, tuz',
      'source_url': 'https://example.org/product/$code',
      'checked_at': '2026-10-13',
      'source_type': 'retailer',
      'status': 'verified',
      'verified_at': '2026-10-13T00:00:00+03:00',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('All shipped catalog rows pass ingestion without silent rejection',
      () async {
    final food =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'))
            as List;
    final cosmetics =
        jsonDecode(await rootBundle.loadString('assets/curated_cosmetics.json'))
            as List;
    final records = ProductRepository.decodeCuratedRecords(food, cosmetics);
    expect(ProductRepository.curatedDataIssues, isEmpty);
    expect(records, hasLength(food.length + cosmetics.length));
    expect(records['food:86920124']?.name, contains('Kakaolu'));
    expect(records['food:86920117']?.name, contains('Hindistan Cevizli'));
  });
  test('GTIN checksum accepts standard lengths and preserves leading zeros',
      () {
    for (final code in [
      '86920124',
      '036000291452',
      '8682536035880',
      '10012345000017'
    ]) {
      expect(isValidGtin(code), isTrue, reason: code);
      final changed =
          '${code.substring(0, code.length - 1)}${(int.parse(code[code.length - 1]) + 1) % 10}';
      expect(isValidGtin(changed), isFalse, reason: changed);
    }
    for (final code in [
      '',
      '123456789',
      '12345678901',
      '8692012A',
      ' 86920124'
    ]) {
      expect(isValidGtin(code), isFalse, reason: code);
    }
  });

  test('A bad catalog row is reported without hiding valid short GTINs', () {
    final records = ProductRepository.decodeCuratedRecords([
      row('86920124'),
      row('036000291452'),
      row('8682536035881'),
      {...row('8682536035880'), 'category': 'cosmetic'},
      {...row('8690508004246'), 'ingredients': ' '},
      {...row('8690635260393'), 'source_url': ''},
      'not a product',
    ], []);
    expect(records.keys, containsAll(['food:86920124', 'food:036000291452']));
    expect(records, hasLength(2));
    expect(ProductRepository.curatedDataIssues, hasLength(5));
    expect(ProductRepository.curatedDataIssues.join('\n'),
        contains('invalid_gtin'));
    expect(ProductRepository.curatedDataIssues.join('\n'),
        contains('category_mismatch'));
    expect(ProductRepository.curatedDataIssues.join('\n'),
        contains('missing_source'));
  });

  test('Conflicting duplicate GTINs are quarantined rather than overwritten',
      () {
    final records = ProductRepository.decodeCuratedRecords([
      row('86920124', name: 'Variant A'),
      row('86920124', name: 'Variant B'),
      row('86920124', name: 'Variant C'),
      row('036000291452'),
    ], []);
    expect(records.keys, ['food:036000291452']);
    expect(ProductRepository.curatedDataIssues, hasLength(2));
    expect(
        ProductRepository.curatedDataIssues
            .every((x) => x.contains('duplicate_gtin')),
        isTrue);
  });
}
