import 'dart:convert';
import 'dart:io';

class LocalProduct {
  final String barcode, category, name, ingredients;
  final DateTime reviewedAt;
  LocalProduct(
      {required this.barcode,
      required this.category,
      required this.name,
      required this.ingredients,
      required this.reviewedAt});
  Map<String, dynamic> toJson() => {
        'barcode': barcode,
        'category': category,
        'name': name,
        'ingredients': ingredients,
        'reviewedAt': reviewedAt.toUtc().toIso8601String()
      };
  factory LocalProduct.fromJson(Map<String, dynamic> json) => LocalProduct(
      barcode: json['barcode'] as String,
      category: json['category'] as String,
      name: json['name'] as String,
      ingredients: json['ingredients'] as String,
      reviewedAt: DateTime.parse(json['reviewedAt'] as String));
}

// One file per barcode/category avoids rewriting unrelated products.
class LocalProductStore {
  final Directory directory;
  LocalProductStore(this.directory);
  File _file(String barcode, String category) {
    if (!RegExp(r'^\d{8,14}$').hasMatch(barcode) ||
        !['food', 'cosmetic'].contains(category)) {
      throw ArgumentError('Invalid product key');
    }
    return File('${directory.path}/$category-$barcode.json');
  }

  Future<LocalProduct?> find(String barcode, String category) async {
    final file = _file(barcode, category);
    if (!await file.exists()) return null;
    final record = LocalProduct.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    if (record.barcode != barcode ||
        record.category != category ||
        record.ingredients.trim().isEmpty) {
      throw const FormatException('Invalid local record');
    }
    return record;
  }

  Future<List<LocalProduct>> recent({int limit = 5}) async {
    if (!await directory.exists()) return [];
    final records = <LocalProduct>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final key =
          RegExp(r'^(food|cosmetic)-(\d{8,14})\.json$').firstMatch(name);
      if (key == null) continue;
      try {
        final product = await find(key.group(2)!, key.group(1)!);
        if (product != null) records.add(product);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    records.sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
    return records.take(limit).toList();
  }

  Future<void> save(LocalProduct product) async {
    if (product.ingredients.trim().isEmpty) {
      throw ArgumentError('Empty ingredient list');
    }
    final file = _file(product.barcode, product.category);
    await directory.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(product.toJson()), flush: true);
    await temp.rename(file.path);
  }

  Future<void> remove(String barcode, String category) async {
    final file = _file(barcode, category);
    if (await file.exists()) await file.delete();
  }
}
