part of '../main.dart';

// Kaçınılacak içerik kriterleri listesi.
extension _CriteriaScreen on _HomePageState {
  String criterionGroup(IngredientRule rule) {
    final id = rule.id.toLowerCase();
    if (id.contains('maltitol') || id.contains('sweetener')) {
      return 'sweeteners';
    }
    if (['oil', 'fat', 'palm', 'margarine', 'hydrogenated', 'trans']
        .any(id.contains)) {
      return 'oils';
    }
    return 'additives';
  }

  Widget criteriaScreen(Policy data) {
    final rules = data.rules.where((rule) {
      if (criteriaCategory != 'all' && rule.category != criteriaCategory) {
        return false;
      }
      final query = normalize(criteriaQuery);
      return query.isEmpty ||
          normalize(
                  '${rule.name} ${rule.englishName} ${rule.aliases.join(' ')}')
              .contains(query);
    }).toList();
    final groups = [
      ('sweeteners', copy('Tatlandırıcılar', 'Sweeteners')),
      ('oils', copy('Yağlar', 'Oils and fats')),
      ('additives', copy('Katkılar ve diğerleri', 'Additives and others')),
    ];
    final visibleGroups = groups
        .map((group) => (
              group.$2,
              rules.where((rule) => criterionGroup(rule) == group.$1).toList()
            ))
        .where((group) => group.$2.isNotEmpty)
        .toList();
    return pageList([
      Row(children: [
        const Icon(Icons.info_outline_rounded,
            size: 16, color: NaviloColors.muted),
        const SizedBox(width: 6),
        Expanded(
            child: Text(
                copy('Taslak liste · uzman incelemesi bekliyor',
                    'Draft list · pending expert review'),
                style: Theme.of(context).textTheme.bodySmall)),
      ]),
      const SizedBox(height: 14),
      TextField(
          onChanged: (value) => _update(() => criteriaQuery = value),
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText:
                  copy('Madde veya eş anlam ara', 'Search ingredients'))),
      const SizedBox(height: 12),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final filter in [
              ('all', copy('Tümü', 'All')),
              ('food', copy('Gıda', 'Food')),
              ('cosmetic', copy('Kozmetik', 'Cosmetics')),
            ])
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: Text(filter.$2),
                      selected: criteriaCategory == filter.$1,
                      onSelected: (_) =>
                          _update(() => criteriaCategory = filter.$1))),
          ])),
      const SizedBox(height: 12),
      Text(copy('${rules.length} madde', '${rules.length} ingredients'),
          style: Theme.of(context).textTheme.bodySmall),
      for (final group in visibleGroups) ...[
        const SizedBox(height: 16),
        Text(group.$1.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: NaviloColors.muted,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700)),
        for (final rule in group.$2)
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(english ? rule.englishName : rule.name),
              subtitle: Text(rule.category == 'food'
                  ? copy('Gıda', 'Food')
                  : copy('Bakım ve kozmetik', 'Beauty & care')),
              children: [
                IngredientExplanation(rule: rule, english: english),
                Padding(
                    padding: const EdgeInsets.only(bottom: 16, right: 12),
                    child: SelectableText(rule.aliases.join(', ')))
              ]),
      ],
      ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(copy('Beslenme kaynakları', 'Dietary references')),
          children: [dietaryPanel(reference: true)]),
    ],
        title: copy('Neye bakıyoruz?', 'What do we check?'),
        subtitle: copy('Kaçınılan içerikler ve kullanılan kaynaklar.',
            'Avoided ingredients and reference sources.'));
  }
}
