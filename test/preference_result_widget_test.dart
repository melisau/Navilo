import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/data/app_settings.dart';
import 'package:navilo/data/local_product_store.dart';
import 'package:navilo/domain/allergens.dart';
import 'package:navilo/domain/nutrition.dart';
import 'package:navilo/domain/policy.dart';
import 'package:navilo/main.dart';

/// Pumps until [finder] appears, scrolling the page and letting asset
/// futures (rootBundle) complete between attempts.
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 40; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable.first, const Offset(0, -300),
          warnIfMissed: false);
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
  fail('Timed out waiting for $finder; text: $texts');
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder.first);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('navilo_pref_ui_');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  testWidgets(
      'Saved product shows preference conflicts, allergens and confirmed nutrition',
      (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(IngredientApp(
        storageDirectory: directory,
        persistSettings: false,
        initialSettings: AppSettings(introSeen: true, preferences: [
          'Vegan',
          'Az yağlı',
          allergenPreference('milk'),
        ]),
        initialPolicy: Policy('test', const []),
        initialProducts: [
          LocalProduct(
              barcode: '8690577001764',
              category: 'food',
              name: 'Test çikolatası',
              ingredients: 'Şeker, kakao yağı, süt tozu, fındık',
              reviewedAt: DateTime.now(),
              nutrition: const NutritionFacts(
                  basis: '100g',
                  source: 'reviewed',
                  energyKcal: 540,
                  fat: 31,
                  carbohydrate: 56,
                  sugars: 52,
                  protein: 6)),
        ]));

    await waitFor(tester, find.text('Test çikolatası'));
    await tester.tap(find.text('Kütüphane'));
    await tester.pump(const Duration(milliseconds: 300));
    await tapVisible(tester, find.text('Test çikolatası'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('İçeriği düzenle / paylaş'));
    await tester.pumpAndSettle();

    // Review screen: the saved values come back as confirmed.
    await waitFor(tester, find.text('Onayladın.'));
    await tapVisible(tester, find.byKey(const ValueKey('confirm-list')));
    await tapVisible(tester, find.byKey(const ValueKey('show-results')));

    // Result screen.
    await waitFor(tester, find.text('Tercihlerine göre'));
    await waitFor(tester, find.text('3 tercihinle çelişen içerik var.'));
    expect(find.text('Hayvansal kaynaklı içerik listelenmiş.'), findsOneWidget);
    expect(find.text('İçeriklerde listelenmiş.'), findsOneWidget);
    expect(find.text('100 g başına 31 g yağ; "az yağlı" eşiği 3 g.'),
        findsOneWidget);
    await waitFor(tester, find.text('Senin onayladığın değerler'));
    await waitFor(tester, find.text('İçeriklerde alerjen listelenmiş'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Without preferences the result invites choosing them',
      (tester) async {
    addTearDown(() async => tester.pumpWidget(const SizedBox()));
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(IngredientApp(
        storageDirectory: directory,
        persistSettings: false,
        initialSettings: const AppSettings(introSeen: true),
        initialPolicy: Policy('test', const []),
        initialProducts: [
          LocalProduct(
              barcode: '8690577001764',
              category: 'food',
              name: 'Pirinç patlağı',
              ingredients: 'Pirinç, tuz',
              reviewedAt: DateTime.now()),
        ]));
    await waitFor(tester, find.text('Pirinç patlağı'));
    await tester.tap(find.text('Kütüphane'));
    await tester.pump(const Duration(milliseconds: 300));
    await tapVisible(tester, find.text('Pirinç patlağı'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('İçeriği düzenle / paylaş'));
    await tester.pumpAndSettle();
    await waitFor(tester, find.text('Elle gir'));
    await tapVisible(tester, find.byKey(const ValueKey('confirm-list')));
    await tapVisible(tester, find.byKey(const ValueKey('show-results')));
    await waitFor(tester, find.text('Tercihlerimi seç'));
    await waitFor(tester, find.text('Listelenen alerjen tespit edilmedi'));
    await waitFor(tester, find.text('Besin değeri tablosu okunamadı'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
