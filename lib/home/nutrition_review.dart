part of '../main.dart';

// İnceleme ekranında besin değerlerini gösterme, onaylama ve düzeltme.
extension _NutritionReview on _HomePageState {
  String nutrientLabel(String key) => switch (key) {
        'energyKcal' => copy('Enerji (kcal)', 'Energy (kcal)'),
        'fat' => copy('Yağ (g)', 'Fat (g)'),
        'saturatedFat' => copy('Doymuş yağ (g)', 'Saturates (g)'),
        'carbohydrate' => copy('Karbonhidrat (g)', 'Carbohydrate (g)'),
        'sugars' => copy('Şekerler (g)', 'Sugars (g)'),
        'fibre' => copy('Lif (g)', 'Fibre (g)'),
        'protein' => copy('Protein (g)', 'Protein (g)'),
        'salt' => copy('Tuz (g)', 'Salt (g)'),
        _ => key,
      };

  void startNutritionEdit(NutritionFacts? from) => _update(() {
        nutritionDraft = {
          for (final k in NutritionFacts.keys)
            k: NutritionFacts.formText(from?.valueOf(k), english: english),
          'basis': from?.basis == '100ml' ? '100ml' : '100g',
        };
        editingNutrition = true;
      });

  void confirmNutrition(NutritionFacts facts) => _update(() {
        reviewedNutrition = facts;
        reviewedNutritionFor = nutritionKey;
        editingNutrition = false;
      });

  Widget nutritionReview() {
    final key = nutritionKey;
    if (nutritionDraftFor != key) {
      // New label text or product: earlier edits no longer apply.
      nutritionDraftFor = key;
      nutritionDraft = {};
      editingNutrition = false;
    }
    final confirmed = reviewedNutrition != null && reviewedNutritionFor == key;
    final read = parseNutritionTable(rawOcrText) ?? productRecord?.nutrition;
    final shown = confirmed ? reviewedNutrition : read;
    final theme = Theme.of(context);

    Widget values(NutritionFacts n) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(n.lines(english).join(' · '),
            style: theme.textTheme.bodyLarge));

    final List<Widget> body;
    if (editingNutrition) {
      final basis = nutritionDraft['basis'] ?? '100g';
      final preview = NutritionFacts.fromForm(nutritionDraft, basis);
      body = [
        const SizedBox(height: 8),
        SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: '100g', label: Text('100 g')),
              ButtonSegment(value: '100ml', label: Text('100 ml')),
            ],
            selected: {basis},
            onSelectionChanged: (v) =>
                _update(() => nutritionDraft['basis'] = v.first)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final k in NutritionFacts.keys)
            SizedBox(
                width: 150,
                child: TextFormField(
                    key: ValueKey('nutrient-$k-$key'),
                    initialValue: nutritionDraft[k] ?? '',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        labelText: nutrientLabel(k), isDense: true),
                    onChanged: (v) => _update(() => nutritionDraft[k] = v))),
        ]),
        if (preview == null)
          notice(
              copy('Bir değer geçersiz. Sayı gir (ör. 3,1); 100 g için 100’den büyük olamaz.',
                  'A value is invalid. Enter a number (e.g. 3.1); it cannot exceed 100 per 100 g.'),
              warning: true)
        else if (preview.energyInconsistent)
          notice(
              copy('Enerji, yağ, karbonhidrat ve proteinle tutmuyor. Virgülün yerini ve basamakları ambalajla karşılaştır.',
                  'Energy does not match fat, carbohydrate and protein. Check decimal commas and digits against the package.'),
              warning: true),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          FilledButton.icon(
              key: const ValueKey('save-nutrition'),
              onPressed: preview == null ? null : () => confirmNutrition(preview),
              icon: const Icon(Icons.check),
              label: Text(copy('Değerleri kaydet', 'Save values'))),
          TextButton(
              onPressed: () => _update(() => editingNutrition = false),
              child: Text(copy('Vazgeç', 'Cancel'))),
        ]),
      ];
    } else if (shown == null || shown.count == 0) {
      body = [
        const SizedBox(height: 4),
        Text(confirmed
            ? copy('Besin değerleri kullanılmayacak.',
                'Nutrition values will not be used.')
            : copy(
                'Besin tablosu okunmadı. "Devamını çek" ile tablonun fotoğrafını ekleyebilir ya da değerleri elle girebilirsin.',
                'No nutrition table was read. Add a photo of it with "Capture next part" or enter the values yourself.')),
        TextButton.icon(
            onPressed: () => startNutritionEdit(null),
            icon: const Icon(Icons.edit_outlined),
            label: Text(copy('Elle gir', 'Enter manually'))),
      ];
    } else if (confirmed) {
      body = [
        values(shown),
        const SizedBox(height: 4),
        Text(copy('Onayladın.', 'Confirmed by you.'),
            style: theme.textTheme.bodySmall),
        TextButton.icon(
            onPressed: () => startNutritionEdit(shown),
            icon: const Icon(Icons.edit_outlined),
            label: Text(copy('Düzenle', 'Edit'))),
      ];
    } else {
      body = [
        values(shown),
        const SizedBox(height: 4),
        Text(
            shown.source == 'database'
                ? copy('Open Food Facts verisi. Ambalajdaki tabloyla karşılaştır.',
                    'Open Food Facts data. Compare with the table on the package.')
                : copy(
                    'Etiketten okundu. Rakamları ve virgülleri ambalajla karşılaştır; "az yağlı" ve "şekersiz" sonucu ancak onaylanınca kesinleşir.',
                    'Read from the label. Compare digits and decimal commas with the package; "low fat" and "sugar-free" are only decided after you confirm.'),
            style: theme.textTheme.bodySmall),
        if (shown.energyInconsistent)
          notice(
              copy('Enerji, yağ, karbonhidrat ve proteinle tutmuyor; bir rakam yanlış okunmuş olabilir.',
                  'Energy does not match fat, carbohydrate and protein; a digit may be misread.'),
              warning: true),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
              key: const ValueKey('confirm-nutrition'),
              onPressed: () => confirmNutrition(shown.reviewed(
                  basis: shown.basis == '100ml' ? '100ml' : '100g')),
              icon: const Icon(Icons.check),
              label: Text(copy('Değerler doğru', 'Values are correct'))),
          OutlinedButton.icon(
              onPressed: () => startNutritionEdit(shown),
              icon: const Icon(Icons.edit_outlined),
              label: Text(copy('Düzelt', 'Correct'))),
          TextButton(
              onPressed: () => confirmNutrition(
                  const NutritionFacts(basis: '100g', source: 'reviewed')),
              child: Text(copy('Kullanma', 'Do not use'))),
        ]),
      ];
    }

    return Container(
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: shown != null && shown.energyInconsistent && !confirmed
                    ? NaviloColors.warning
                    : const Color(0xFFD8E2DC))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  shown != null && shown.count > 0 && !editingNutrition
                      ? '${copy('Besin değerleri', 'Nutrition')} · ${shown.basisLabel(english)}'
                      : copy('Besin değerleri', 'Nutrition'),
                  style: theme.textTheme.titleMedium),
              ...body,
            ]));
  }
}
