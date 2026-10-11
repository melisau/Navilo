import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ProductRecord {
  final String code, name, ingredients, sourceUrl;
  final String sourceName;
  final DateTime? modified;
  final List<String> allergens, traces, labels;
  ProductRecord(this.code, this.name, this.ingredients, this.sourceUrl,
      this.modified, this.allergens, this.traces, this.labels,
      {this.sourceName = 'Open Food Facts'});
  factory ProductRecord.parse(String code, Map<String, dynamic> json,
      {bool english = false,
      String host = 'world.openfoodfacts.org',
      String sourceName = 'Open Food Facts'}) {
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
        sourceName: sourceName);
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

  final ProductJsonLoader load;
  ProductRepository({ProductJsonLoader? loader}) : load = loader ?? _load;

  Future<ProductRecord> find(String code,
      {bool english = false, String category = 'food'}) async {
    if (!RegExp(r'^\d{8,14}$').hasMatch(code)) {
      throw const FormatException('Unsupported barcode');
    }
    final attempts = <String>[];
    final beauty = category == 'cosmetic';
    final host =
        beauty ? 'world.openbeautyfacts.org' : 'world.openfoodfacts.org';
    final source = beauty ? 'Open Beauty Facts' : 'Open Food Facts';
    try {
      final json = await load(Uri.https(host, '/api/v2/product/$code.json', {
        'fields':
            'code,product_name,product_name_tr,product_name_en,ingredients_text,ingredients_text_tr,ingredients_text_en,allergens_tags,traces_tags,labels_tags,last_modified_t'
      }));
      return ProductRecord.parse(code, json,
          english: english, host: host, sourceName: source);
    } catch (error) {
      attempts.add('$source: ${failureMessage(error, english: english)}');
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
