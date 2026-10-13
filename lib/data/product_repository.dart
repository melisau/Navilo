import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/barcode.dart';

class ProductRecord {
  final String code, name, ingredients, sourceUrl;
  final String sourceName;
  final String mayContain;
  final String? imageUrl;
  final String? imageSourceUrl;
  String get imageCredit => imageUrl != null &&
          Uri.tryParse(imageUrl!)?.host == 'images.openfoodfacts.org'
      ? 'Open Food Facts contributors · CC BY-SA 3.0'
      : 'Görsel kaynağı: ${Uri.tryParse(imageSourceUrl ?? '')?.host ?? ''}';
  final bool nameMatched;
  final String? nameLookupSource;
  final DateTime? modified;
  final List<String> allergens, traces, labels;
  ProductRecord(this.code, this.name, this.ingredients, this.sourceUrl,
      this.modified, this.allergens, this.traces, this.labels,
      {this.sourceName = 'Open Food Facts',
      this.mayContain = '',
      this.imageUrl,
      this.imageSourceUrl,
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

  static String? curatedImage(Map<String, dynamic> row) {
    if (row['image_license'] == 'CC-BY-SA-3.0') {
      return licensedImage(row['image_url']);
    }
    final image =
        Uri.tryParse(row['image_url'] is String ? row['image_url'] : '');
    final source = Uri.tryParse(
        row['image_source_url'] is String ? row['image_source_url'] : '');
    return row['image_evidence'] == 'catalogue_product_page' &&
            row['image_matched_code'] == row['code'] &&
            ['barcode', 'name'].contains(row['image_match_method']) &&
            image?.scheme == 'https' &&
            image!.host.isNotEmpty &&
            source?.scheme == 'https' &&
            source!.host.isNotEmpty
        ? image.toString()
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
        imageSourceUrl: host == 'world.openfoodfacts.org'
            ? 'https://world.openfoodfacts.org/product/$code'
            : null,
        imageUrl: host == 'world.openfoodfacts.org'
            ? licensedImage(p['image_front_url'])
            : null);
  }
}

typedef ProductJsonLoader = Future<Map<String, dynamic>> Function(Uri uri);

class ProductLookupException implements Exception {
  final List<String> attempts;
  final String? resolvedName;
  ProductLookupException(this.attempts, {this.resolvedName});
  @override
  String toString() => attempts.join('\n');
}

class ProductServiceException implements Exception {
  final int statusCode;
  ProductServiceException(this.statusCode);
}

class ProductRepository {
  static List<String> _curatedDataIssues = const [];

  /// Rejected bundled rows, retained for diagnosis instead of silently
  /// overwriting another product or dropping a valid shorter GTIN.
  static List<String> get curatedDataIssues => _curatedDataIssues;
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
    // Prefer Turkish catalogue entries first; when sparse, search globally too.
    // Name matches are candidates only and are never selected automatically.
    for (final turkishOnly in [true, false]) {
      for (final (host, source) in sources) {
        try {
          final parameters = <String, String>{
            'search_terms': query,
            'json': '1',
            'page_size': '20',
            'fields':
                'code,product_name,product_name_tr,product_name_en,ingredients_text,ingredients_text_tr,ingredients_text_en,allergens_tags,traces_tags,labels_tags,last_modified_t,image_front_url'
          };
          if (turkishOnly) parameters['countries_tags_en'] = 'turkey';
          final response =
              await load(Uri.https(host, '/cgi/search.pl', parameters));
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
              if (candidates.length == 8) {
                return candidates;
              }
            } on FormatException {
              // Do not suggest records without ingredient text.
            }
          }
        } catch (_) {
          // Continue to sibling sources if one service is unavailable.
        }
      }
    }
    return candidates;
  }

  Future<ProductRecord?> _findCurated(String code, String category) async {
    final records = await (_curatedRecords ??= _loadCuratedRecords());
    return records['$category:$code'];
  }

  static Future<Map<String, ProductRecord>> _loadCuratedRecords() async {
    final food =
        jsonDecode(await rootBundle.loadString('assets/curated_products.json'));
    final cosmetics = jsonDecode(
        await rootBundle.loadString('assets/curated_cosmetics.json'));
    if (food is! List || cosmetics is! List) {
      throw const FormatException('Invalid curated product data');
    }
    return decodeCuratedRecords(food, cosmetics);
  }

  static Map<String, ProductRecord> decodeCuratedRecords(
      List<dynamic> food, List<dynamic> cosmetics) {
    final records = <String, ProductRecord>{};
    final issues = <String>[];
    final blockedKeys = <String>{};
    for (final (category, rows) in [('food', food), ('cosmetic', cosmetics)]) {
      for (var index = 0; index < rows.length; index++) {
        final item = rows[index];
        final location = '$category row ${index + 1}';
        if (item is! Map<String, dynamic>) {
          issues.add('$location: invalid_record');
          continue;
        }
        String field(String key) =>
            item[key] is String ? item[key] as String : '';
        final code = field('code');
        final ingredients = field('ingredients');
        final name = field('name');
        final uri = Uri.tryParse(field('source_url'));
        String? rejection;
        if (!isValidGtin(code)) {
          rejection = 'invalid_gtin';
        } else if ((item['category'] ?? category) != category) {
          rejection = 'category_mismatch';
        } else if (name.trim().isEmpty || ingredients.trim().isEmpty) {
          rejection = 'missing_name_or_ingredients';
        } else if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
          rejection = 'missing_source';
        } else if (DateTime.tryParse(field('checked_at')) == null) {
          rejection = 'missing_check_date';
        } else if (['allergens', 'traces', 'labels']
            .any((key) => item[key] != null && item[key] is! List)) {
          rejection = 'invalid_tag_list';
        }
        if (rejection != null) {
          issues.add('$location ($code): $rejection');
          continue;
        }
        final key = '$category:$code';
        if (records.containsKey(key) || blockedKeys.contains(key)) {
          records.remove(key);
          blockedKeys.add(key);
          issues.add('$location ($code): duplicate_gtin');
          continue;
        }
        records[key] = ProductRecord(
          code,
          name,
          ingredients,
          item['source_url'] as String? ?? '',
          DateTime.tryParse(item['checked_at'] as String? ?? ''),
          (item['allergens'] as List? ?? []).whereType<String>().toList(),
          (item['traces'] as List? ?? []).whereType<String>().toList(),
          (item['labels'] as List? ?? []).whereType<String>().toList(),
          sourceName: item['source_name'] as String? ?? 'Navilo curated label',
          mayContain: item['may_contain'] as String? ?? '',
          imageUrl: ProductRecord.curatedImage(item),
          imageSourceUrl: item['image_license'] == 'CC-BY-SA-3.0'
              ? 'https://world.openfoodfacts.org/product/$code'
              : item['image_source_url'] as String?,
        );
      }
    }
    _curatedDataIssues = List.unmodifiable(issues);
    return records;
  }

  /// The same offline records used by barcode lookup, available for browsing.
  Future<List<ProductRecord>> listCurated({required String category}) async {
    final records = await (_curatedRecords ??= _loadCuratedRecords());
    final products = records.entries
        .where((entry) => entry.key.startsWith('$category:'))
        .map((entry) => entry.value)
        .toList();
    products.sort((a, b) => a.name.compareTo(b.name));
    return products;
  }

  Future<ProductRecord> find(String code,
      {bool english = false,
      String category = 'food',
      void Function(int step)? onProgress}) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(code)) {
      throw const FormatException('Unsupported barcode');
    }
    final attempts = <String>[];
    String? resolvedName;
    if (catalogConfigured) {
      onProgress?.call(1);
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
    onProgress?.call(2);
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
        if (error is FormatException &&
            error.message == 'Ingredients unavailable') {
          final name = error.source?.toString().trim() ?? '';
          if (name.isNotEmpty) resolvedName ??= name;
        }
        attempts.add('$source: ${failureMessage(error, english: english)}');
      }
    }
    throw ProductLookupException(attempts, resolvedName: resolvedName);
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
