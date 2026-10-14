import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('verified eye palettes are available in the curated catalog', () async {
    final rows = (jsonDecode(
            await rootBundle.loadString('assets/curated_cosmetics.json')) as List)
        .cast<Map<String, dynamic>>();

    final flormar = rows
        .singleWhere((row) => row['code'] == '8682536048477');
    expect(flormar['name'], contains('Nude Dude'));
    expect(flormar['ingredients'], contains('TALC'));
    expect(flormar['may_contain'], contains('CI 75470'));

    final burgundy = rows
        .singleWhere((row) => row['code'] == '3600531429911');
    expect(burgundy['name'], contains('Burgundy Bar'));
    expect(burgundy['ingredients'], contains('PHENOXYETHANOL'));
    expect(burgundy['may_contain'], contains('CI 75470'));
  });

  test('unresolved cosmetic research remains editable contribution data',
      () async {
    final rows = (jsonDecode(await rootBundle
            .loadString('assets/contribution_candidates.json')) as List)
        .cast<Map<String, dynamic>>();

    final nudes = rows
        .singleWhere((row) => row['id'] == 'candidate-maybelline-the-nudes');
    expect(nudes['category'], 'cosmetic');
    expect(nudes['candidate_barcode'], '3600531199081');
    expect(nudes['known_ingredients'], contains('TALC'));
    expect(nudes['missing_fields'], contains('package_photo'));

    expect(
        rows.any((row) => row['id'] == 'candidate-loreal-le-shadow-stick-120'),
        isTrue);
    expect(
        rows.any((row) => row['id'] == 'candidate-beaulis-eyeshadow-159'),
        isTrue);
  });
}
