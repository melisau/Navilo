import 'package:flutter/material.dart';
import '../domain/policy.dart';

/// Concise context next to a detected ingredient; no inferred product risk score.
class IngredientExplanation extends StatelessWidget {
  final IngredientRule rule;
  final bool english;
  final String? ingredientText;
  const IngredientExplanation(
      {super.key,
      required this.rule,
      this.english = false,
      this.ingredientText});

  @override
  Widget build(BuildContext context) {
    final matched = ingredientText == null
        ? const <String>[]
        : rule.aliases
            .where((alias) => containsIngredient(ingredientText!, alias))
            .toList();
    final explanation = english
        ? (rule.summaryEn ?? 'A short explanation is not available yet.')
        : (rule.summaryTr ?? 'Bu madde için kısa açıklama henüz eklenmedi.');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(english ? rule.englishName : rule.name,
              style: Theme.of(context).textTheme.titleSmall),
          if (matched.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${english ? 'Detected on the label' : 'Etikette eşleşen ifade'}: ${matched.join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF53635D),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (rule.sourceUrl?.isNotEmpty ?? false)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(english ? 'Source' : 'Kaynak',
                  style: Theme.of(context).textTheme.bodySmall),
              children: [
                SelectableText(
                  english
                      ? 'Open the reference for the scope and limitations of the evidence.'
                      : 'Kanıtın kapsamını ve sınırlamalarını görmek için kaynağı aç.',
                ),
                SelectableText(rule.sourceUrl!),
              ],
            ),
          const SizedBox(height: 6),
          Text(explanation),
          const SizedBox(height: 6),
          Text(
            english
                ? 'Why this matters: the ingredient name identifies a substance to review; it does not by itself prove that the finished product is unsafe. Concentration, product type, exposure and personal sensitivity can change the assessment.'
                : 'Neden önemli: Bu eşleşme incelenmesi gereken bir maddeyi gösterir; tek başına bitmiş ürünün güvensiz olduğunu kanıtlamaz. Değerlendirme miktara, ürünün kullanım şekline, maruziyete ve kişisel hassasiyete göre değişebilir.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
