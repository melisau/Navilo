import 'dart:convert';

import 'dietary.dart';
import 'dietary_analysis.dart';
import 'policy.dart';

/// How a product's reviewed ingredient text relates to one saved preference.
///
/// The order is also the display order: conflicts first, then cautions.
/// There is deliberately no "suitable" status: the text alone can show a
/// conflict, or show that none was found, but never proves suitability.
enum PreferenceStatus {
  /// The text lists something that goes against the preference.
  conflict,

  /// Only a portion or amount decides; the text cannot settle it.
  caution,

  /// The label claims it (e.g. "glutensiz"); not independently verified.
  labelClaim,

  /// Every recognised ingredient fits (e.g. plain rice and salt).
  ingredientsFit,

  /// Nothing conflicting was found in the listed ingredients.
  noneFound,

  /// This preference cannot be judged from an ingredient list.
  notAssessable,
}

class PreferenceVerdict {
  final String preference;
  final PreferenceStatus status;
  final String tr, en;
  final List<String> evidence;
  const PreferenceVerdict(this.preference, this.status, this.tr, this.en,
      [this.evidence = const []]);
  String message(bool english) => english ? en : tr;
}

/// Facts the dietary panel already derives from the reviewed text.
class DietaryFacts {
  final List<String> glutenSources;
  final bool glutenClaim, glutenFreeByIngredients;
  final List<String> lactoseSources;
  final bool lactoseFree, lactoseFreeByIngredients, lactoseClaim;
  final List<String> fodmapSources;
  final bool simpleRice;
  final List<String> sugarAdditions, fruitSweeteners, otherSweeteners;
  final String? fodmapCertification;
  final bool sugarClaim;

  /// The user confirmed the ingredient list is complete.
  final bool complete;
  const DietaryFacts({
    this.glutenSources = const [],
    this.glutenClaim = false,
    this.glutenFreeByIngredients = false,
    this.lactoseSources = const [],
    this.lactoseFree = false,
    this.lactoseFreeByIngredients = false,
    this.lactoseClaim = false,
    this.fodmapSources = const [],
    this.simpleRice = false,
    this.sugarAdditions = const [],
    this.fruitSweeteners = const [],
    this.otherSweeteners = const [],
    this.fodmapCertification,
    this.sugarClaim = false,
    this.complete = false,
  });

  factory DietaryFacts.fromAnalysis(DietaryAnalysis a, {bool english = false}) {
    List<String> names(List<DietaryEntry> e) =>
        e.map((x) => x.name(english)).toList();
    return DietaryFacts(
      glutenSources: names(a.gluten),
      glutenClaim: a.glutenClaim,
      glutenFreeByIngredients: a.riceGluten,
      lactoseSources: names(a.lactose),
      lactoseFree: a.lactoseFree,
      lactoseFreeByIngredients:
          a.riceLactose && !a.lactoseClaim && !a.lactoseFreeByEnzyme,
      lactoseClaim: a.lactoseClaim,
      fodmapSources: names(a.fodmap),
      simpleRice: a.simpleRice,
      sugarAdditions: a.sugarAdditions,
      fruitSweeteners: a.fruitSweeteners,
      otherSweeteners: a.otherSweeteners,
      fodmapCertification: a.fodmapCertification,
      sugarClaim: a.sugarClaim,
      complete: a.complete,
    );
  }
}

/// Preference labels as stored in AppSettings.
const preferenceOrder = [
  'Glutensiz',
  'Laktozsuz',
  'Düşük FODMAP',
  'Vegan',
  'Şekersiz',
  'İlave şekersiz',
  'Rafine şekersiz',
  'Ketojenik',
  'Az yağlı',
];

/// Sugar additions treated as refined. Honey, molasses, syrups from fruit
/// and juice concentrates are additions but not refined sugar.
const _refinedSugarAliases = {
  'şeker',
  'seker',
  'sugar',
  'zucker',
  'sakkaroz',
  'sukroz',
  'sucrose',
  'glikoz',
  'glukoz',
  'glucose',
  'dekstroz',
  'dextrose',
  'fruktoz',
  'fructose',
  'invert şeker',
  'invert sugar',
  'glikoz şurubu',
  'glukoz şurubu',
  'glucose syrup',
  'corn syrup',
  'mısır şurubu',
  'misir surubu',
  'fruktoz şurubu',
};

/// A source-reviewed animal-derived ingredient group from assets/vegan.json.
/// Recognises common names only: absence never means vegan.
class VeganEntry {
  final String id, source;
  final Map<String, String> names;
  final List<String> aliases, exclude;
  VeganEntry(Map<String, dynamic> j)
      : id = j['id'] as String,
        source = j['source'] as String,
        names = Map<String, String>.from(j['names'] as Map),
        aliases = List<String>.from(j['aliases'] as List),
        exclude = List<String>.from(j['exclude'] as List? ?? const []);
  String name(bool english) => names[english ? 'en' : 'tr']!;

  /// Plant-based look-alikes (coconut milk, cocoa butter) are removed first.
  bool matches(String text) {
    var value = normalize(text);
    for (final phrase in exclude) {
      value = value.replaceAll(normalize(phrase), ' ');
    }
    return aliases.any((alias) => containsIngredient(value, alias));
  }

  static List<VeganEntry> decodeAll(String json) =>
      ((jsonDecode(json) as Map<String, dynamic>)['entries'] as List)
          .map((e) => VeganEntry(e as Map<String, dynamic>))
          .toList();
}

List<String> listedAnimalIngredients(String text, List<VeganEntry> entries,
        {bool english = false}) =>
    entries.where((e) => e.matches(text)).map((e) => e.name(english)).toList();

/// Reference data needed to check any ingredient text against preferences.
class PreferenceReference {
  final List<DietaryEntry> dietary;
  final List<VeganEntry> vegan;
  const PreferenceReference(this.dietary, this.vegan);
}

/// Checks free text (e.g. a catalogue product) against saved preferences.
List<PreferenceVerdict> checkIngredientText(
    Set<String> preferences, PreferenceReference ref, String text,
    {String evidence = '',
    List<String> labels = const [],
    bool complete = false,
    bool english = false}) {
  if (preferences.isEmpty) return const [];
  final analysis = DietaryAnalysis.of(
      ref.dietary.where((e) => e.matches(text)).toList(),
      text: text,
      evidence: evidence,
      labels: labels,
      complete: complete);
  return evaluatePreferences(
      preferences, DietaryFacts.fromAnalysis(analysis, english: english), text,
      vegan: ref.vegan, english: english);
}

/// Verdicts for the user's saved food preferences, conflicts first.
List<PreferenceVerdict> evaluatePreferences(
    Set<String> preferences, DietaryFacts f, String ingredientText,
    {List<VeganEntry> vegan = const [], bool english = false}) {
  final verdicts = <PreferenceVerdict>[];
  for (final p in preferenceOrder.where(preferences.contains)) {
    final v = _evaluate(p, f, ingredientText, vegan, english);
    if (v != null) verdicts.add(v);
  }
  verdicts.sort((a, b) => a.status.index.compareTo(b.status.index));
  return verdicts;
}

PreferenceVerdict? _evaluate(String p, DietaryFacts f, String text,
    List<VeganEntry> vegan, bool english) {
  const unconfirmedTr =
      'İçerik listesi tam olarak onaylanmadı; eksik metin uyarıyı kaçırabilir.';
  const unconfirmedEn =
      'The ingredient list was not confirmed complete; missing text can hide a conflict.';
  switch (p) {
    case 'Glutensiz':
      if (f.glutenSources.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Gluten kaynağı listelenmiş.', 'A gluten source is listed.',
            f.glutenSources);
      }
      if (f.glutenClaim) {
        return PreferenceVerdict(p, PreferenceStatus.labelClaim,
            'Etikette glutensiz beyanı var; bağımsız doğrulanmadı.',
            'The label claims gluten-free; not independently verified.');
      }
      if (f.glutenFreeByIngredients) {
        return PreferenceVerdict(p, PreferenceStatus.ingredientsFit,
            'İçerikler glutensiz; çapraz bulaşma doğrulanmadı.',
            'Ingredients are gluten-free; cross-contact is not ruled out.');
      }
      return PreferenceVerdict(
          p,
          PreferenceStatus.noneFound,
          f.complete
              ? 'Listelenen gluten kaynağı yok; bu glutensiz olduğunu kanıtlamaz.'
              : unconfirmedTr,
          f.complete
              ? 'No listed gluten source; this does not prove gluten-free.'
              : unconfirmedEn);
    case 'Laktozsuz':
      if (!f.lactoseFree && f.lactoseSources.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Olası laktoz kaynağı listelenmiş.',
            'A possible lactose source is listed.', f.lactoseSources);
      }
      if (f.lactoseFree) {
        return PreferenceVerdict(
            p,
            f.lactoseFreeByIngredients
                ? PreferenceStatus.ingredientsFit
                : PreferenceStatus.labelClaim,
            f.lactoseFreeByIngredients
                ? 'İçeriklere göre laktozsuz.'
                : f.lactoseClaim
                    ? 'Etikette laktozsuz beyanı var; bağımsız doğrulanmadı.'
                    : 'Laktaz enzimi listelenmiş; bağımsız doğrulanmadı.',
            f.lactoseFreeByIngredients
                ? 'Lactose-free based on ingredients.'
                : f.lactoseClaim
                    ? 'The label claims lactose-free; not independently verified.'
                    : 'Lactase enzyme is listed; not independently verified.');
      }
      return PreferenceVerdict(
          p,
          PreferenceStatus.noneFound,
          f.complete ? 'Listelenen laktoz kaynağı yok.' : unconfirmedTr,
          f.complete ? 'No listed lactose source.' : unconfirmedEn);
    case 'Düşük FODMAP':
      if (f.fodmapCertification != null) {
        return PreferenceVerdict(
            p,
            PreferenceStatus.labelClaim,
            'Ambalajda düşük FODMAP sertifika ibaresi var; sertifika ambalajdaki porsiyon için geçerlidir. Bağımsız doğrulanmadı.',
            'The pack shows a low-FODMAP certification mark; it applies to the serving stated on the pack. Not independently verified.',
            [f.fodmapCertification!]);
      }
      if (f.fodmapSources.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.caution,
            'Olası FODMAP kaynağı var; düzeyi porsiyona bağlı.',
            'Possible FODMAP source; the level depends on the serving.',
            f.fodmapSources);
      }
      return PreferenceVerdict(p, PreferenceStatus.caution,
          'FODMAP düzeyi için doğrulanmış porsiyon verisi gerekir.',
          'A validated serving is needed to judge FODMAP level.');
    case 'Vegan':
      final animal = listedAnimalIngredients(text, vegan, english: english);
      if (animal.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Hayvansal kaynaklı içerik listelenmiş.',
            'An animal-derived ingredient is listed.', animal);
      }
      return PreferenceVerdict(
          p,
          PreferenceStatus.notAssessable,
          vegan.isEmpty
              ? 'Vegan kaynak listesi yüklenemedi.'
              : 'Bilinen hayvansal içerik bulunmadı; bu vegan olduğunu kanıtlamaz (ör. aroma ve katkı kaynakları belirtilmeyebilir).',
          vegan.isEmpty
              ? 'Vegan reference list could not load.'
              : 'No known animal-derived ingredient found; this does not prove vegan (flavouring and additive sources may be undisclosed).');
    case 'Şekersiz':
    case 'İlave şekersiz':
      if (f.sugarAdditions.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Şeker veya şeker şurubu listelenmiş.',
            'A sugar or sugar syrup is listed.', f.sugarAdditions);
      }
      final sweeteners = [...f.fruitSweeteners, ...f.otherSweeteners];
      if (p == 'Şekersiz' && f.sugarClaim) {
        return PreferenceVerdict(p, PreferenceStatus.labelClaim,
            'Etikette şekersiz beyanı var; bağımsız doğrulanmadı.',
            'The label claims sugar-free; not independently verified.',
            sweeteners);
      }
      if (p == 'Şekersiz') {
        return PreferenceVerdict(
            p,
            PreferenceStatus.notAssessable,
            f.fruitSweeteners.isNotEmpty
                ? 'Şeker ilavesi yok; meyve kaynaklı tatlandırıcı doğal şeker içerir. Toplam şeker için besin değeri tablosu gerekir.'
                : 'Şeker ilavesi bulunmadı; toplam şeker için besin değeri tablosu gerekir.',
            f.fruitSweeteners.isNotEmpty
                ? 'No added sugar; fruit-based sweeteners contain natural sugars. Total sugars need the nutrition table.'
                : 'No added sugar found; total sugars need the nutrition table.',
            sweeteners);
      }
      if (!f.complete) {
        return PreferenceVerdict(p, PreferenceStatus.noneFound,
            unconfirmedTr, unconfirmedEn, sweeteners);
      }
      return PreferenceVerdict(
          p,
          PreferenceStatus.noneFound,
          sweeteners.isEmpty
              ? 'Listelenen şeker ilavesi yok.'
              : 'Şeker ilavesi yok; tatlandırıcı olarak listelenenler ayrıca gösterildi.',
          sweeteners.isEmpty
              ? 'No listed added sugar.'
              : 'No added sugar; the listed sweeteners are shown separately.',
          sweeteners);
    case 'Rafine şekersiz':
      final refined =
          f.sugarAdditions.where(_refinedSugarAliases.contains).toList();
      if (refined.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Rafine şeker listelenmiş.', 'A refined sugar is listed.',
            refined);
      }
      return PreferenceVerdict(
          p,
          PreferenceStatus.noneFound,
          f.complete
              ? (f.sugarAdditions.isEmpty
                  ? 'Listelenen rafine şeker yok.'
                  : 'Rafine şeker yok; başka şeker kaynakları listelenmiş.')
              : unconfirmedTr,
          f.complete
              ? (f.sugarAdditions.isEmpty
                  ? 'No listed refined sugar.'
                  : 'No refined sugar; other sugar sources are listed.')
              : unconfirmedEn,
          f.sugarAdditions);
    case 'Ketojenik':
      return PreferenceVerdict(p, PreferenceStatus.notAssessable,
          'Karbonhidrat miktarı gerekir; içerik listesinden değerlendirilemez.',
          'Needs carbohydrate amounts; cannot be judged from ingredients.');
    case 'Az yağlı':
      return PreferenceVerdict(p, PreferenceStatus.notAssessable,
          'Yağ miktarı gerekir; içerik listesinden değerlendirilemez.',
          'Needs fat amounts; cannot be judged from ingredients.');
  }
  return null;
}
