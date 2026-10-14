import 'dart:convert';
import 'dart:io';
import 'local_product_store.dart';
import 'product_repository.dart';
import '../domain/barcode.dart';
import '../domain/catalogue_exclusions.dart';

/// Explicit text-only contributions; never publishes personal photos or profiles.
class CommunitySubmission {
  static String? _token;
  static Future<void> submit(LocalProduct product,
      {required String language}) async {
    final base = Uri.parse(ProductRepository.catalogUrl);
    if (base.scheme != 'https' ||
        !base.host.endsWith('.supabase.co') ||
        !isValidGtin(product.barcode) ||
        excludedCatalogueCodes.contains(product.barcode)) {
      throw const FormatException('Invalid catalogue or barcode');
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    Future<dynamic> post(String path, Map<String, dynamic> body,
        {String? token}) async {
      final request = await client.postUrl(Uri.https(base.host, path));
      request.followRedirects = false;
      request.headers.set('apikey', ProductRepository.catalogKey);
      request.headers.contentType = ContentType.json;
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) {
          _token = null;
        }
        throw HttpException('Catalogue submission HTTP ${response.statusCode}');
      }
      return text.isEmpty ? null : jsonDecode(text);
    }

    try {
      await (() async {
        if (_token == null) {
          // Enable Anonymous Sign-ins in the Supabase Auth dashboard.
          final session = await post('/auth/v1/signup', <String, dynamic>{});
          final token = session['access_token'];
          if (token is! String) {
            throw const FormatException('No session');
          }
          _token = token;
        }
        await post(
            '/rest/v1/rpc/navilo_submit_submission',
            {
              'p_barcode': product.barcode,
              'p_category': product.category,
              'p_product_name': product.name,
              'p_ingredients': product.ingredients,
              'p_language': language,
              'p_source_note':
                  'User-reviewed package ingredient text. No image submitted.',
            },
            token: _token);
      })()
          .timeout(const Duration(seconds: 20));
    } finally {
      client.close(force: true);
    }
  }
}
