import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/nutrition.dart';
import 'package:navilo/domain/preference_fit.dart';

void main() {
  test('Reads a Turkish per-100 g table', () {
    final n = parseNutritionTable('''
Besin Değerleri 100 g
Enerji 2245 kJ / 537 kcal
Yağ 31 g
Doymuş yağ 15 g
Karbonhidrat 56 g
Şekerler 52 g
Lif 2,1 g
Protein 6,3 g
Tuz 0,2 g
''')!;
    expect(n.basis, '100g');
    expect(n.source, 'label');
    expect(n.energyKcal, 537);
    expect(n.fat, 31);
    expect(n.saturatedFat, 15);
    expect(n.carbohydrate, 56);
    expect(n.sugars, 52);
    expect(n.fibre, 2.1);
    expect(n.protein, 6.3);
    expect(n.salt, 0.2);
  });

  test('English labels, kJ only and two columns use the first value', () {
    final n = parseNutritionTable('''
Nutrition per 100 g / per 30 g
Energy 1500 kJ
Fat 1.2 g 0.4 g
of which saturates 0.3 g 0.1 g
Carbohydrate 70 g 21 g
of which sugars 12 g 3.6 g
''')!;
    expect(n.energyKcal, 359);
    expect(n.fat, 1.2);
    expect(n.saturatedFat, 0.3);
    expect(n.carbohydrate, 70);
    expect(n.sugars, 12);
  });

  test('Unaccented OCR text and "<0,5 g" are read', () {
    final n = parseNutritionTable('Yag 3 g\nKarbonhidrat 10 g\nSekerler <0,5 g')!;
    expect(n.fat, 3);
    expect(n.sugars, 0.5);
  });

  test('Liquids are recognised from "100 ml"', () {
    final n = parseNutritionTable(
        '100 ml için: Enerji 42 kcal; Yağ 1,5 g; Karbonhidrat 10,6 g; Şekerler 10,6 g')!;
    expect(n.basis, '100ml');
    expect(n.isLiquid, isTrue);
    expect(n.energyKcal, 42);
  });

  test('Columns split by OCR are not reconstructed', () {
    expect(parseNutritionTable('Yağ\nKarbonhidrat\n31 g\n56 g'), isNull);
    expect(parseNutritionTable('Buğday unu, şeker, tuz'), isNull);
  });

  test('Impossible values are dropped, unsaturated fat is not total fat', () {
    final n = parseNutritionTable('''
Yağ 20 g
Tekli doymamış yağ 12 g
Doymuş yağ 25 g
Karbonhidrat 10 g
Şekerler 30 g
''')!;
    expect(n.fat, 20);
    expect(n.saturatedFat, isNull);
    expect(n.sugars, isNull);
  });

  test('Open Food Facts nutriments are read per 100 g', () {
    final n = NutritionFacts.fromOpenFoodFacts(
        {'fat_100g': 1.2, 'sugars_100g': '4.5', 'proteins_100g': -1})!;
    expect(n.source, 'database');
    expect(n.fat, 1.2);
    expect(n.sugars, 4.5);
    expect(n.protein, isNull);
    expect(NutritionFacts.fromOpenFoodFacts({}), isNull);
    expect(NutritionFacts.fromOpenFoodFacts(null), isNull);
  });

  group('Preferences with nutrition values', () {
    PreferenceVerdict check(String pref, NutritionFacts n) =>
        evaluatePreferences(
                {pref}, DietaryFacts(complete: true, nutrition: n), '')
            .single;
    const solid = NutritionFacts(
        basis: '100g', source: 'label', fat: 1.2, sugars: 0.3, carbohydrate: 4);
    const fatty = NutritionFacts(
        basis: '100g', source: 'label', fat: 31, sugars: 52, carbohydrate: 56);
    const drink = NutritionFacts(basis: '100ml', source: 'label', fat: 2);

    test('Low fat follows the 3 g / 1.5 ml claim limits', () {
      expect(check('Az yağlı', solid).status, PreferenceStatus.ingredientsFit);
      expect(check('Az yağlı', fatty).status, PreferenceStatus.conflict);
      expect(check('Az yağlı', drink).status, PreferenceStatus.conflict);
    });

    test('Sugar-free follows the 0.5 g limit, including natural sugars', () {
      expect(check('Şekersiz', solid).status, PreferenceStatus.ingredientsFit);
      expect(check('Şekersiz', fatty).status, PreferenceStatus.conflict);
    });

    test('Ketogenic shows carbohydrate but never decides', () {
      final v = check('Ketojenik', fatty);
      expect(v.status, PreferenceStatus.caution);
      expect(v.message(false), contains('56 g karbonhidrat'));
    });

    test('Without a table these stay not assessable', () {
      for (final pref in ['Az yağlı', 'Ketojenik', 'Şekersiz']) {
        expect(
            evaluatePreferences({pref}, const DietaryFacts(complete: true), '')
                .single
                .status,
            PreferenceStatus.notAssessable,
            reason: pref);
      }
    });
  });
}
