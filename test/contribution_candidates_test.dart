import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/barcode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('incomplete product research is available for user contribution', () async {
    final rows = jsonDecode(
            await rootBundle.loadString('assets/contribution_candidates.json'))
        as List;
    final ids = rows.map((row) => row['id']).toSet();
    expect(ids.length, rows.length);
    for (final name in [
      'Harras Frambuazlı Cheesecake (650 g)',
      'Harras San Sebastian Cheesecake (500 g)',
      'Sinangil Glutensiz Karabuğdaylı Baton Ekmek (350 g)',
      'Lorenz Chipsletten Paprika Aromalı Patates Cipsi (100 g)',
      'Dimes Şeftali Nektarı (1 L)',
      'Dimes Vişne Nektarı (200 ml)',
      'Cappy Şeftali Nektarı Karton Kutu (200 ml)',
    ]) {
      expect(rows.any((row) => row['name'] == name), isTrue);
    }
  });

  test('Automatic Open Facts candidates carry a valid barcode and source',
      () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/contribution_candidates.json'))
        as List).cast<Map<String, dynamic>>();
    final catalogue = (jsonDecode(
            await rootBundle.loadString('assets/curated_products.json')) as List)
        .map((row) => row['code'])
        .toSet();
    for (final row in rows.where((r) => (r['id'] as String).startsWith('off-gap-'))) {
      final code = row['candidate_barcode'] as String;
      expect(isValidGtin(code), isTrue, reason: code);
      expect(row['id'], 'off-gap-$code');
      expect(catalogue.contains(code), isFalse, reason: code);
      expect(row['missing_fields'], contains('ingredients'));
      expect((row['source_url'] as String).startsWith('https://'), isTrue);
    }
  });
}
