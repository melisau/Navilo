import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';
import 'package:navilo/domain/catalogue_provenance.dart';

Map<String, dynamic> evidenceRow() => {
      'code': '036000291452',
      'name': 'Sample',
      'ingredients': 'Water',
      'category': 'food',
      'source_type': 'retailer',
      'source_url': 'https://example.org/product/036000291452',
      'checked_at': '2026-10-12T00:00:00Z',
      'verified_at': '2026-10-12T00:00:00Z',
      'status': 'verified',
    };

void main() {
  test('Unverified, sourceless and undated evidence never enters results', () {
    for (final change in [
      {'status': 'unverified'},
      {'status': null},
      {'source_url': ''},
      {'source_url': 'http://example.org/product'},
      {'source_type': null},
      {'verified_at': null},
      {'verified_at': '2099-01-01T00:00:00Z'},
      {'verified_at': '2026-10-12'},
      {'catalog_batch': 'processed-meat-20261013'},
    ]) {
      final row = {...evidenceRow(), ...change};
      expect(hasVerifiedSource(row), isFalse, reason: '$change');
      expect(ProductRepository.decodeCuratedRecords([row], []), isEmpty);
    }
    expect(ProductRepository.decodeCuratedRecords([evidenceRow()], []),
        hasLength(1));
  });

  test(
      'All 150 quarantined rows remain blocked even if someone marks them verified',
      () async {
    final rows = jsonDecode(
            File('data/quarantine/processed_meat_150.json').readAsStringSync())
        as List;
    expect(rows, hasLength(150));
    final forged =
        rows.map((r) => {...evidenceRow(), 'code': r['code']}).toList();
    expect(ProductRepository.decodeCuratedRecords(forged, []), isEmpty);
    var requests = 0;
    final repo = ProductRepository(loader: (_) async {
      requests++;
      return {'status': 0};
    });
    for (final row in rows) {
      expect(row['status'], 'unverified');
      await expectLater(repo.find(row['code']), throwsFormatException);
    }
    await expectLater(repo.find('8690527021149'), throwsFormatException);
    expect(requests, 0);
  });

  test('Invalid GTIN never reaches a provider or title lookup', () async {
    var requests = 0;
    final repo = ProductRepository(loader: (_) async {
      requests++;
      return {};
    });
    await expectLater(repo.find('12345678'), throwsFormatException);
    await expectLater(
        repo.findNameCandidates(barcode: '12345678'), throwsFormatException);
    expect(requests, 0);
  });
}
