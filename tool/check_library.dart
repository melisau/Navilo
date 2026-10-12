import 'dart:io';
import 'dart:convert';
import 'package:navilo/data/local_product_store.dart';

void check(bool value) {
  if (!value) throw StateError('Library check failed');
}

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('navilo_library_');
  final store = LocalProductStore(dir);
  final id = 'local-1791800000000000';
  try {
    await store.save(LocalProduct(
        id: id,
        barcode: '',
        category: 'cosmetic',
        name: 'Test cream',
        ingredients: 'Aqua, Glycerin',
        reviewedAt: DateTime.now()));
    final reopened = await LocalProductStore(dir).find(id, 'cosmetic');
    check(reopened!.name == 'Test cream' && reopened.barcode.isEmpty);
    check(await store.find(id, 'food') == null);
    await store.save(LocalProduct(
        id: id,
        barcode: '',
        category: 'cosmetic',
        name: 'Updated cream',
        ingredients: 'Aqua',
        reviewedAt: DateTime.now()));
    check((await store.recent(limit: null)).single.name == 'Updated cream');
    final old = {
      'barcode': '8690577001764',
      'category': 'food',
      'name': 'Older record',
      'ingredients': 'Rice flour',
      'reviewedAt': DateTime.now().toIso8601String()
    };
    await File('${dir.path}/food-8690577001764.json')
        .writeAsString(jsonEncode(old));
    check((await store.find('8690577001764', 'food'))!.id == '8690577001764');
    await store.remove(id, 'cosmetic');
    check((await store.recent(limit: null)).single.name == 'Older record');
    stdout.writeln(
        'PASS: 5 library persistence, update, migration and deletion checks');
  } finally {
    await for (final entity in dir.list()) {
      if (entity is File) await entity.delete();
    }
    await dir.delete();
  }
}
