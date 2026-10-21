part of '../main.dart';

// İçerik vurgulama ve diyet (gluten/laktoz/şeker/FODMAP) paneli.
extension _DietaryPanel on _HomePageState {
  List<TextSpan> highlightedIngredientSpans() {
    final source = label.text;
    final ranges = <(int, int)>[];
    for (final alias in matches!.expand((rule) => rule.aliases).toSet()) {
      if (alias.trim().length < 3) continue;
      final pattern = RegExp(RegExp.escape(alias), caseSensitive: false);
      for (final match in pattern.allMatches(source)) {
        ranges.add((match.start, match.end));
      }
    }
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.$1 < cursor) continue;
      if (range.$1 > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, range.$1)));
      }
      spans.add(TextSpan(
          text: source.substring(range.$1, range.$2),
          style: const TextStyle(
              backgroundColor: Color(0xFFFFD36B),
              color: NaviloColors.ink,
              fontWeight: FontWeight.w700)));
      cursor = range.$2;
    }
    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor)));
    }
    return spans;
  }

  Widget resultRow(String title, String status, List<String> names,
      {bool warning = false, bool unknown = false, Color? accent}) {
    final indicatorColor = warning
        ? NaviloColors.warning
        : unknown
            ? NaviloColors.uncertain
            : accent ?? NaviloColors.muted;
    final indicator = warning
        ? Icons.warning_amber_rounded
        : unknown
            ? Icons.help_outline_rounded
            : Icons.remove_circle_outline_rounded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NaviloColors.line))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(indicator, size: 21, color: indicatorColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: NaviloColors.muted,
                    letterSpacing: 1.05,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(status,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: warning ? NaviloColors.warning : NaviloColors.ink,
                    fontWeight: FontWeight.w600,
                    height: 1.3)),
            if (names.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(names.join(' · '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: NaviloColors.muted)),
            ],
          ]),
        ),
      ]),
    );
  }

  void showFodmapPortionDetails({required bool simpleRice}) {
    showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (ctx) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(
                            copy('FODMAP ve porsiyon',
                                'FODMAP and serving size'),
                            style: Theme.of(ctx).textTheme.titleLarge)),
                    IconButton(
                        tooltip: copy('Kapat', 'Close'),
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 16),
                  Text(
                      copy('Bu ürünün doğrulanmış FODMAP porsiyonu henüz yok.',
                          'A validated FODMAP serving for this product is not available yet.'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                  if (simpleRice) ...[
                    const SizedBox(height: 20),
                    Text(
                        copy('Sade pirinç patlağı için kaynak örneği: 2 adet',
                            'Source example for plain rice cakes: 2 cakes'),
                        style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(copy(
                        'Monash’ın 2022 tarihli açıklamasında 2 adet pirinç patlağı düşük FODMAP örneği olarak veriliyor. Bu, taradığın markanın test edilmiş porsiyonu veya üst tüketim sınırı değildir. Adet büyüklüğü değiştiği için gram karşılığı tahmin edilmez.',
                        'Monash’s 2022 article uses 2 rice cakes as a low-FODMAP example. This is not a tested serving or an upper intake limit for your scanned brand. Cake sizes vary, so no gram conversion is assumed.')),
                  ],
                  const SizedBox(height: 20),
                  Text(
                      copy('Porsiyon büyürse ne olur?',
                          'What happens with a larger serving?'),
                      style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(copy(
                      'Miktar arttıkça alınan FODMAP miktarı da artabilir; bazı gıdalar daha büyük porsiyonda orta veya yüksek FODMAP düzeyine geçebilir. Aynı öğündeki diğer gıdalar da toplamı etkiler. Bu ürünün kaç gramda yüksek düzeye geçtiği bilinmiyor; otomatik bir eşik hesaplamıyoruz.',
                      'Larger servings can increase FODMAP intake; some foods move to moderate or high levels at larger servings. Other foods in the same meal also affect the total. The high-FODMAP threshold in grams for this product is unknown; no threshold is calculated automatically.')),
                  const SizedBox(height: 20),
                  Text(copy('Ambalaj porsiyonu ile FODMAP porsiyonu farklıdır.',
                      'A package serving is different from a validated FODMAP serving.')),
                  const SizedBox(height: 12),
                  const SelectableText(
                      'Monash University · 2022\nhttps://www.monashfodmap.com/blog/fodmap-stacking-explained/\nhttps://monashfodmap.com/blog/serving-size-and-fodmaps-why-it-so-important/'),
                  const SizedBox(height: 20),
                ])));
  }

  Widget dietaryPanel({bool reference = false}) =>
      FutureBuilder<Map<String, dynamic>>(
        future: dietary,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(english
                ? 'Reference data unavailable.'
                : 'Kaynak verisi yüklenemedi.');
          }
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final json = snapshot.requireData;
          final entries = (json['entries'] as List)
              .map((e) => DietaryEntry(e as Map<String, dynamic>))
              .where((e) => reference || e.matches(label.text))
              .toList();
          final sources = json['sources'] as Map<String, dynamic>;
          // In reference mode every entry is listed; the analysis below is
          // only displayed for a real product.
          final a = DietaryAnalysis.of(entries,
              text: label.text,
              evidence:
                  '$rawOcrText ${productName ?? ''} ${productRecord?.name ?? ''}',
              labels: productRecord?.labels ?? const [],
              complete: complete);
          final gluten = a.gluten;
          final lactose = a.lactose;
          final lactoseFreeByEnzyme = a.lactoseFreeByEnzyme;
          final glutenClaim = a.glutenClaim;
          final fodmap = a.fodmap;
          final sugarClaim = a.sugarClaim;
          final sugarAdditions = a.sugarAdditions;
          final natural = glutenFreeIngredients(label.text, english: english);
          final simpleRice = a.simpleRice;
          final riceGluten = a.riceGluten;
          final riceLactose = a.riceLactose;
          final lactoseFree = a.lactoseFree;
          final milkAllergens = a.milkAllergens;
          final facts = DietaryFacts.fromAnalysis(a, english: english);
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!reference) preferenceSummary(facts),
                if (!reference) ...[
                  resultRow(
                      'Gluten',
                      glutenClaim
                          ? (english
                              ? 'Gluten-free · label claim'
                              : 'Glutensiz · etiket beyanı')
                          : riceGluten
                              ? copy('Glutensiz · içeriklere göre',
                                  'Gluten-free · based on ingredients')
                              : gluten.isNotEmpty
                                  ? (english
                                      ? 'Ingredient requires review'
                                      : 'İçerik uyarısı var')
                                  : (english
                                      ? 'No listed gluten source detected'
                                      : 'Listelenen gluten kaynağı tespit edilmedi'),
                      gluten.map((e) => e.name(english)).toList(),
                      warning: gluten.isNotEmpty,
                      accent: glutenClaim || riceGluten
                          ? const Color(0xFF6D4ACB)
                          : null),
                  if (natural.isNotEmpty)
                    resultRow(
                        english
                            ? 'Naturally gluten-free ingredients'
                            : 'Doğal olarak glutensiz içerikler',
                        english ? 'Recognized in the text' : 'Metinde tanındı',
                        natural),
                  resultRow(
                      english ? 'Lactose' : 'Laktoz',
                      lactoseFree
                          ? (english
                              ? (lactoseFreeByEnzyme
                                  ? 'Lactose-free · lactase enzyme listed'
                                  : 'Lactose-free · label claim')
                              : (lactoseFreeByEnzyme
                                  ? 'Laktozsuz · laktaz enzimi listelenmiş'
                                  : 'Laktozsuz · etiket beyanı'))
                          : riceLactose
                              ? copy('Laktozsuz · içeriklere göre',
                                  'Lactose-free · based on ingredients')
                              : lactose.isNotEmpty
                                  ? (english
                                      ? 'Possible lactose source'
                                      : 'Olası laktoz kaynağı var')
                                  : (english
                                      ? 'No listed lactose source detected'
                                      : 'Listelenen laktoz kaynağı tespit edilmedi'),
                      lactoseFreeByEnzyme && lactoseFree
                          ? [copy('Laktaz enzimi', 'Lactase enzyme')]
                          : lactoseFree
                              ? const <String>[]
                              : lactose.map((e) => e.name(english)).toList(),
                      warning: !lactoseFree && lactose.isNotEmpty,
                      accent: lactoseFree ? const Color(0xFF1672B8) : null),
                  if (lactoseFree && milkAllergens.isNotEmpty)
                    resultRow(
                        english ? 'Milk allergen' : 'Süt alerjeni',
                        english
                            ? 'Milk is still listed; lactose-free does not mean milk-protein-free.'
                            : 'Süt içerir; laktozsuz olması süt proteini içermediği anlamına gelmez.',
                        milkAllergens.map((e) => e.name(english)).toList(),
                        warning: true),
                  resultRow(
                      english ? 'Sugar' : 'Şeker',
                      sugarAdditions.isNotEmpty
                          ? copy('Şeker veya şeker şurubu listelenmiş',
                              'Sugar or sugar syrup listed')
                          : sugarClaim
                              ? copy('Şekersiz · etiket beyanı',
                                  'Sugar-free · label claim')
                              : complete
                                  ? copy(
                                      'Listelenen şeker ilavesi tespit edilmedi',
                                      'No listed sugar addition detected')
                                  : copy('İçerik listesini kontrol et',
                                      'Review the ingredient list'),
                      sugarAdditions,
                      warning: sugarAdditions.isNotEmpty,
                      unknown:
                          sugarAdditions.isEmpty && !sugarClaim && !complete,
                      accent: sugarAdditions.isEmpty && (sugarClaim || complete)
                          ? const Color(0xFFB34572)
                          : null),
                  if (a.fruitSweeteners.isNotEmpty ||
                      a.otherSweeteners.isNotEmpty)
                    resultRow(
                        copy('Tatlandırıcı', 'Sweeteners'),
                        a.fruitSweeteners.isNotEmpty
                            ? copy(
                                'Meyve kaynaklı tatlandırıcı listelenmiş · şeker ilavesi sayılmaz, doğal şeker içerir',
                                'Fruit-based sweetener listed · not counted as added sugar; contains natural sugars')
                            : copy(
                                'Şeker dışı tatlandırıcı listelenmiş · şeker ilavesi sayılmaz',
                                'Non-sugar sweetener listed · not counted as added sugar'),
                        [...a.fruitSweeteners, ...a.otherSweeteners]),
                  InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          showFodmapPortionDetails(simpleRice: simpleRice),
                      child: resultRow(
                          'FODMAP ⓘ',
                          a.fodmapCertification != null
                              ? copy(
                                  'Düşük FODMAP sertifika ibaresi · ambalajdaki porsiyon için geçerli',
                                  'Low-FODMAP certification mark · applies to the serving on the pack')
                              : simpleRice && fodmap.isEmpty
                              ? copy(
                                  'Düşük FODMAP içerikler · porsiyon gerekli',
                                  'Low-FODMAP ingredients · serving needed')
                              : fodmap.isNotEmpty
                                  ? (english
                                      ? 'FODMAP level undetermined'
                                      : 'FODMAP düzeyi belirlenemedi')
                                  : (english
                                      ? 'Product level unknown'
                                      : 'Ürün düzeyi belirlenemedi'),
                          [
                            if (a.fodmapCertification != null)
                              a.fodmapCertification!,
                            ...fodmap.map((e) => e.name(english)),
                          ],
                          unknown: a.fodmapCertification == null,
                          accent: a.fodmapCertification != null ||
                                  (simpleRice && fodmap.isEmpty)
                              ? const Color(0xFF297A54)
                              : null)),
                  TextButton.icon(
                      onPressed: () =>
                          showFodmapPortionDetails(simpleRice: simpleRice),
                      icon: const Icon(Icons.info_outline),
                      label: Text(copy('Porsiyon miktarı ve ayrıntılar',
                          'Serving size and details'))),
                  if (simpleRice)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(copy(
                            'Pirinç ve tuz tanındı. Gluten/laktoz değerlendirmesi içeriklere dayanır; çapraz bulaşmayı doğrulamaz. Pirinç patlağında FODMAP sonucu tüketilen porsiyona bağlıdır.',
                            'Rice and salt recognized. Gluten/lactose assessment is ingredient-based and does not rule out cross-contact. Rice-cake FODMAP levels depend on the serving eaten.'))),
                ],
                ExpansionTile(
                    title: Text(english
                        ? 'Sources and assessment details'
                        : 'Kaynaklar ve değerlendirme ayrıntıları'),
                    initiallyExpanded: reference,
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(english
                              ? 'Results apply to the text read. No match does not establish gluten-free or lactose-free status. Label claims are not independently verified. FODMAP classification requires serving sizes, amounts and validated data; no licensed FODMAP database is connected.'
                              : 'Sonuçlar okunan metne aittir. Eşleşme olmaması ürünün glutensiz veya laktozsuz olduğunu doğrulamaz. Etiket beyanı bağımsız olarak doğrulanmamıştır. FODMAP sınıflandırması için porsiyon, miktar ve doğrulanmış veri gerekir; lisanslı FODMAP veritabanı bağlı değildir.')),
                      const Padding(
                          padding: EdgeInsets.all(16),
                          child: SelectableText(
                              'Rice / plain rice cakes: Monash University\nhttps://monashfodmap.com/documents/192/3-step_FODMAP_Diet_2025_A4_info_sheet.pdf\nServing sizes: https://monashfodmap.com/blog/serving-size-and-fodmaps-why-it-so-important/\nNaturally gluten-free rice: https://www.coeliac.org.uk/grains/')),
                      ...entries.map((e) => ExpansionTile(
                              title: Text(e.name(english)),
                              subtitle: Text(_dietarySubtitle(e.kind)),
                              children: [
                                SelectableText(e.aliases.join(', ')),
                                Text(sources[e.source]['title'] as String),
                                SelectableText(
                                    sources[e.source]['url'] as String),
                                Text(
                                    '${english ? "Reviewed" : "Kontrol tarihi"}: ${sources[e.source]['reviewed']}')
                              ])),
                      if (natural.isNotEmpty)
                        const ListTile(
                            title: Text('Coeliac UK · Gluten-free grains'),
                            subtitle: SelectableText(
                                'https://www.coeliac.org.uk/grains/')),
                    ]),
              ]);
        },
      );

  /// Saved food preferences checked against the reviewed text, conflicts
  /// first. Never says "suitable": only conflicts, cautions or no findings.
  Widget preferenceSummary(DietaryFacts facts) =>
      FutureBuilder<List<VeganEntry>>(
          future: veganEntries,
          builder: (context, snapshot) => preferenceVerdicts(evaluatePreferences(
              preferences, facts, label.text,
              vegan: snapshot.data ?? const [], english: english)));

  Widget preferenceVerdicts(List<PreferenceVerdict> verdicts) {
    final title = Text(copy('Tercihlerine göre', 'For your preferences'),
        style: Theme.of(context).textTheme.titleMedium);
    if (verdicts.isEmpty) {
      return Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 4),
                Text(copy(
                    'Gluten, laktoz, şeker veya vegan gibi tercihlerini seçersen bu ürün onlara göre de kontrol edilir.',
                    'Choose preferences such as gluten, lactose, sugar or vegan to check this product against them.')),
                TextButton.icon(
                    onPressed: () => _update(() => page = 1),
                    icon: const Icon(Icons.tune),
                    label: Text(copy('Tercihlerimi seç', 'Choose preferences'))),
              ]));
    }
    final conflicts =
        verdicts.where((v) => v.status == PreferenceStatus.conflict).length;
    return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 4),
              Text(
                  conflicts > 0
                      ? copy('$conflicts tercihinle çelişen içerik var.',
                          'Conflicts with $conflicts of your preferences.')
                      : copy('Tercihlerinle çelişen içerik bulunmadı.',
                          'No conflict found with your preferences.'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: conflicts > 0
                          ? NaviloColors.warning
                          : NaviloColors.ink)),
              for (final v in verdicts)
                resultRow(tr(v.preference), v.message(english), v.evidence,
                    warning: v.status == PreferenceStatus.conflict,
                    unknown: v.status == PreferenceStatus.caution ||
                        v.status == PreferenceStatus.notAssessable,
                    accent: v.status == PreferenceStatus.ingredientsFit ||
                            v.status == PreferenceStatus.labelClaim
                        ? const Color(0xFF297A54)
                        : null),
              const SizedBox(height: 4),
              Text(
                  copy(
                      'Okunan metne dayanır; uygunluk garantisi veya sağlık tavsiyesi değildir.',
                      'Based on the text read; not a suitability guarantee or medical advice.'),
                  style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 28),
            ]));
  }
}
