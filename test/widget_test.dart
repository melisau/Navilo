import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/main.dart';
import 'package:navilo/data/app_settings.dart';
import 'package:navilo/data/local_product_store.dart';

Future<void> settleStorage(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });
  await tester.pumpAndSettle();
}

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('navilo_ui_');
  });
  tearDown(() async {
    // All paths belong to the test-created temporary directory.
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File) await entity.delete();
    }
    final products = Directory('${directory.path}/navilo_products');
    if (await products.exists()) await products.delete();
    await directory.delete();
  });

  testWidgets('First use is skippable; home is free of review forms',
      (tester) async {
    await tester.pumpWidget(IngredientApp(storageDirectory: directory));
    await settleStorage(tester);
    await tester.scrollUntilVisible(find.text('Tanıtımı atla'), 220);
    expect(find.text('Tanıtımı atla'), findsOneWidget);
    await tester.tap(find.text('Tanıtımı atla'));
    await settleStorage(tester);
    expect(find.text('Barkod okut'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Kaynaklar ve değerlendirme ayrıntıları'), findsNothing);
    await tester.runAsync(() async {
      expect((await AppSettingsStore(directory).load()).introSeen, isTrue);
    });
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleStorage(tester);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Saved text needs review; edits remove confirmation',
      (tester) async {
    await tester.runAsync(() async {
      await AppSettingsStore(directory)
          .save(const AppSettings(introSeen: true));
      await LocalProductStore(Directory('${directory.path}/navilo_products'))
          .save(LocalProduct(
              barcode: '8690577001764',
              category: 'food',
              name: 'Test ürünü',
              ingredients: 'Mısır nişastası, pirinç unu, patates nişastası',
              reviewedAt: DateTime.now()));
    });
    await tester.pumpWidget(IngredientApp(storageDirectory: directory));
    await settleStorage(tester);
    await tester.scrollUntilVisible(find.text('Test ürünü'), 220);
    await tester.tap(find.text('Test ürünü'));
    await tester.pumpAndSettle();
    expect(find.text('Okunan içeriği kontrol et'), findsOneWidget);
    final next = find.byKey(const ValueKey('show-results'));
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    await tester.scrollUntilVisible(
        find.byKey(const ValueKey('confirm-list')), 220);
    await tester.tap(find.byKey(const ValueKey('confirm-list')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(find.text('Kaçınılan içerikler'), findsOneWidget);
    expect(find.text('Listemizdeki madde tespit edilmedi'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mısır nişastası, maltitol');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(next).onPressed, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Narrow screen and large system text remain scrollable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.runAsync(() async {
      await AppSettingsStore(directory)
          .save(const AppSettings(introSeen: true));
    });
    await tester.pumpWidget(IngredientApp(storageDirectory: directory));
    await settleStorage(tester);
    await tester.scrollUntilVisible(find.text('Galeriden görsel ekle'), 220);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Tercihlerim'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Beslenme tercihlerin'), 220);
    expect(find.text('Beslenme tercihlerin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
