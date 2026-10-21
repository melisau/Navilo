import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/ingredient_text.dart';
import 'package:navilo/domain/policy.dart';
import 'package:navilo/domain/preference_fit.dart';

void main() {
  group('E numbers', () {
    test('Spaced, hyphenated and dotted forms are one token', () {
      for (final text in [
        'Renklendirici (E120)',
        'Renklendirici (E 120)',
        'Renklendirici (E-120)',
        'Renklendirici (E.120)',
        'Renklendirici (e 120)',
      ]) {
        expect(containsIngredient(text, 'e120'), isTrue, reason: text);
      }
      expect(containsIngredient('Renklendirici (E120)', 'E 120'), isTrue);
    });

    test('OCR letter O inside an E number is read as zero', () {
      expect(containsIngredient('Renklendirici (E12O)', 'e120'), isTrue);
      expect(containsIngredient('Tatlandırıcı (E 965)', 'e965'), isTrue);
    });

    test('Letter suffixes and longer numbers stay distinct', () {
      expect(containsIngredient('Renklendirici (E 160 a)', 'e160a'), isTrue);
      expect(containsIngredient('Kıvam artırıcı (E1200)', 'e120'), isFalse);
      expect(containsIngredient('Asitlik düzenleyici (E 330)', 'e330'), isTrue);
    });

    test('Vitamin E amounts are not E numbers', () {
      expect(containsIngredient('Vitamin E 100 mg', 'e100'), isFalse);
    });
  });

  group('Turkish letters dropped by OCR', () {
    test('Unaccented text still matches accented aliases', () {
      expect(containsIngredient('Seker, sut tozu', 'şeker'), isTrue);
      expect(containsIngredient('Seker, sut tozu', 'süt tozu'), isTrue);
      expect(containsIngredient('Findik, kakao', 'fındık'), isTrue);
    });

    test('Negation still works on unaccented text', () {
      expect(containsIngredient('Gluten icermez', 'gluten'), isFalse);
      expect(containsIngredient('Gluten içermez', 'gluten'), isFalse);
    });

    test('Whole-word matching is unchanged', () {
      expect(containsIngredient('Balık yağı', 'bal'), isFalse);
      expect(containsIngredient('Maltitol', 'malt'), isFalse);
    });
  });

  group('Nested ingredients and percentages', () {
    test('Ingredients inside parentheses are matched', () {
      const label = 'Sütlü çikolata %40 (şeker, kakao yağı, süt tozu, '
          'emülgatör (soya lesitini)), fındık (%13)';
      expect(containsIngredient(label, 'süt tozu'), isTrue);
      expect(containsIngredient(label, 'fındık'), isTrue);
      expect(containsIngredient(label, 'soya lesitini'), isTrue);
    });

    test('Percentages next to names do not block a match', () {
      expect(containsIngredient('Fındık%13, şeker', 'fındık'), isTrue);
      expect(containsIngredient('Süt tozu (%5,5)', 'süt tozu'), isTrue);
    });

    test('Hyphenated OCR line breaks are joined before matching', () {
      final text = IngredientText.cleanOcr('Şeker, mal-\ntitol, kakao');
      expect(containsIngredient(text, 'maltitol'), isTrue);
    });
  });

  test('The policy finds maltitol written as a spaced E number', () {
    final policy = Policy.decode(File('assets/policy.json').readAsStringSync());
    expect(policy.evaluate('Tatlandırıcı (E 965), kakao', 'food').map((r) => r.id),
        contains('maltitol'));
  });

  group('Vegan additives', () {
    final vegan =
        VeganEntry.decodeAll(File('assets/vegan.json').readAsStringSync());

    test('Beeswax and shellac are animal-derived; beeswax is not honey', () {
      expect(listedAnimalIngredients('Parlatıcı (E 904), şeker', vegan),
          ['Şellak (E904)']);
      expect(listedAnimalIngredients('Kaplama: balmumu', vegan),
          ['Balmumu (E901)']);
      expect(listedAnimalIngredients('Kaplama: bal mumu', vegan),
          ['Balmumu (E901)']);
    });

    test('E471 and flavourings are "possibly animal", not a conflict', () {
      const text = 'Şeker, emülgatör (E 471), aroma';
      expect(listedAnimalIngredients(text, vegan), isEmpty);
      expect(listedPossiblyAnimal(text, vegan), hasLength(2));
      final v = evaluatePreferences(
              {'Vegan'}, const DietaryFacts(complete: true), text,
              vegan: vegan)
          .single;
      expect(v.status, PreferenceStatus.caution);
    });

    test('Soy or sunflower lecithin is plant-based', () {
      for (final text in [
        'Emülgatör (soya lesitini)',
        'Soya lesitini (E322)',
        'Emülgatör: lesitinler (ayçiçeği)',
        'Emulsifier (sunflower lecithin)',
      ]) {
        expect(listedPossiblyAnimal(text, vegan), isEmpty, reason: text);
      }
      expect(listedPossiblyAnimal('Emülgatör (lesitin)', vegan),
          ['Lesitin (E322) — yumurtadan olabilir']);
    });
  });
}
