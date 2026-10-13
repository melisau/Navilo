import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/policy.dart';
import 'package:navilo/widgets/ingredient_explanation.dart';

void main() {
  final policy = Policy.decode(File('assets/policy.json').readAsStringSync());

  testWidgets(
      'Legacy and malformed metadata render a fallback without crashing',
      (tester) async {
    for (final value in [null, '', 42, <String>[]]) {
      final rule = IngredientRule({
        'id': 'nitrites',
        'name': 'Nitritler ve nitratlar',
        'category': 'food',
        'aliases': ['sodyum nitrit'],
        'summary_tr': value,
        'summary_en': value,
        'source_url': value,
      });
      for (final english in [false, true]) {
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
          body: IngredientExplanation(rule: rule, english: english),
        )));
        expect(
            find.text(english
                ? 'A short explanation is not available yet.'
                : 'Bu madde için kısa açıklama henüz eklenmedi.'),
            findsOneWidget);
        expect(find.byType(ExpansionTile), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  test('Every ingredient has bilingual context and a source', () {
    for (final rule in policy.rules) {
      expect(rule.summaryTr, isNotEmpty, reason: rule.id);
      expect(rule.summaryEn, isNotEmpty, reason: rule.id);
      expect(Uri.parse(rule.sourceUrl!).scheme, 'https', reason: rule.id);
    }
  });

  for (final category in ['food', 'cosmetic']) {
    testWidgets('$category explanations and sources fit a narrow screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final rule in policy.rules.where((r) => r.category == category)) {
        for (final english in [false, true]) {
          await tester.pumpWidget(MaterialApp(
              home: Scaffold(
                  body: SingleChildScrollView(
            child: IngredientExplanation(
                key: ValueKey('${rule.id}-$english'),
                rule: rule,
                english: english),
          ))));
          expect(find.text((english ? rule.summaryEn : rule.summaryTr)!),
              findsOneWidget);
          await tester.tap(find.text(english ? 'Source' : 'Kaynak'));
          await tester.pumpAndSettle();
          expect(find.text(rule.sourceUrl!), findsOneWidget);
          expect(tester.takeException(), isNull, reason: rule.id);
        }
      }
    });
  }
}
