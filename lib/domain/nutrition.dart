import 'policy.dart';

/// Nutrition values per 100 g (or 100 ml), read from the label or a
/// product database. Values are never estimated: a nutrient that was not
/// read stays null.
class NutritionFacts {
  /// `100g`, `100ml`, or `100g_or_ml` when the source does not say.
  final String basis;

  /// `label` (OCR of the package, not yet confirmed), `reviewed` (checked
  /// or entered by the user) or `database` (e.g. Open Food Facts).
  final String source;
  final double? energyKcal,
      fat,
      saturatedFat,
      carbohydrate,
      sugars,
      fibre,
      protein,
      salt;

  const NutritionFacts({
    required this.basis,
    required this.source,
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.carbohydrate,
    this.sugars,
    this.fibre,
    this.protein,
    this.salt,
  });

  bool get isLiquid => basis == '100ml';

  /// The user confirmed these values against the package.
  bool get confirmed => source == 'reviewed';

  /// Energy does not agree with fat, carbohydrate and protein
  /// (9/4/4 kcal per g, fibre 2 kcal): a typical sign of a misread digit or
  /// decimal comma ("31 g" read as "3,1 g"). Needs all four values.
  bool get energyInconsistent {
    final e = energyKcal, f = fat, c = carbohydrate, p = protein;
    if (e == null || f == null || c == null || p == null || e <= 0) {
      return false;
    }
    final expected = 9 * f + 4 * c + 4 * p + 2 * (fibre ?? 0);
    final diff = (expected - e).abs();
    return diff > 20 && diff / e > 0.2;
  }

  /// The same values marked as confirmed by the user.
  NutritionFacts reviewed({String? basis}) => NutritionFacts(
        basis: basis ?? this.basis,
        source: 'reviewed',
        energyKcal: energyKcal,
        fat: fat,
        saturatedFat: saturatedFat,
        carbohydrate: carbohydrate,
        sugars: sugars,
        fibre: fibre,
        protein: protein,
        salt: salt,
      );

  /// Nutrient keys used by the review form, in label order.
  static const keys = [
    'energyKcal',
    'fat',
    'saturatedFat',
    'carbohydrate',
    'sugars',
    'fibre',
    'protein',
    'salt',
  ];

  double? valueOf(String key) => switch (key) {
        'energyKcal' => energyKcal,
        'fat' => fat,
        'saturatedFat' => saturatedFat,
        'carbohydrate' => carbohydrate,
        'sugars' => sugars,
        'fibre' => fibre,
        'protein' => protein,
        'salt' => salt,
        _ => null,
      };

  /// Builds user-reviewed values from form text ("3,1" or "3.1"; empty
  /// means not given). Returns null if any value is not a valid amount.
  static NutritionFacts? fromForm(Map<String, String> values, String basis) {
    final parsed = <String, double?>{};
    for (final key in keys) {
      final text = (values[key] ?? '').trim();
      if (text.isEmpty) {
        parsed[key] = null;
        continue;
      }
      final v = double.tryParse(text.replaceAll(',', '.'));
      if (v == null || v < 0 || v > (key == 'energyKcal' ? 1000 : 100)) {
        return null;
      }
      parsed[key] = v;
    }
    return NutritionFacts(
      basis: basis,
      source: 'reviewed',
      energyKcal: parsed['energyKcal'],
      fat: parsed['fat'],
      saturatedFat: parsed['saturatedFat'],
      carbohydrate: parsed['carbohydrate'],
      sugars: parsed['sugars'],
      fibre: parsed['fibre'],
      protein: parsed['protein'],
      salt: parsed['salt'],
    );
  }

  /// Form text for a value: "3,1" in Turkish, "3.1" in English.
  static String formText(double? v, {bool english = false}) {
    if (v == null) return '';
    final s = v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(v < 1 ? 2 : 1);
    return english ? s : s.replaceAll('.', ',');
  }
  String basisLabel(bool english) =>
      {'100g': '100 g', '100ml': '100 ml'}[basis] ??
      (english ? '100 g or ml' : '100 g veya ml');

  int get count => [
        energyKcal,
        fat,
        saturatedFat,
        carbohydrate,
        sugars,
        fibre,
        protein,
        salt
      ].whereType<double>().length;

  /// Open Food Facts `nutriments` (`*_100g` keys). Returns null when no
  /// usable value is present.
  static NutritionFacts? fromOpenFoodFacts(Object? nutriments) {
    if (nutriments is! Map) return null;
    double? v(String key) {
      final value = nutriments[key];
      final number =
          value is num ? value.toDouble() : double.tryParse('$value');
      return number == null || number < 0 || number > 1000 ? null : number;
    }

    final facts = NutritionFacts(
      basis: '100g_or_ml',
      source: 'database',
      energyKcal: v('energy-kcal_100g'),
      fat: v('fat_100g'),
      saturatedFat: v('saturated-fat_100g'),
      carbohydrate: v('carbohydrates_100g'),
      sugars: v('sugars_100g'),
      fibre: v('fiber_100g'),
      protein: v('proteins_100g'),
      salt: v('salt_100g'),
    );
    return facts.count == 0 ? null : facts;
  }

  /// Human-readable list such as `Yağ 31 g`.
  List<String> lines(bool english) {
    String n(double x) {
      final s = x == x.roundToDouble()
          ? x.toStringAsFixed(0)
          : x.toStringAsFixed(x < 1 ? 2 : 1);
      return english ? s : s.replaceAll('.', ',');
    }

    return [
      if (energyKcal != null)
        '${english ? 'Energy' : 'Enerji'} ${n(energyKcal!)} kcal',
      if (fat != null) '${english ? 'Fat' : 'Yağ'} ${n(fat!)} g',
      if (saturatedFat != null)
        '${english ? 'Saturates' : 'Doymuş yağ'} ${n(saturatedFat!)} g',
      if (carbohydrate != null)
        '${english ? 'Carbohydrate' : 'Karbonhidrat'} ${n(carbohydrate!)} g',
      if (sugars != null) '${english ? 'Sugars' : 'Şekerler'} ${n(sugars!)} g',
      if (fibre != null) '${english ? 'Fibre' : 'Lif'} ${n(fibre!)} g',
      if (protein != null) 'Protein ${n(protein!)} g',
      if (salt != null) '${english ? 'Salt' : 'Tuz'} ${n(salt!)} g',
    ];
  }
}

final _gram = RegExp(r'(<\s*)?(\d+(?:[.,]\d+)?)\s*g(?![a-z])');
final _kcal = RegExp(r'(\d+(?:[.,]\d+)?)\s*kcal');
final _kj = RegExp(r'(\d+(?:[.,]\d+)?)\s*kj');

double? _num(String s) => double.tryParse(s.replaceAll(',', '.'));

/// Reads a nutrition table written as "name value" on one line, e.g.
/// `Yağ 31 g` or `of which sugars 52 g`. The first value on a line is used
/// (the per-100 g column comes first on EU labels). Tables that OCR has
/// split into separate name and value columns are not reconstructed.
/// Returns null unless at least two nutrients were read.
NutritionFacts? parseNutritionTable(String raw) {
  final text = raw.toLowerCase();
  final basis = RegExp(r'100\s*ml').hasMatch(text) &&
          !RegExp(r'100\s*g(?![a-z])').hasMatch(text)
      ? '100ml'
      : '100g';
  double? energy, fat, sat, carb, sugars, fibre, protein, salt;
  for (final original in raw.split(RegExp(r'\n|;'))) {
    final line = matchForm(original);
    if (line.isEmpty) continue;
    double? grams() {
      final m = _gram.firstMatch(line);
      if (m == null) return null;
      final value = _num(m[2]!);
      return value == null || value > 100 ? null : value;
    }

    bool has(String pattern) => RegExp(pattern).hasMatch(line);
    if (has(r'(?<![a-z])(enerji|energy|energie)(?![a-z])')) {
      final kcal = _kcal.firstMatch(line);
      final kj = _kj.firstMatch(line);
      energy ??= kcal != null
          ? _num(kcal[1]!)
          : kj != null
              ? (_num(kj[1]!) ?? 0) / 4.184
              : null;
    } else if (has(r'doymamis|unsaturate|unges(?:a|ä)ttigt')) {
      continue;
    } else if (has(r'doymus|saturate|ges(?:a|ä)ttigt')) {
      sat ??= grams();
    } else if (has(r'(?<![a-z])trans(?![a-z])')) {
      continue;
    } else if (has(r'(?<![a-z])(yag|yaglar|fat|fett)(?![a-z])')) {
      fat ??= grams();
    } else if (has(r'karbonhidrat|carbohydrate|kohlenhydrat')) {
      carb ??= grams();
    } else if (has(r'poliol|polyol|alkol|alcohol|nisasta|starch')) {
      continue;
    } else if (has(r'(?<![a-z])(seker|sekerler|sugars?|zucker)(?![a-z])')) {
      sugars ??= grams();
    } else if (has(r'(?<![a-z])(lif|posa|fibre|fiber|ballaststoffe)(?![a-z])')) {
      fibre ??= grams();
    } else if (has(r'(?<![a-z])(protein|proteinler|eiwei(?:ss|ß))(?![a-z])')) {
      protein ??= grams();
    } else if (has(r'(?<![a-z])(tuz|salt|salz)(?![a-z])')) {
      salt ??= grams();
    }
  }
  // Physically impossible combinations mean the columns were misread.
  if (sat != null && fat != null && sat > fat) sat = null;
  if (sugars != null && carb != null && sugars > carb) sugars = null;
  final facts = NutritionFacts(
    basis: basis,
    source: 'label',
    energyKcal: energy?.roundToDouble(),
    fat: fat,
    saturatedFat: sat,
    carbohydrate: carb,
    sugars: sugars,
    fibre: fibre,
    protein: protein,
    salt: salt,
  );
  return facts.count >= 2 ? facts : null;
}

/// Regulation (EC) No 1924/2006, Annex: nutrition claim conditions.
class NutritionClaimLimits {
  static double lowFat(NutritionFacts n) => n.isLiquid ? 1.5 : 3;
  static const sugarsFree = 0.5;
  static double lowSugars(NutritionFacts n) => n.isLiquid ? 2.5 : 5;
}
