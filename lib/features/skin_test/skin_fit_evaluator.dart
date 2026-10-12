import 'skin_type.dart';
import 'skin_test_service.dart';

enum FitLevel { good, caution, unknown }

class SkinFitResult {
  final FitLevel level;
  final List<String> positives, cautions;
  SkinFitResult(this.level, this.positives, this.cautions);
}

class SkinFitEvaluator {
  static String normalize(String text) => text
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .toLowerCase()
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
  static SkinFitResult evaluate(
      {required String ingredientsText,
      required SkinTestResult skin,
      bool complete = true,
      bool english = false}) {
    final positives = <String>[], cautions = <String>[];
    if (!complete || ingredientsText.trim().length < 3) {
      return SkinFitResult(FitLevel.unknown, positives, cautions);
    }
    // Full INCI entries, not substrings: coconut derivatives and fatty alcohols
    // must not accidentally match coconut oil or ethanol.
    final entries = ingredientsText
        .split(RegExp(r'[,;\n]'))
        .map((e) => normalize(e
            .replaceFirst(RegExp(r'^.*?:'), '')
            .replaceAll(RegExp(r'\([^)]*\)'), '')))
        .toSet();
    bool has(List<String> aliases) =>
        aliases.any((a) => entries.contains(normalize(a)));
    void positive(List<String> aliases, String tr, String en) {
      if (has(aliases)) positives.add(english ? en : tr);
    }

    void caution(List<String> aliases, String tr, String en) {
      if (has(aliases)) cautions.add(english ? en : tr);
    }

    positive(
        ['glycerin', 'glycerol', 'gliserin'],
        'Gliserin: nem tutmaya yardımcı olabilir.',
        'Glycerin: may help retain moisture.');
    positive(
        ['hyaluronic acid', 'sodium hyaluronate', 'hyaluronik asit'],
        'Hyaluronik asit: nem desteği sağlayabilir.',
        'Hyaluronic acid: may support hydration.');
    if (skin.type == SkinType.dry) {
      positive(
          ['ceramide np', 'ceramide ap', 'ceramide eop', 'ceramide', 'seramid'],
          'Seramidler: cilt bariyerini destekleyebilir.',
          'Ceramides: may support the skin barrier.');
      positive(
          ['butyrospermum parkii butter', 'shea butter'],
          'Shea yağı: kuru cilde nem desteği sağlayabilir.',
          'Shea butter: may support dry skin.');
    }
    if (skin.type == SkinType.dry || skin.isSensitive) {
      caution([
        'alcohol denat',
        'denatured alcohol',
        'sd alcohol 40',
        'sd alcohol 40 b',
        'ethanol',
        'etanol',
        'denature alkol'
      ], 'Denatüre alkol / etanol: kuruluk veya hassasiyet yapabilir.',
          'Denatured alcohol / ethanol: may cause dryness or irritation.');
      caution(
          ['sodium lauryl sulfate', 'sodyum lauril sulfat'],
          'SLS: özellikle kuru veya hassas ciltte tahriş yapabilir.',
          'SLS: may irritate dry or sensitive skin.');
    }
    if (skin.isSensitive) {
      caution(
          ['parfum', 'fragrance', 'perfume', 'parfüm'],
          'Parfüm: hassasiyet açısından dikkat gerektirebilir.',
          'Fragrance: may be a sensitivity concern.');
      caution(
          ['limonene', 'linalool'],
          'Limonene / linalool: hassasiyet açısından dikkat gerektirebilir.',
          'Limonene / linalool: may be a sensitivity concern.');
      caution(['menthol', 'mentol'], 'Mentol: yanma veya batma yapabilir.',
          'Menthol: may cause burning or stinging.');
    }
    return SkinFitResult(
        cautions.isNotEmpty
            ? FitLevel.caution
            : positives.isNotEmpty
                ? FitLevel.good
                : FitLevel.unknown,
        positives,
        cautions);
  }
}
