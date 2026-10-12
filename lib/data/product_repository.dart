import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;

class ProductRecord {
  final String code, name, ingredients, sourceUrl;
  final String sourceName;
  final String? imageUrl;
  final bool nameMatched;
  final String? nameLookupSource;
  final DateTime? modified;
  final List<String> allergens, traces, labels;
  ProductRecord(this.code, this.name, this.ingredients, this.sourceUrl,
      this.modified, this.allergens, this.traces, this.labels,
      {this.sourceName = 'Open Food Facts',
      this.imageUrl,
      this.nameMatched = false,
      this.nameLookupSource});
  static String? licensedImage(dynamic value) {
    final uri = value is String ? Uri.tryParse(value) : null;
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host == 'images.openfoodfacts.org'
        ? uri.toString()
        : null;
  }

  factory ProductRecord.parse(String code, Map<String, dynamic> json,
      {bool english = false,
      String host = 'world.openfoodfacts.org',
      String sourceName = 'Open Food Facts',
      bool nameMatched = false,
      String? nameLookupSource}) {
    if (json['status'] != 1 || json['product'] is! Map<String, dynamic>) {
      throw const FormatException('Product not found');
    }
    final p = json['product'] as Map<String, dynamic>;
    String first(List<String> fields) => fields
        .map((key) => (p[key] ?? '').toString().trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    final ingredients = first(english
        ? ['ingredients_text_en', 'ingredients_text', 'ingredients_text_tr']
        : ['ingredients_text_tr', 'ingredients_text', 'ingredients_text_en']);
    if (ingredients.isEmpty) {
      throw FormatException('Ingredients unavailable',
          first(['product_name_tr', 'product_name', 'product_name_en']));
    }
    List<String> tags(String key) =>
        (p[key] as List? ?? []).whereType<String>().toList();
    final timestamp = p['last_modified_t'];
    return ProductRecord(
        code,
        first(english
            ? ['product_name_en', 'product_name', 'product_name_tr']
            : ['product_name_tr', 'product_name', 'product_name_en']),
        ingredients,
        'https://$host/product/$code',
        timestamp is num
            ? DateTime.fromMillisecondsSinceEpoch(timestamp.toInt() * 1000,
                isUtc: true)
            : null,
        tags('allergens_tags'),
        tags('traces_tags'),
        tags('labels_tags'),
        sourceName: sourceName,
        nameMatched: nameMatched,
        nameLookupSource: nameLookupSource,
        imageUrl: host == 'world.openfoodfacts.org'
            ? licensedImage(p['image_front_url'])
            : null);
  }
}

typedef ProductJsonLoader = Future<Map<String, dynamic>> Function(Uri uri);

class ProductLookupException implements Exception {
  final List<String> attempts;
  ProductLookupException(this.attempts);
  @override
  String toString() => attempts.join('\n');
}

class ProductServiceException implements Exception {
  final int statusCode;
  ProductServiceException(this.statusCode);
}

class ProductRepository {
  static String failureMessage(Object error, {bool english = false}) {
    if (error is FormatException) {
      if (error.message == 'Ingredients unavailable') {
        final name = error.source?.toString() ?? '';
        return english
            ? 'Product found${name.isEmpty ? "" : ": $name"}; ingredient list missing.'
            : 'Ürün bulundu${name.isEmpty ? "" : ": $name"}; içerik listesi kayıtlı değil.';
      }
      return english
          ? 'No usable product record with ingredients found.'
          : 'İçerik listesi bulunan uygun ürün kaydı bulunamadı.';
    }
    if (error is ProductServiceException) {
      if (error.statusCode == 429) {
        return english
            ? 'Request quota exceeded (HTTP 429).'
            : 'İstek kotası doldu (HTTP 429).';
      }
      return english
          ? 'Service returned HTTP ${error.statusCode}.'
          : 'Servis HTTP ${error.statusCode} hatası döndürdü.';
    }
    if (error is TimeoutException) {
      return english
          ? 'Service timed out.'
          : 'Servis yanıtı zaman aşımına uğradı.';
    }
    if (error is SocketException) {
      return english
          ? 'Network connection failed.'
          : 'Ağ bağlantısı kurulamadı.';
    }
    return english
        ? 'Service response could not be processed.'
        : 'Servis yanıtı işlenemedi.';
  }

  static const catalogUrl = String.fromEnvironment('SUPABASE_URL');
  static const catalogKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get catalogConfigured =>
      catalogUrl.isNotEmpty && catalogKey.isNotEmpty;

  Future<ProductRecord?> findCommunity(String code, String category) async {
    final base = Uri.tryParse(catalogUrl);
    if (base == null ||
        base.scheme != 'https' ||
        !base.host.endsWith('.supabase.co')) {
      throw const FormatException('Invalid catalogue configuration');
    }
    final uri = Uri.https(base.host, '/rest/v1/navilo_catalog', {
      'barcode': 'eq.$code',
      'category': 'eq.$category',
      'select': 'barcode,category,product_name,ingredients,reviewed_at',
      'limit': '1'
    });
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        request.headers.set('apikey', catalogKey);
        final response = await request.close();
        if (response.statusCode != 200) {
          throw ProductServiceException(response.statusCode);
        }
        final rows = jsonDecode(await response.transform(utf8.decoder).join());
        if (rows is! List) {
          throw const FormatException('Invalid catalogue response');
        }
        if (rows.isEmpty) return null;
        final row = rows.single as Map<String, dynamic>;
        if (row['barcode'] != code ||
            row['category'] != category ||
            row['ingredients'] is! String ||
            (row['ingredients'] as String).trim().isEmpty) {
          throw const FormatException('Invalid catalogue record');
        }
        return ProductRecord(
            code,
            row['product_name'] as String,
            row['ingredients'] as String,
            'https://${base.host}/rest/v1/navilo_catalog',
            DateTime.tryParse(row['reviewed_at'] as String? ?? ''),
            [],
            [],
            [],
            sourceName: 'Navilo Community');
      })()
          .timeout(const Duration(seconds: 12));
    } finally {
      client.close(force: true);
    }
  }

  final ProductJsonLoader load;
  ProductRepository({ProductJsonLoader? loader}) : load = loader ?? _load;

  static Future<Map<String, ProductRecord>>? _curatedRecords;
  static final Map<String, String> _upcTitleCache = {};

  /// Resolve a barcode title through UPCitemdb, then offer Open Facts
  /// ingredients as candidates. Callers must ask the user before selection.
  Future<List<ProductRecord>> findNameCandidates({
    String? barcode,
    String? productName,
    bool english = false,
  }) async {
    var query = productName?.trim() ?? '';
    final nameLookupSource =
        productName == null && barcode != null ? 'UPCitemdb' : null;
    if (query.isEmpty && barcode != null) {
      query = _upcTitleCache[barcode] ?? '';
      try {
        if (query.isEmpty) {
          final lookup = await load(Uri.https(
              'api.upcitemdb.com', '/prod/trial/lookup', {'upc': barcode}));
          final items = lookup['items'];
          if (lookup['code'] == 'OK' && items is List && items.isNotEmpty) {
            final item = items.first;
            if (item is Map<String, dynamic>) {
              final title = (item['title'] ?? '').toString().trim();
              final brand = (item['brand'] ?? '').toString().trim();
              query = [brand, title].where((part) => part.isNotEmpty).join(' ');
              if (query.isNotEmpty) _upcTitleCache[barcode] = query;
            }
          }
        }
      } catch (_) {
        // UPCitemdb may have no record or be rate-limited; manual name search
        // remains available in the UI.
      }
    }
    if (query.isEmpty) return const [];

    const sources = [
      ('world.openfoodfacts.org', 'Open Food Facts'),
      ('world.openbeautyfacts.org', 'Open Beauty Facts'),
      ('world.openproductsfacts.org', 'Open Products Facts'),
      ('world.openpetfoodfacts.org', 'Open Pet Food Facts'),
    ];
    final candidates = <ProductRecord>[];
    final seenCodes = <String>{};
    for (final (host, source) in sources) {
      try {
        final response = await load(Uri.https(host, '/cgi/search.pl', {
          'search_terms': query,
          'countries_tags_en': 'turkey',
          'json': '1',
          'page_size': '10',
          'fields':
              'code,product_name,product_name_tr,product_name_en,ingredients_text,ingredients_text_tr,ingredients_text_en,allergens_tags,traces_tags,labels_tags,last_modified_t,image_front_url'
        }));
        final rows = response['products'];
        if (rows is! List) continue;
        for (final row in rows) {
          if (row is! Map<String, dynamic>) continue;
          final code = (row['code'] ?? '').toString();
          if (!RegExp(r'^\d{8,14}$').hasMatch(code) ||
              seenCodes.contains(code)) {
            continue;
          }
          try {
            final record = ProductRecord.parse(
                code, {'status': 1, 'product': row},
                english: english,
                host: host,
                sourceName: source,
                nameMatched: true,
                nameLookupSource: nameLookupSource);
            seenCodes.add(code);
            candidates.add(record);
            if (candidates.length == 8) return candidates;
          } on FormatException {
            // Do not suggest records without ingredient text.
          }
        }
      } catch (_) {
        // Continue to sibling sources if one service is unavailable.
      }
    }
    return candidates;
  }

  Future<ProductRecord?> _findCurated(String code, String category) async {
    if (category != 'food') return null;
    final records = await (_curatedRecords ??= _loadCuratedRecords());
    return records[code];
  }

  static Future<Map<String, ProductRecord>> _loadCuratedRecords() async {
    final raw =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'));
    if (raw is! List) {
      throw const FormatException('Invalid curated product data');
    }
    final records = <String, ProductRecord>{};
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final code = item['code'] as String? ?? '';
      final ingredients = item['ingredients'] as String? ?? '';
      if (!RegExp(r'^\d{8,14}$').hasMatch(code) || ingredients.trim().isEmpty) {
        continue;
      }
      records[code] = ProductRecord(
        code,
        item['name'] as String? ?? '',
        ingredients,
        item['source_url'] as String? ?? '',
        DateTime.tryParse(item['checked_at'] as String? ?? ''),
        (item['allergens'] as List? ?? []).whereType<String>().toList(),
        (item['traces'] as List? ?? []).whereType<String>().toList(),
        (item['labels'] as List? ?? []).whereType<String>().toList(),
        sourceName: item['source_name'] as String? ?? 'Navilo curated label',
      );
    }
    return records;
  }

  Future<ProductRecord> find(String code,
      {bool english = false, String category = 'food'}) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(code)) {
      throw const FormatException('Unsupported barcode');
    }
    final attempts = <String>[];
    if (catalogConfigured) {
      try {
        final product = await findCommunity(code, category);
        if (product != null) return product;
      } catch (error) {
        attempts.add(
            'Navilo Community: ${failureMessage(error, english: english)}');
      }
    }
    try {
      final product = await _findCurated(code, category);
      if (product != null) return product;
    } catch (error) {
      attempts.add(
          'Navilo curated data: ${failureMessage(error, english: english)}');
    }
    // Product type can be misclassified in any community database, so check
    // every sibling dataset. ProductRecord.parse only accepts status == 1 and
    // a non-empty ingredient list. Keep the matched dataset as attribution.
    const sources = [
      ('world.openfoodfacts.org', 'Open Food Facts'),
      ('world.openbeautyfacts.org', 'Open Beauty Facts'),
      ('world.openproductsfacts.org', 'Open Products Facts'),
      ('world.openpetfoodfacts.org', 'Open Pet Food Facts'),
    ];
    for (final (host, source) in sources) {
      try {
        final json = await load(Uri.https(host, '/api/v2/product/$code.json', {
          'fields':
              'code,product_name,product_name_tr,product_name_en,ingredients_text,ingredients_text_tr,ingredients_text_en,allergens_tags,traces_tags,labels_tags,last_modified_t,image_front_url'
        }));
        return ProductRecord.parse(code, json,
            english: english, host: host, sourceName: source);
      } catch (error) {
        attempts.add('$source: ${failureMessage(error, english: english)}');
      }
    }
    throw ProductLookupException(attempts);
  }

  static Future<Map<String, dynamic>> _load(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.headers.set(HttpHeaders.userAgentHeader,
            'Navilo/0.1 (https://github.com/melisau/Navilo)');
        final response = await request.close();
        if (response.statusCode == 404) {
          throw const FormatException('Product not found');
        }
        if (response.statusCode != 200) {
          throw ProductServiceException(response.statusCode);
        }
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body) as Map<String, dynamic>;
      })()
          .timeout(const Duration(seconds: 12));
    } finally {
      client.close(force: true);
    }
  }
}
