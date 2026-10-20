part of '../main.dart';

// Profil: cilt tipi, tercihler ve dil.
extension _ProfileScreen on _HomePageState {
  Future<void> showSkinTypeQuiz() async {
    final result = await Navigator.push<SkinTestResult>(
        context,
        MaterialPageRoute(
            builder: (_) => SkinTestScreen(
                english: english, persist: widget.persistSettings)));
    if (result == null || !mounted) return;
    _update(() {
      skinResult = result;
      skin = result.type.label;
    });
    await persistSettings();
  }

  Widget skinFitCard(String ingredients, {required bool reviewed}) {
    final profile = skinResult;
    if (profile == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.face_outlined),
        title: Text(copy('Cildine uygun mu?', 'Does it suit your skin?')),
        subtitle: Text(copy('9 soruluk testi tamamlayarak kişiselleştir.',
            'Personalize with the 9-question skin test.')),
        trailing: const Icon(Icons.chevron_right),
        onTap: showSkinTypeQuiz,
      );
    }
    final fit = SkinFitEvaluator.evaluate(
        ingredientsText: ingredients,
        skin: profile,
        complete: reviewed,
        english: english);
    final title = switch (fit.level) {
      FitLevel.good => copy('Uygun görünüyor', 'Looks suitable'),
      FitLevel.caution => copy('Dikkat gerektiriyor', 'Take care'),
      FitLevel.unknown => copy('Uygunluk belirsiz', 'Suitability unknown'),
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
            fit.level == FitLevel.caution
                ? Icons.warning_amber_rounded
                : fit.level == FitLevel.unknown
                    ? Icons.help_outline
                    : Icons.spa_outlined,
            color: fit.level == FitLevel.caution
                ? Colors.orange.shade800
                : NaviloColors.forest),
        title: Text(title),
        subtitle: Text(
            '${copy('Cilt eğilimin', 'Skin tendency')}: ${english ? profile.type.name : profile.type.label}${profile.isSensitive ? copy(' · Hassasiyet', ' · Sensitivity') : ''}'),
      ),
      ...fit.cautions.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 8), child: Text('• $text'))),
      ...fit.positives.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: 8), child: Text('• $text'))),
      if (fit.level == FitLevel.unknown)
        Text(copy(
            'Yeterli içerik eşleşmesi veya kontrol edilmiş tam liste yok.',
            'There are insufficient ingredient matches or no reviewed complete list.')),
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title:
              Text(copy('Bu sonuç ne anlama geliyor?', 'What does this mean?')),
          children: [
            Text(copy(
                'Bu bir içerik eşleştirmesidir; ürünün tamamının güvenli veya etkili olduğunu doğrulamaz. Oranlar, formül, kullanım şekli ve kişisel tepki bilinmiyor. Test teşhis değildir. Kaynak: American Academy of Dermatology; kurallar v1, 12.10.2026.',
                'This is ingredient matching, not proof that the whole product is safe or effective. Concentrations, formulation, use and individual response are unknown. The test is not diagnostic. Source: American Academy of Dermatology; rules v1, 2026-10-12.'))
          ]),
    ]);
  }

  Widget skinTypeCard() {
    const options = [
      ('Kuru', Icons.water_drop_outlined),
      ('Yağlı', Icons.wb_sunny_outlined),
      ('Karma', Icons.blur_on_rounded),
      ('Normal', Icons.spa_outlined),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(copy('Cilt tipin', 'Your skin type'),
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 10),
      InkWell(
          onTap: showSkinTypeQuiz,
          borderRadius: BorderRadius.circular(16),
          child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: NaviloColors.paper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NaviloColors.line)),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.face_retouching_natural_outlined,
                      color: NaviloColors.forest),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          skin == 'Henüz seçilmedi'
                              ? copy('Cilt tipini keşfet',
                                  'Explore your skin type')
                              : '${copy('Cilt eğilimin', 'Skin tendency')}: ${tr(skin)}',
                          style: Theme.of(context).textTheme.titleMedium)),
                  const Icon(Icons.arrow_forward_rounded,
                      color: NaviloColors.muted),
                ]),
                const SizedBox(height: 12),
                Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    children: options.map((option) {
                      final selected = skin == option.$1;
                      return Column(children: [
                        CircleAvatar(
                            radius: 20,
                            backgroundColor: selected
                                ? const Color(0xFFE8D7B5)
                                : const Color(0xFFF0ECE2),
                            child: Icon(option.$2,
                                size: 19, color: NaviloColors.forest)),
                        const SizedBox(height: 4),
                        Text(tr(option.$1),
                            style: Theme.of(context).textTheme.labelSmall),
                      ]);
                    }).toList()),
              ]))),
      if (skinResult != null) ...[
        Text(
            '${copy('Son test', 'Last test')}: ${dateLabel(skinResult!.date)}${skinResult!.isSensitive ? copy(' · Hassasiyet notu var', ' · Sensitivity noted') : ''}'),
        TextButton(
            onPressed: () async {
              try {
                if (widget.persistSettings) await SkinTestStorage.clear();
                if (!mounted) return;
                _update(() {
                  skinResult = null;
                  skin = 'Henüz seçilmedi';
                });
                await persistSettings();
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(copy('Cilt profili silinemedi.',
                          'Could not remove skin profile.'))));
                }
              }
            },
            child: Text(copy('Cilt sonucunu sil', 'Delete skin result'))),
      ],
      const SizedBox(height: 6),
      Text(
          copy('9 soruluk öz değerlendirmedir; tıbbi analiz değildir.',
              'A brief self-assessment, not a medical analysis.'),
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget preferenceChips(String title, List<String> values,
          {bool singleChoice = false}) =>
      Padding(
          padding: const EdgeInsets.only(top: 18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: NaviloColors.muted,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values
                    .map((value) => FilterChip(
                        showCheckmark: false,
                        label: Text(tr(value)),
                        selected: preferences.contains(value),
                        onSelected: (selected) {
                          _update(() {
                            if (singleChoice) preferences.removeAll(values);
                            if (selected) {
                              preferences.add(value);
                            } else {
                              preferences.remove(value);
                            }
                          });
                          persistSettings();
                        }))
                    .toList()),
          ]));

  Widget profileScreen() => pageList([
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.fact_check_outlined),
            title: Text(copy('Kriterler', 'Criteria')),
            subtitle: Text(copy('İncelenen maddeler ve kaynaklar',
                'Ingredients and sources we check')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _update(() => page = 2)),
        const Divider(),
        skinTypeCard(),
        const SizedBox(height: 24),
        Text(copy('Beslenme tercihlerin', 'Dietary preferences'),
            style: Theme.of(context).textTheme.titleLarge),
        preferenceChips(
            copy('Diyet', 'Diet'), ['Vegan', 'Ketojenik', 'Az yağlı']),
        preferenceChips(copy('Hassasiyetler', 'Sensitivities'),
            ['Glutensiz', 'Laktozsuz', 'Düşük FODMAP']),
        preferenceChips(copy('Şeker tercihi', 'Sugar preference'),
            ['Şekersiz', 'İlave şekersiz', 'Rafine şekersiz'],
            singleChoice: true),
        const SizedBox(height: 20),
        Text(
            copy(
                'Gıda sonuçlarında seçtiğin tercihlerle çelişen içerikler ayrıca gösterilir. Ketojenik ve az yağlı için besin değeri gerektiğinden değerlendirme yapılmaz. Sağlık tavsiyesi değildir.',
                'Food results show ingredients that conflict with your preferences. Ketogenic and low-fat need nutrition values, so they are not assessed. This is not medical advice.'),
            style: Theme.of(context).textTheme.bodySmall),
        if (storageError != null) notice(storageError!, warning: true),
        const Divider(height: 32),
        Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(copy('Uygulama dili', 'App language'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          SegmentedButton<bool>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                  textStyle:
                      const TextStyle(fontFamily: 'sans-serif', fontSize: 12),
                  minimumSize: const Size(84, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14)),
              segments: const [
                ButtonSegment(value: false, label: Text('Türkçe')),
                ButtonSegment(value: true, label: Text('English')),
              ],
              selected: {english},
              onSelectionChanged: (value) {
                _update(() => english = value.first);
                persistSettings();
              }),
        ])),
        const SizedBox(height: 20),
      ],
          title: copy('Profil ve ayarlar', 'Profile & settings'),
          subtitle: copy('Ürünleri kendi seçimlerine göre keşfet.',
              'Explore products with your own preferences.'));
}
