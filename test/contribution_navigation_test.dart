import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/main.dart';
import 'package:navilo/data/app_settings.dart';
import 'package:navilo/data/local_product_store.dart';
import 'package:navilo/domain/policy.dart';
import 'widget_test.dart' show waitForWidget;

void main() {
  testWidgets('Centered navigation, nested criteria and editable contribution',
      (tester) async {
    final dir = Directory.systemTemp.createTempSync('navilo_contribution_');
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      dir.deleteSync(recursive: true);
    });
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(IngredientApp(
        storageDirectory: dir,
        persistSettings: false,
        initialSettings: const AppSettings(introSeen: true),
        initialPolicy: Policy('test', const [])));
    await waitForWidget(tester, find.text('Kütüphane'));
    expect(tester.getCenter(find.byIcon(Icons.center_focus_strong_rounded)).dx,
        210);
    await tester.tap(find.text('Profilim'));
    await tester.pumpAndSettle();
    expect(find.text('Profil ve ayarlar'), findsOneWidget);
    await tester.tap(find.text('Kriterler'));
    await tester.pumpAndSettle();
    expect(find.text('Neye bakıyoruz?'), findsOneWidget);
    await tester.tap(find.byTooltip('Profile dön'));
    await tester.pumpAndSettle();
    await waitForWidget(tester, find.text('Uygulama dili'));
    await tester.ensureVisible(find.text('English'));
    expect(tester.getCenter(find.byType(SegmentedButton<bool>)).dx, 210);
    await tester.tap(find.text('Kütüphane'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Katkı'));
    await waitForWidget(tester, find.text('Katkı listesinde ara'));
    await tester.enterText(find.byType(TextField), 'Saf Fit Mix');
    await tester.pumpAndSettle();
    const name = 'Saf Fit Mix strawberry vanilla 360 g';
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(find.text('Barkod okut / düzelt'), findsOneWidget);
    expect(find.textContaining('8682352821258'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    await tester.enterText(
        find.byType(TextField), 'İçindekiler: pirinç, deniz tuzu.');
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-list')), 250,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const ValueKey('confirm-list')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Katkıyı kaydet'), 180,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Katkıyı kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Kaydet'));
    await tester.pump();
    await waitForWidget(tester, find.text('Katkıyı kaydet'));
    await tester.pumpAndSettle();
    final saved = await tester.runAsync(() =>
        LocalProductStore(Directory('${dir.path}/navilo_products'))
            .recent(limit: null));
    expect(saved!.single.name, name);
    expect(saved.single.barcode, isEmpty);
    expect(saved.single.ingredients, contains('pirinç'));
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kütüphane'));
    await tester.pumpAndSettle();
    expect(find.text('Bu cihazda kaydedildi · Düzenle'), findsOneWidget);
    await tester.tap(find.text(name));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        contains('pirinç'));
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-list')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(
        tester
            .widget<CheckboxListTile>(
                find.byKey(const ValueKey('confirm-list')))
            .value,
        isFalse);
    expect(tester.takeException(), isNull);
  });
}
