import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/ingredient_text.dart';

void main() {
  test('German ingredients exclude recipe before heading and trace statement',
      () {
    final p = IngredientText.parse(
        'Rezept: 200 ml Sahne\nZutaten: 47 % Zwiebeln, Stärke, Knoblauch.\nKann Spuren von Gluten, Milch enthalten.');
    expect(p.ingredients, contains('Zwiebeln'));
    expect(p.ingredients, isNot(contains('Sahne')));
    expect(p.ingredients, isNot(contains('Gluten')));
  });
  test('Both ingredient languages retained, allergens separate', () {
    final p = IngredientText.parse(
        'İçindekiler: Fındık, Tam Yağlı Süt Tozu, Hindiba Kökü Lifi.\nIngredients: Hazelnuts, Whole Milk Powder, Chicory Root Fiber.\nAlerjen beyanı: Süt içerir.');
    expect(p.ingredients, contains('Hindiba'));
    expect(p.ingredients, contains('Chicory'));
    expect(p.ingredients, isNot(contains('beyanı')));
  });
  test('Flour claim excluded and raw preserved', () {
    const raw =
        'İçindekiler: Mısır nişastası, pirinç unu.\nGluten miktarı 20mg/kg geçmez.\nEnerji ve Besin Öğeleri';
    final p = IngredientText.parse(raw);
    expect(p.raw, raw);
    expect(p.ingredients, isNot(contains('Gluten miktarı')));
  });
  test('Heading missing preserves text without inventing list', () {
    final p = IngredientText.parse('blurred text');
    expect(p.headingFound, false);
    expect(p.ingredients, 'blurred text');
  });
  test('Flags a suspiciously short OCR result for manual review', () {
    expect(IngredientText.reviewIssues('sugar'), contains('too_short'));
    expect(IngredientText.reviewIssues('sugar, cocoa'),
        isNot(contains('too_short')));
  });
  test('Cleans OCR spacing without changing ingredient words', () {
    expect(IngredientText.cleanOcr('sugar   ,  cocoa'), 'sugar , cocoa');
    expect(IngredientText.cleanOcr('hydro-\ngenated oil'), 'hydrogenated oil');
  });
}
