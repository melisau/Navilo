import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/preference_fit.dart';

PreferenceVerdict only(Set<String> prefs, DietaryFacts facts,
        [String text = '']) =>
    evaluatePreferences(prefs, facts, text).single;

void main() {
  test('No preferences produce no verdicts', () {
    expect(evaluatePreferences({}, const DietaryFacts(), 'buğday unu'),
        isEmpty);
  });

  test('Listed gluten source conflicts with gluten-free preference', () {
    final v = only({'Glutensiz'},
        const DietaryFacts(glutenSources: ['Buğday'], complete: true));
    expect(v.status, PreferenceStatus.conflict);
    expect(v.evidence, ['Buğday']);
  });

  test('Gluten source wins over a gluten-free label claim', () {
    final v = only(
        {'Glutensiz'},
        const DietaryFacts(
            glutenSources: ['Arpa'], glutenClaim: true, complete: true));
    expect(v.status, PreferenceStatus.conflict);
  });

  test('No gluten found is never reported as suitable', () {
    final v = only({'Glutensiz'}, const DietaryFacts(complete: true));
    expect(v.status, PreferenceStatus.noneFound);
    expect(v.message(false), contains('kanıtlamaz'));
  });

  test('Unconfirmed lists say the text may be incomplete', () {
    final v = only({'Laktozsuz'}, const DietaryFacts());
    expect(v.status, PreferenceStatus.noneFound);
    expect(v.message(true), contains('not confirmed complete'));
  });

  test('Lactose-free claim is a label claim, not a conflict', () {
    final v = only(
        {'Laktozsuz'},
        const DietaryFacts(
            lactoseSources: ['Süt'],
            lactoseFree: true,
            lactoseClaim: true,
            complete: true));
    expect(v.status, PreferenceStatus.labelClaim);
  });

  test('Milk conflicts with vegan even when lactose-free', () {
    final v = only(
        {'Vegan'},
        const DietaryFacts(
            lactoseFree: true, milkIngredients: ['Süt'], complete: true));
    expect(v.status, PreferenceStatus.conflict);
  });

  test('Vegan detects honey, gelatin and carmine but not "balık" as honey',
      () {
    expect(listedAnimalIngredients('Şeker, jelatin, E120'),
        containsAll(['Jelatin / gelatin', 'Karmin / carmine']));
    expect(listedAnimalIngredients('Bal, su'), ['Bal / honey']);
    expect(listedAnimalIngredients('Balık yağı'), ['Balık / fish']);
  });

  test('Vegan without animal hits is not assessable, not suitable', () {
    final v = only({'Vegan'}, const DietaryFacts(complete: true),
        'Pirinç, tuz');
    expect(v.status, PreferenceStatus.notAssessable);
  });

  test('Refined sugar preference ignores honey but flags sugar', () {
    final honey = only({'Rafine şekersiz'},
        const DietaryFacts(sugarAdditions: ['bal'], complete: true));
    expect(honey.status, PreferenceStatus.noneFound);
    final sugar = only({'Rafine şekersiz'},
        const DietaryFacts(sugarAdditions: ['şeker', 'bal'], complete: true));
    expect(sugar.status, PreferenceStatus.conflict);
    expect(sugar.evidence, ['şeker']);
  });

  test('Sugar-free without additions still needs the nutrition table', () {
    final v = only({'Şekersiz'}, const DietaryFacts(complete: true));
    expect(v.status, PreferenceStatus.notAssessable);
  });

  test('Ketogenic and low-fat are never judged from ingredients', () {
    final vs = evaluatePreferences(
        {'Ketojenik', 'Az yağlı'}, const DietaryFacts(complete: true), '');
    expect(vs.map((v) => v.status),
        everyElement(PreferenceStatus.notAssessable));
  });

  test('FODMAP is always a caution', () {
    expect(only({'Düşük FODMAP'}, const DietaryFacts(fodmapSources: ['Soğan']))
        .status, PreferenceStatus.caution);
    expect(only({'Düşük FODMAP'}, const DietaryFacts(simpleRice: true)).status,
        PreferenceStatus.caution);
  });

  test('Conflicts are listed before other verdicts', () {
    final vs = evaluatePreferences({
      'Ketojenik',
      'Glutensiz',
      'Laktozsuz'
    }, const DietaryFacts(lactoseSources: ['Süt'], complete: true), '');
    expect(vs.first.preference, 'Laktozsuz');
    expect(vs.first.status, PreferenceStatus.conflict);
    expect(vs.last.status, PreferenceStatus.notAssessable);
  });
}
