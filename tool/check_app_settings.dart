import 'dart:io';
import 'package:navilo/data/app_settings.dart';
import 'package:navilo/data/local_product_store.dart';

void check(bool condition, String label) {
  if (!condition) throw StateError(label);
}

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('navilo_preferences_');
  final products = Directory('${dir.path}/navilo_products');
  try {
    final settings = AppSettingsStore(dir);
    check(!(await settings.load()).introSeen, 'New installation');
    await Future.wait([
      settings.save(const AppSettings(introSeen: true, preferences: ['Vegan'])),
      settings.save(const AppSettings(
          introSeen: true,
          english: true,
          skin: 'Kuru',
          preferences: ['Glutensiz'])),
    ]);
    final reopened = await AppSettingsStore(dir).load();
    check(
        reopened.introSeen &&
            reopened.english &&
            reopened.skin == 'Kuru' &&
            reopened.preferences.single == 'Glutensiz',
        'Last write and restart');
    await File('${dir.path}/navilo_settings.json').writeAsString('{broken');
    check(!(await settings.load()).introSeen, 'Corrupt settings fallback');
    final store = LocalProductStore(products);
    check((await store.recent()).isEmpty, 'Empty history');
    for (var i = 0; i < 7; i++) {
      await store.save(LocalProduct(
          barcode: '869057700176$i',
          category: 'food',
          name: 'Product $i',
          ingredients: 'Rice flour',
          reviewedAt: DateTime.utc(2026, 10, i + 1)));
    }
    await File('${products.path}/food-12345678.json').writeAsString('{broken');
    final history = await store.recent();
    check(
        history.length == 5 &&
            history.first.name == 'Product 6' &&
            history.last.name == 'Product 2',
        'Recent order, limit, corrupt record skip');
    await store.remove(history.first.barcode, 'food');
    check((await store.recent()).first.name == 'Product 5', 'Deletion refresh');
    stdout.writeln('PASS: 6 settings and recent-record checks');
  } finally {
    await for (final file in dir.list(recursive: true, followLinks: false)) {
      if (file is File) await file.delete();
    }
    if (await products.exists()) await products.delete();
    await dir.delete();
  }
}
