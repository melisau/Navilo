import 'dart:convert';
import 'dart:io';

class LocalProduct {
  final String id, barcode, category, name, ingredients;
  final DateTime reviewedAt;
  final String? imageFile;
  final String? remoteImageUrl, imageSourceUrl;
  LocalProduct(
      {String? id,
      this.imageFile,
      this.remoteImageUrl,
      this.imageSourceUrl,
      required this.barcode,
      required this.category,
      required this.name,
      required this.ingredients,
      required this.reviewedAt})
      : id = id ?? barcode;
  Map<String, dynamic> toJson() => {
        'id': id,
        'imageFile': imageFile,
        'remoteImageUrl': remoteImageUrl,
        'imageSourceUrl': imageSourceUrl,
        'barcode': barcode,
        'category': category,
        'name': name,
        'ingredients': ingredients,
        'reviewedAt': reviewedAt.toUtc().toIso8601String()
      };
  factory LocalProduct.fromJson(Map<String, dynamic> json) => LocalProduct(
      id: json['id'] as String?,
      imageFile: json['imageFile'] as String?,
      remoteImageUrl: json['remoteImageUrl'] as String?,
      imageSourceUrl: json['imageSourceUrl'] as String?,
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
    if (!RegExp(r'^(?:\d{8,14}|local-\d{10,20})$').hasMatch(barcode) ||
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
    if (record.id != barcode ||
        record.category != category ||
        record.ingredients.trim().isEmpty) {
      throw const FormatException('Invalid local record');
    }
    return record;
  }

  /// Barcode is independent of the file ID for photo-first library records.
  Future<LocalProduct?> findByBarcode(String barcode, String category) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(barcode)) {
      throw ArgumentError('Invalid barcode');
    }
    try {
      final direct = await find(barcode, category);
      if (direct != null && direct.barcode == barcode) return direct;
    } on FormatException {
      // Try other valid library records after a damaged direct record.
    } on TypeError {
      // Malformed records must not hide a valid linked record.
    }
    for (final record in await recent(limit: null)) {
      if (record.category == category && record.barcode == barcode) {
        return record;
      }
    }
    return null;
  }

  Future<List<LocalProduct>> recent({int? limit = 5}) async {
    if (!await directory.exists()) return [];
    final records = <LocalProduct>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final key = RegExp(r'^(food|cosmetic)-(\d{8,14}|local-\d{10,20})\.json$')
          .firstMatch(name);
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
    return limit == null ? records : records.take(limit).toList();
  }

  Future<void> save(LocalProduct product) async {
    if (product.barcode.isNotEmpty &&
        !RegExp(r'^\d{8,14}$').hasMatch(product.barcode)) {
      throw ArgumentError('Invalid barcode');
    }
    if (product.ingredients.trim().isEmpty) {
      throw ArgumentError('Empty ingredient list');
    }
    final file = _file(product.id, product.category);
    await directory.create(recursive: true);
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(product.toJson()), flush: true);
    await temp.rename(file.path);
  }

  File? imageFor(LocalProduct product) {
    final name = product.imageFile;
    if (name == null || !RegExp(r'^photo-[0-9]+\.jpg$').hasMatch(name)) {
      return null;
    }
    return File('${directory.path}/$name');
  }

  Future<LocalProduct> attachImage(LocalProduct product, File source) async {
    await directory.create(recursive: true);
    final name = 'photo-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final target = File('${directory.path}/$name');
    await source.copy(target.path);
    final updated = LocalProduct(
        id: product.id,
        barcode: product.barcode,
        category: product.category,
        name: product.name,
        ingredients: product.ingredients,
        reviewedAt: product.reviewedAt,
        imageFile: name);
    try {
      await save(updated);
    } catch (_) {
      await target.delete();
      rethrow;
    }
    final old = imageFor(product);
    if (old != null && await old.exists()) await old.delete();
    return updated;
  }

  Future<void> remove(String barcode, String category) async {
    final file = _file(barcode, category);
    if (await file.exists()) {
      final product = await find(barcode, category);
      await file.delete();
      final image = product == null ? null : imageFor(product);
      if (image != null && await image.exists()) await image.delete();
    }
  }
}
