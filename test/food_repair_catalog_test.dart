import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/product_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'Reviewed repair batch resolves offline including distinct GTIN8 variants',
      () async {
    var networkCalls = 0;
    final repo = ProductRepository(loader: (_) async {
      networkCalls++;
      throw StateError('Offline');
    });
    final cocoa = await repo.find('86920124');
    final coconut = await repo.find('86920117');
    expect(cocoa.name, contains('Kakaolu'));
    expect(cocoa.ingredients, contains('Kakaolu Granül'));
    expect(coconut.name, contains('Hindistan Cevizli'));
    expect(coconut.ingredients, contains('Hindistan Cevizi %7'));
    for (final code in [
      '8690504034032',
      '8690526061108',
      '8690849820147',
      '8693374111988',
      '8691313010033',
      '8690828000805',
    ]) {
      expect(await repo.find(code), isNotNull, reason: code);
    }
    expect(networkCalls, 0);
  });

  test('Failed submitted codes are never aliases for reviewed replacements',
      () async {
    final rows =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'))
            as List;
    final codes = rows.map((r) => r['code']).toSet();
    for (final code in [
      '8690526013334',
      '8690504116439',
      '8690526012115',
      '8691349011025',
      '8697412700348',
      '8690736202027',
      '8691512002157',
    ]) {
      expect(codes, isNot(contains(code)), reason: code);
    }
    final reviewed =
        rows.where((r) => r['catalog_batch'] == 'food-repair-20261013');
    expect(reviewed.length, 8);
    for (final row in reviewed) {
      expect(row['ingredient_evidence'], 'full_label_transcription');
      for (final field in ['code', 'name', 'ingredients']) {
        expect(row['field_sources'][field], isNotEmpty);
      }
    }
  });
}
