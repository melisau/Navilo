import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/allergens.dart';
import 'package:navilo/domain/dietary.dart';
import 'package:navilo/domain/preference_fit.dart';

final entries =
    AllergenEntry.decodeAll(File('assets/allergens.json').readAsStringSync());

List<String> containedIds(String text) =>
    findAllergens(text, entries).contains.map((e) => e.id).toList();
List<String> tracedIds(String text) =>
    findAllergens(text, entries).mayContain.map((e) => e.id).toList();

void main() {
  test('All 14 regulated allergens are present with sources', () {
    final json = jsonDecode(File('assets/allergens.json').readAsStringSync())
        as Map<String, dynamic>;
    final sources = json['sources'] as Map<String, dynamic>;
    expect(entries.map((e) => e.id).toSet(), {
      'gluten',
      'crustaceans',
      'eggs',
      'fish',
      'peanuts',
      'soybeans',
      'milk',
      'nuts',
      'celery',
      'mustard',
      'sesame',
      'sulphites',
      'lupin',
      'molluscs',
    });
    for (final e in entries) {
      expect(sources.containsKey(e.source), isTrue, reason: e.id);
      expect(e.names.keys, containsAll(['tr', 'en']));
      expect(e.offTags, isNotEmpty, reason: e.id);
    }
  });

  test('Ingredients and "may contain" statements are kept apart', () {
    const label = 'Buğday unu, şeker, fındık (%8), süt tozu. '
        'Eser miktarda yer fıstığı ve susam içerebilir.';
    expect(containedIds(label), containsAll(['gluten', 'nuts', 'milk']));
    expect(containedIds(label), isNot(contains('peanuts')));
    expect(tracedIds(label), containsAll(['peanuts', 'sesame']));
  });

  test('Decimals do not split sentences', () {
    final parts = splitPrecautionary('Kakao (%3.5), şeker. Süt içerebilir.');
    expect(parts.ingredients, contains('%3.5'));
    expect(parts.precautionary, contains('Süt içerebilir'));
  });

  test('An allergen already in the ingredients is not repeated as a trace',
      () {
    expect(tracedIds('Süt, şeker. Süt içerebilir.'), isEmpty);
  });

  test('Plant look-alikes and exempt forms are not flagged', () {
    expect(containedIds('Hindistan cevizi sütü, kakao yağı'), isEmpty);
    expect(containedIds('Glikoz şurubu (buğday), su'), isEmpty);
    expect(containedIds('Hindistan cevizi, şeker'), isNot(contains('nuts')));
    expect(containedIds('Tam rafine soya yağı'), isEmpty);
  });

  test('Common Turkish forms and E numbers are recognised', () {
    expect(containedIds('Kuru kayısı (koruyucu: kükürt dioksit)'),
        contains('sulphites'));
    expect(containedIds('Sirke, E224'), contains('sulphites'));
    expect(containedIds('Tahin, şeker'), contains('sesame'));
    expect(containedIds('Ton balığı, zeytinyağı'), contains('fish'));
    expect(containedIds('Soya lesitini'), contains('soybeans'));
    expect(containedIds('Gluten içermez. Pirinç unu'), isEmpty);
  });

  test('Only precautionary statements of the raw OCR text count', () {
    final found = findAllergens('Pirinç, tuz', entries,
        extra: 'Pirinç, tuz. Peynir ile servis edin. Fındık içerebilir.');
    expect(found.contains, isEmpty);
    expect(found.mayContain.map((e) => e.id), ['nuts']);
  });

  test('Database tags count as declared allergens and traces', () {
    final found = findAllergens('Şeker', entries,
        allergenTags: ['en:milk'], traceTags: ['en:nuts']);
    expect(found.contains.map((e) => e.id), ['milk']);
    expect(found.mayContain.map((e) => e.id), ['nuts']);
  });

  final dietary = ((jsonDecode(File('assets/dietary.json').readAsStringSync())
              as Map<String, dynamic>)['entries'] as List)
      .map((e) => DietaryEntry(e as Map<String, dynamic>))
      .toList();
  final ref = PreferenceReference(dietary, const [], allergens: entries);

  test('Allergy preferences: contains is a conflict, may contain a caution',
      () {
    final vs = checkIngredientText({
      allergenPreference('milk'),
      allergenPreference('peanuts'),
      allergenPreference('celery'),
    }, ref, 'Süt, şeker. Yer fıstığı içerebilir.', complete: true);
    final byKey = {for (final v in vs) v.preference: v};
    expect(byKey[allergenPreference('milk')]!.status,
        PreferenceStatus.conflict);
    expect(byKey[allergenPreference('peanuts')]!.status,
        PreferenceStatus.caution);
    expect(byKey[allergenPreference('celery')]!.status,
        PreferenceStatus.noneFound);
    expect(vs.first.status, PreferenceStatus.conflict);
    expect(byKey[allergenPreference('milk')]!.title(false, (s) => s), 'Süt');
    expect(byKey[allergenPreference('milk')]!.title(true, (s) => s), 'Milk');
  });

  test('Allergy keys round-trip', () {
    expect(allergenIdOf(allergenPreference('sesame')), 'sesame');
    expect(allergenIdOf('Vegan'), isNull);
  });
}
