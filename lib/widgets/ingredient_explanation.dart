import 'package:flutter/material.dart';
import '../domain/policy.dart';

/// Concise context next to a detected ingredient; no inferred product risk score.
class IngredientExplanation extends StatelessWidget {
  final IngredientRule rule;
  final bool english;
  const IngredientExplanation(
      {super.key, required this.rule, this.english = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(english ? rule.englishName : rule.name,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(english
                ? (rule.summaryEn ??
                    'A short explanation is not available yet.')
                : (rule.summaryTr ??
                    'Bu madde için kısa açıklama henüz eklenmedi.')),
            if (rule.sourceUrl?.isNotEmpty ?? false)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(english ? 'Source' : 'Kaynak',
                    style: Theme.of(context).textTheme.bodySmall),
                children: [SelectableText(rule.sourceUrl!)],
              ),
          ],
        ),
      );
}
