import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/community_submission.dart';
import 'package:navilo/data/local_product_store.dart';

void main() {
  late Directory dir;
  late LocalProductStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('navilo_store_ids_');
    store = LocalProductStore(dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  LocalProduct product(String id, {String barcode = '', String? category}) =>
      LocalProduct(
          id: id,
          barcode: barcode,
          category: category ?? 'food',
          name: 'Test',
          ingredients: 'pirinç, tuz',
          reviewedAt: DateTime.utc(2026, 11, 14));

  test('every contribution candidate can be saved under its own id', () async {
    final rows = (jsonDecode(
                File('assets/contribution_candidates.json').readAsStringSync())
            as List)
        .cast<Map<String, dynamic>>();
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final id = row['id'] as String;
      final category = row['category'] as String;
      await store.save(product(id, category: category));
      expect((await store.find(id, category))?.id, id, reason: id);
      await store.remove(id, category);
    }
  });

  test('candidate records are listed and found by their linked barcode',
      () async {
    await store
        .save(product('off-gap-8684252201457', barcode: '8684252201457'));
    await store.save(product('candidate-harras-brownie'));
    expect((await store.recent(limit: null)).map((p) => p.id),
        containsAll(['off-gap-8684252201457', 'candidate-harras-brownie']));
    expect((await store.findByBarcode('8684252201457', 'food'))?.id,
        'off-gap-8684252201457');
  });

  test('ids that could leave the store directory are rejected', () async {
    for (final id in [
      '../escape',
      'local-../x',
      'candidate-a/b',
      r'candidate-a\b',
      'candidate-A',
      'candidate-',
      'other-123',
      'local-${'1' * 120}',
    ]) {
      expect(() => store.save(product(id)), throwsArgumentError, reason: id);
    }
  });

  test('a damaged record can still be removed', () async {
    File('${dir.path}/food-8690000000005.json').writeAsStringSync('{broken');
    await store.remove('8690000000005', 'food');
    expect(File('${dir.path}/food-8690000000005.json').existsSync(), isFalse);
  });

  test('only real GTINs are accepted for shared submission', () {
    expect(CommunitySubmission.accepts('8684252201457'), isTrue);
    expect(CommunitySubmission.accepts('8684252201458'), isFalse);
    expect(CommunitySubmission.accepts('12345678901'), isFalse);
    expect(CommunitySubmission.accepts(''), isFalse);
  });
}
