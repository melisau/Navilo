import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/main.dart';
import 'package:navilo/data/app_settings.dart';
import 'package:navilo/data/local_product_store.dart';
import 'package:navilo/domain/policy.dart';

Future<void> waitForWidget(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    final scrollable = find.byType(ListView);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -280));
    }
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump(const Duration(milliseconds: 100));
  }
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for widget: $finder; text: $texts');
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
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(IngredientApp(
        storageDirectory: directory,
        persistSettings: false,
        initialSettings: const AppSettings(introSeen: false),
        initialPolicy: Policy('test', const [])));
    await waitForWidget(tester, find.text('Tanıtımı atla'));
    await tester.scrollUntilVisible(find.text('Tanıtımı atla'), 220);
    expect(find.text('Tanıtımı atla'), findsOneWidget);
    await tester.tap(find.text('Tanıtımı atla'));
    await waitForWidget(tester, find.text('Barkod okut'));
    expect(find.text('Barkod okut'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Kaynaklar ve değerlendirme ayrıntıları'), findsNothing);
    await tester.tap(find.text('Profilim'));
    await waitForWidget(tester, find.text('Uygulama dili'));
    await tester.tap(find.text('English'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.scrollUntilVisible(find.text('Dietary preferences'), -220, scrollable: find.byType(Scrollable).first);
    expect(find.text('Dietary preferences'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Library product details open from saved product',
      (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    await tester.pumpWidget(IngredientApp(
        storageDirectory: directory,
        persistSettings: false,
        initialSettings: const AppSettings(introSeen: true),
        initialPolicy: Policy('test', const []),
        initialProducts: [
          LocalProduct(
              barcode: '8690577001764',
              category: 'food',
              name: 'Test ürünü',
              ingredients: 'Mısır nişastası, pirinç unu, patates nişastası',
              reviewedAt: DateTime.now())
        ]));
    await waitForWidget(tester, find.text('Test ürünü'));
    await tester.tap(find.text('Kütüphane'));
    await tester.pump(const Duration(milliseconds: 300));
    final savedProduct = find.text('Test ürünü');
    await tester.ensureVisible(savedProduct);
    await tester.tap(savedProduct);
    await tester.pumpAndSettle();
    expect(find.text('Test ürünü'), findsNWidgets(2));
    expect(find.text('Test ürünü'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Narrow screen and large system text remain scrollable',
      (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(IngredientApp(
        storageDirectory: directory,
        persistSettings: false,
        initialSettings: const AppSettings(introSeen: true),
        initialPolicy: Policy('test', const [])));
    await waitForWidget(tester, find.text('Ürünün içeriğini keşfet'));
    final scrollable = find.byType(Scrollable).first;
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    await tester.drag(scrollable, const Offset(0, -360));
    await tester.pump(const Duration(milliseconds: 300));
    final after = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(after, greaterThan(before));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Profilim'));
    await waitForWidget(tester, find.text('Beslenme tercihlerin'));
    await tester.scrollUntilVisible(find.text('Beslenme tercihlerin'), 220);
    expect(find.text('Beslenme tercihlerin'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
