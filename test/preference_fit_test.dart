import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/dietary.dart';
import 'package:navilo/domain/preference_fit.dart';

final vegan = VeganEntry.decodeAll(File('assets/vegan.json').readAsStringSync());
final dietaryEntries = ((jsonDecode(File('assets/dietary.json').readAsStringSync())
            as Map<String, dynamic>)['entries'] as List)
    .map((e) => DietaryEntry(e as Map<String, dynamic>))
    .toList();
final reference = PreferenceReference(dietaryEntries, vegan);

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

  test('Milk conflicts with vegan even when the label says lactose-free', () {
    final v = checkIngredientText(
            {'Vegan'}, reference, 'Laktozsuz süt, laktaz enzimi',
            evidence: 'Laktozsuz')
        .single;
    expect(v.status, PreferenceStatus.conflict);
    expect(v.evidence, ['Süt ürünü']);
  });

  test('Vegan list finds honey, gelatine and carmine with Turkish forms', () {
    List<String> hits(String text) => listedAnimalIngredients(text, vegan);
    expect(hits('Şeker, sığır jelatini, renklendirici (E120)'),
        containsAll(['Jelatin', 'Karmin / koşnil (E120)']));
    expect(hits('Bal, su'), ['Bal']);
    expect(hits('Ton balığı, zeytinyağı'), ['Balık / kabuklu deniz ürünü']);
    expect(hits('Balık yağı'), ['Balık / kabuklu deniz ürünü']);
  });

  test('Plant milks and cocoa butter are not dairy', () {
    List<String> hits(String text) => listedAnimalIngredients(text, vegan);
    expect(hits('Hindistan cevizi sütü, şeker'), isEmpty);
    expect(hits('Coconut milk powder, cocoa butter, peanut butter'), isEmpty);
    expect(hits('Badem sütü (su, badem)'), isEmpty);
    expect(hits('Coconut milk, skimmed milk powder'), ['Süt ürünü']);
  });

  test('Vegan without animal hits is not assessable, not suitable', () {
    final v = only({'Vegan'}, const DietaryFacts(complete: true),
        'Pirinç, tuz');
    expect(v.status, PreferenceStatus.notAssessable);
  });

  test('Vegan says so when its reference list is missing', () {
    final v = evaluatePreferences(
            {'Vegan'}, const DietaryFacts(complete: true), 'Bal')
        .single;
    expect(v.status, PreferenceStatus.notAssessable);
    expect(v.message(true), contains('could not load'));
  });

  test('Every vegan entry has both names and a known source', () {
    final json = jsonDecode(File('assets/vegan.json').readAsStringSync())
        as Map<String, dynamic>;
    final sources = json['sources'] as Map<String, dynamic>;
    for (final e in vegan) {
      expect(sources.containsKey(e.source), isTrue, reason: e.id);
      expect(e.names.keys, containsAll(['tr', 'en']));
      expect((sources[e.source] as Map)['url'], startsWith('https://'));
    }
  });

  test('Catalogue check flags wheat for gluten-free and nothing for rice', () {
    final wheat = checkIngredientText(
        {'Glutensiz', 'Vegan'}, reference, 'Buğday unu, su, tuz, maya');
    expect(wheat.first.preference, 'Glutensiz');
    expect(wheat.first.status, PreferenceStatus.conflict);
    final rice = checkIngredientText({'Glutensiz'}, reference, 'Pirinç, tuz');
    expect(rice.single.status, isNot(PreferenceStatus.conflict));
    expect(checkIngredientText({}, reference, 'Buğday unu'), isEmpty);
  });

  test('Database label tags count as a claim, not as suitability', () {
    final v = checkIngredientText({'Glutensiz'}, reference, 'Mısır unu',
            labels: ['en:gluten-free'])
        .single;
    expect(v.status, PreferenceStatus.labelClaim);
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

  test('Apple extract, dates and stevia are not added sugar', () {
    for (final text in [
      'Yulaf, elma özü, tarçın',
      'Hurma, badem, kakao',
      'Su, limon, stevia (steviol glikozitleri)',
      'Pirinç, üzüm pekmezi',
    ]) {
      final vs = checkIngredientText(
          {'İlave şekersiz', 'Şekersiz', 'Rafine şekersiz'}, reference, text,
          complete: true);
      expect(vs.where((v) => v.status == PreferenceStatus.conflict), isEmpty,
          reason: text);
      expect(vs.any((v) => v.evidence.isNotEmpty), isTrue, reason: text);
    }
  });

  test('Glucose-fructose syrup and sugar are added sugar', () {
    for (final text in [
      'Su, glikoz-fruktoz şurubu, aroma',
      'Un, şeker, elma özü',
      'Water, glucose syrup',
    ]) {
      final v = checkIngredientText({'İlave şekersiz'}, reference, text,
              complete: true)
          .single;
      expect(v.status, PreferenceStatus.conflict, reason: text);
    }
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

  test('A certification mark turns the FODMAP caution into a label claim',
      () {
    final v = checkIngredientText({'Düşük FODMAP'}, reference, 'Pirinç, soğan',
            evidence: 'Monash University Low FODMAP Certified')
        .single;
    expect(v.status, PreferenceStatus.labelClaim);
    expect(v.evidence, ['Monash University Low FODMAP Certified']);
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
