import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/dietary.dart';

void main() {
  final json = jsonDecode(File('assets/dietary.json').readAsStringSync())
      as Map<String, dynamic>;
  final entries =
      (json['entries'] as List).map((e) => DietaryEntry(e)).toList();
  test('Turkish and English aliases map to the same reference', () {
    final wheat = entries.firstWhere((e) => e.id == 'wheat');
    expect(wheat.matches('buğday unu, su'), isTrue);
    expect(wheat.matches('WHEAT FLOUR, water'), isTrue);
    expect(wheat.matches('gluten-free wheat claim'), isFalse);
  });
  test('Oats require review, not automatic gluten classification', () {
    expect(entries.firstWhere((e) => e.id == 'oats').kind, 'oats_check');
  });
  test('FODMAP seed provides potential flags only and valid sources', () {
    for (final e in entries) {
      expect((json['sources'] as Map).containsKey(e.source), isTrue);
      expect(e.names.keys, containsAll(['tr', 'en']));
      if (e.id == 'garlic') expect(e.kind, 'fodmap_potential');
    }
  });
}
