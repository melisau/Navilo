import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/dietary.dart';

void main() {
  test('User hazelnut spread flags chicory in both languages', () {
    final j = jsonDecode(File('assets/dietary.json').readAsStringSync())
        as Map<String, dynamic>;
    final entry = (j['entries'] as List)
        .map((e) => DietaryEntry(e))
        .firstWhere((e) => e.id == 'inulin_chicory');
    expect(
        entry.matches('Fındık, Tam Yağlı Süt Tozu, Hindiba Kökü Lifi'), true);
    expect(entry.matches('Hazelnuts, Chicory Root Fiber'), true);
    expect(entry.matches('Mısır nişastası, pirinç unu, guar gam'), false);
  });
  final json = jsonDecode(File('assets/dietary.json').readAsStringSync())
      as Map<String, dynamic>;
  final entries =
      (json['entries'] as List).map((e) => DietaryEntry(e)).toList();
  test('Turkish and English aliases map to the same reference', () {
    final wheat = entries.firstWhere((e) => e.id == 'wheat');
    expect(wheat.matches('buğday unu, su'), isTrue);
    expect(wheat.matches('Buğday unu [buğday unu (gluten) içerir'), isTrue);
    expect(wheat.matches('WHEAT FLOUR, water'), isTrue);
    expect(wheat.matches('gluten-free, wheat flour'), isTrue);
    expect(wheat.matches('lactose free, wheat flour'), isTrue);
  });
  test('Oats require review, not automatic gluten classification', () {
    expect(entries.firstWhere((e) => e.id == 'oats').kind, 'oats_check');
  });
  test('Lactose ingredients are included as review references', () {
    expect(
      entries.where((e) => e.kind == 'lactose_check').map((e) => e.id),
      containsAll(['milk', 'milk_powder', 'whey', 'lactose']),
    );
    expect(
        entries.firstWhere((e) => e.id == 'milk').matches('Süt tozu'), isTrue);
  });
  test('FODMAP seed provides potential flags only and valid sources', () {
    for (final e in entries) {
      expect((json['sources'] as Map).containsKey(e.source), isTrue);
      expect(e.names.keys, containsAll(['tr', 'en']));
      if (e.id == 'garlic') expect(e.kind, 'fodmap_potential');
    }
  });
  List<String> ids(String text) =>
      entries.where((e) => e.matches(text)).map((e) => e.id).toList();

  test('Polyols are FODMAP sources, by name and E number', () {
    expect(ids('Kakao, tatlandırıcı (maltitol), süt tozu'), contains('maltitol'));
    expect(ids('Sweetener: sorbitol, xylitol'), containsAll(['sorbitol', 'xylitol']));
    expect(ids('Tatlandırıcılar (E420, E953)'), containsAll(['sorbitol', 'isomalt']));
  });

  test('Fructose sources and legumes are flagged', () {
    expect(ids('Yulaf, bal'), contains('honey_fructose'));
    expect(ids('Su, glikoz-fruktoz şurubu'), contains('hfcs'));
    expect(ids('Nohut unu, su, tuz'), contains('chickpea'));
    expect(ids('Kırmızı mercimek, pirinç'), contains('legumes'));
    expect(ids('Sebze tozu, tuz'), contains('vegetable_powder'));
    expect(ids('Pirinç, tuz'), isEmpty);
  });

  test('Plain words are not mistaken for FODMAP sources', () {
    expect(ids('Balık, tuz'), isNot(contains('honey_fructose')));
    expect(ids('Mısır unu, su'), isEmpty);
  });

  test('Low-FODMAP certification wording is recognised, not inferred', () {
    expect(lowFodmapCertification('Monash University Low FODMAP Certified™'),
        'Monash University Low FODMAP Certified');
    expect(lowFodmapCertification('FODMAP Friendly'), 'FODMAP Friendly');
    expect(lowFodmapCertification('Düşük FODMAP sertifikalı'),
        'Low FODMAP certified');
    expect(lowFodmapCertification('Low FODMAP'), isNull);
    expect(lowFodmapCertification('Pirinç, tuz'), isNull);
    expect(lowFodmapCertification('', labels: ['en:fodmap-friendly']),
        isNotNull);
  });
}
