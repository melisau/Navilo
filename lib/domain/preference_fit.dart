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
  final List<String> milkIngredients;
  final List<String> fodmapSources;
  final bool simpleRice;
  final List<String> sugarAdditions;
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
    this.milkIngredients = const [],
    this.fodmapSources = const [],
    this.simpleRice = false,
    this.sugarAdditions = const [],
    this.sugarClaim = false,
    this.complete = false,
  });
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

/// Animal-derived names this version can recognise. Not a complete vegan
/// check: absence never means vegan.
const _animalAliases = <String, String>{
  'bal': 'Bal / honey',
  'honey': 'Bal / honey',
  'yumurta': 'Yumurta / egg',
  'egg': 'Yumurta / egg',
  'jelatin': 'Jelatin / gelatin',
  'gelatin': 'Jelatin / gelatin',
  'gelatine': 'Jelatin / gelatin',
  'tereyağı': 'Tereyağı / butter',
  'butter': 'Tereyağı / butter',
  'peynir': 'Peynir / cheese',
  'cheese': 'Peynir / cheese',
  'balık': 'Balık / fish',
  'fish': 'Balık / fish',
  'tavuk': 'Tavuk / chicken',
  'chicken': 'Tavuk / chicken',
  'sığır eti': 'Sığır eti / beef',
  'beef': 'Sığır eti / beef',
  'karmin': 'Karmin / carmine',
  'carmine': 'Karmin / carmine',
  'e120': 'Karmin / carmine',
};

List<String> listedAnimalIngredients(String text) => _animalAliases.entries
    .where((e) => containsIngredient(text, e.key))
    .map((e) => e.value)
    .toSet()
    .toList();

/// Verdicts for the user's saved food preferences, conflicts first.
List<PreferenceVerdict> evaluatePreferences(
    Set<String> preferences, DietaryFacts f, String ingredientText) {
  final verdicts = <PreferenceVerdict>[];
  for (final p in preferenceOrder.where(preferences.contains)) {
    final v = _evaluate(p, f, ingredientText);
    if (v != null) verdicts.add(v);
  }
  verdicts.sort((a, b) => a.status.index.compareTo(b.status.index));
  return verdicts;
}

PreferenceVerdict? _evaluate(String p, DietaryFacts f, String text) {
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
      final animal = {...f.milkIngredients, ...listedAnimalIngredients(text)}
          .toList();
      if (animal.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Hayvansal kaynaklı içerik listelenmiş.',
            'An animal-derived ingredient is listed.', animal);
      }
      return PreferenceVerdict(p, PreferenceStatus.notAssessable,
          'Tam bir vegan içerik listemiz yok; yalnızca süt ürünleri, yumurta, bal, jelatin, et, balık ve karmin aranır.',
          'No complete vegan list yet; only dairy, egg, honey, gelatin, meat, fish and carmine are checked.');
    case 'Şekersiz':
    case 'İlave şekersiz':
      if (f.sugarAdditions.isNotEmpty) {
        return PreferenceVerdict(p, PreferenceStatus.conflict,
            'Şeker ilavesi listelenmiş.', 'An added sugar is listed.',
            f.sugarAdditions);
      }
      if (p == 'Şekersiz' && f.sugarClaim) {
        return PreferenceVerdict(p, PreferenceStatus.labelClaim,
            'Etikette şekersiz beyanı var; bağımsız doğrulanmadı.',
            'The label claims sugar-free; not independently verified.');
      }
      if (p == 'Şekersiz') {
        return PreferenceVerdict(p, PreferenceStatus.notAssessable,
            'Şeker ilavesi bulunmadı; toplam şeker için besin değeri tablosu gerekir.',
            'No added sugar found; total sugars need the nutrition table.');
      }
      return PreferenceVerdict(
          p,
          PreferenceStatus.noneFound,
          f.complete ? 'Listelenen şeker ilavesi yok.' : unconfirmedTr,
          f.complete ? 'No listed added sugar.' : unconfirmedEn);
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
