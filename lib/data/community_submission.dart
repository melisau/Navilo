import 'dart:convert';
import 'dart:io';
import 'local_product_store.dart';
import 'product_repository.dart';
import '../domain/barcode.dart';
import '../domain/catalogue_exclusions.dart';

/// Explicit text-only contributions; never publishes personal photos or profiles.
class CommunitySubmission {
  static String? _token, _userId;
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
          _userId = null;
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
          final userId = session['user']?['id'];
          if (token is! String || userId is! String) {
            throw const FormatException('No session');
          }
          _token = token;
          _userId = userId;
        }
        await post(
            '/rest/v1/navilo_submissions',
            {
              'contributor_id': _userId,
              'barcode': product.barcode,
              'category': product.category,
              'product_name': product.name,
              'ingredients': product.ingredients,
              'language': language,
              'source_note':
                  'User-reviewed package ingredient text. No image submitted.',
              'sharing_consent': true,
            },
            token: _token);
      })()
          .timeout(const Duration(seconds: 20));
    } finally {
      client.close(force: true);
    }
  }
}
