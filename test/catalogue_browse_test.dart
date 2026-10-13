import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/main.dart';
import 'package:navilo/data/app_settings.dart';
import 'package:navilo/domain/policy.dart';
import 'widget_test.dart' show waitForWidget;

void main() {
  testWidgets(
      'Bundled food and cosmetics can be browsed and reviewed without saving',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('navilo_catalogue_');
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      dir.deleteSync(recursive: true);
    });
    await tester.pumpWidget(IngredientApp(
        storageDirectory: dir,
        persistSettings: false,
        initialSettings: const AppSettings(introSeen: true),
        initialPolicy: Policy('test', const []),
        initialProducts: const []));
    await waitForWidget(tester, find.text('Kütüphane'));
    await tester.tap(find.text('Kütüphane'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Katalog'));
    await waitForWidget(tester, find.text('Ürün kataloğu'));
    await tester.enterText(find.byType(TextField), '8682696010031');
    await waitForWidget(
        tester, find.text('ProteinOcean Whey Protein Çikolata 400 g'));
    await tester.tap(find.text('ProteinOcean Whey Protein Çikolata 400 g'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Whey Proteini Konsantresi'), findsOneWidget);
    expect(find.text('https://proteinocean.com/whey-protein'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('İçeriği kontrol et ve değerlendir'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('İçeriği kontrol et ve değerlendir'));
    await tester.pumpAndSettle();
    expect(find.text('Barkod: 8682696010031'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        contains('Whey Proteini Konsantresi'));
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kütüphane'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '8682536035699');
    await tester.tap(find.text('Kozmetik'));
    await waitForWidget(tester, find.textContaining('TENDER SALMON'));
    expect(find.widgetWithText(ListTile, '8682536035699'), findsOneWidget);
    await tester.tap(find.text('Ürünlerim'));
    await tester.pumpAndSettle();
    expect(find.text('0 ürün'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
