import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:navilo/features/skin_test/skin_type.dart';
import 'package:navilo/features/skin_test/skin_test_service.dart';
import 'package:navilo/features/skin_test/skin_fit_evaluator.dart';
import 'package:navilo/features/skin_test/skin_test_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const profiles = {
    SkinType.dry: [0, 0, 3, 0, 3, 0, 0, 0, 2],
    SkinType.normal: [1, 1, 2, 2, 2, 1, 1, 1, 2],
    SkinType.combination: [2, 2, 1, 1, 1, 2, 2, 2, 2],
    SkinType.oily: [3, 3, 0, 3, 0, 3, 3, 3, 2],
  };
  for (final p in profiles.entries) {
    test('Typical ${p.key.name} profile and independent sensitivity', () {
      final result = SkinTestEngine.evaluate(p.value);
      expect(result.type, p.key);
      expect(result.isSensitive, false);
      final sensitive = SkinTestEngine.evaluate([...p.value.take(8), 0]);
      expect(sensitive.type, p.key);
      expect(sensitive.scores, result.scores);
      expect(sensitive.isSensitive, true);
      expect(
          SkinTestEngine.evaluate([...p.value.take(8), 1]).isSensitive, false);
    });
  }
  test('Reject missing, null and invalid answers', () {
    expect(() => SkinTestEngine.evaluate([]), throwsArgumentError);
    expect(() => SkinTestEngine.evaluate(List.filled(9, null)),
        throwsArgumentError);
    expect(
        () => SkinTestEngine.evaluate([...profiles[SkinType.dry]!.take(8), 3]),
        throwsArgumentError);
  });
  test('Combination thresholds and normal tie priority', () {
    Map<SkinType, int> scores(int oily, int dry, int combination, int normal) =>
        {
          SkinType.oily: oily,
          SkinType.dry: dry,
          SkinType.combination: combination,
          SkinType.normal: normal
        };
    expect(SkinTestEngine.resolve(scores(10, 8, 1, 0)), SkinType.combination);
    expect(SkinTestEngine.resolve(scores(10, 7, 1, 0)), SkinType.oily);
    expect(SkinTestEngine.resolve(scores(10, 1, 9, 0)), SkinType.combination);
    expect(SkinTestEngine.resolve(scores(1, 1, 1, 20)), SkinType.normal);
    expect(SkinTestEngine.resolve(scores(5, 1, 0, 5)), SkinType.oily);
  });
  test('Local storage roundtrip, clear and malformed data', () async {
    SharedPreferences.setMockInitialValues({});
    final result = SkinTestEngine.evaluate(profiles[SkinType.dry]!,
        now: DateTime.utc(2026, 10, 12));
    await SkinTestStorage.save(result);
    expect((await SkinTestStorage.load())!.toJson(), result.toJson());
    await SkinTestStorage.clear();
    expect(await SkinTestStorage.load(), null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SkinTestStorage.key, '{"version":1}');
    expect(await SkinTestStorage.load(), null);
    await prefs.setString(SkinTestStorage.key, 'not json');
    expect(await SkinTestStorage.load(), null);
  });
  test('Ingredient rules: fatty alcohol, boundaries, caution precedence', () {
    final skin =
        SkinTestEngine.evaluate([...profiles[SkinType.dry]!.take(8), 0]);
    SkinFitResult fit(String text, {bool complete = true}) =>
        SkinFitEvaluator.evaluate(
            ingredientsText: text, skin: skin, complete: complete);
    expect(
        fit('Aqua, Cetyl Alcohol, Cetearyl Alcohol').level, FitLevel.unknown);
    expect(fit('Aqua, Glycerin').level, FitLevel.good);
    expect(fit('Aqua, Glycerin, Alcohol Denat.').level, FitLevel.caution);
    expect(fit('Aqua, Glycerin, PARFÜM').level, FitLevel.caution);
    expect(fit('Aqua, Ethanolamine').cautions, isEmpty);
    expect(fit('').level, FitLevel.unknown);
    expect(fit('Aqua, Glycerin', complete: false).level, FitLevel.unknown);
  });
  testWidgets(
      'Nine questions retain answers when going back; completed result returns',
      (tester) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SkinTestResult? returned;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      returned = await Navigator.push<SkinTestResult>(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SkinTestScreen(persist: false)));
                    },
                    child: const Text('start'))))));
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rahat; ne gergin ne yağlı'));
    await tester.pump();
    await tester.tap(find.text('Devam'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Devam'))
            .onPressed,
        isNotNull);
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pump();
      await tester.ensureVisible(find.byType(FilledButton).first);
      await tester.tap(find.byType(FilledButton).first);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Cilt eğilimin:'), findsOneWidget);
    await tester.ensureVisible(find.text('Kaydet ve tamamla'));
    await tester.tap(find.text('Kaydet ve tamamla'));
    await tester.pumpAndSettle();
    expect(returned, isNotNull);
  });
}
