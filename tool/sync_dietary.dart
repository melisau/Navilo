import 'dart:convert';
import 'dart:io';

const dietaryPath = 'assets/dietary.json';
const usdaEndpoint = 'https://api.nal.usda.gov/fdc/v1/foods/search';

Future<void> main() async {
  final apiKey = Platform.environment['USDA_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('USDA_API_KEY ortam değişkeni tanımlı değil.');
    exitCode = 2;
    return;
  }

  final file = File(dietaryPath);
  if (!file.existsSync()) {
    stderr.writeln('$dietaryPath bulunamadı.');
    exitCode = 2;
    return;
  }

  final document = jsonDecode(await file.readAsString());
  if (document is! Map<String, dynamic> ||
      document['entries'] is! List<dynamic>) {
    stderr.writeln('$dietaryPath beklenen JSON yapısında değil.');
    exitCode = 2;
    return;
  }

  final client = HttpClient();
  final updated = <Map<String, dynamic>>[];
  try {
    for (final rawEntry in document['entries'] as List<dynamic>) {
      if (rawEntry is! Map<String, dynamic>) {
        throw const FormatException('Geçersiz dietary entry kaydı.');
      }
      final entry = Map<String, dynamic>.from(rawEntry);
      final aliases = (entry['aliases'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .take(3);
      final fdcIds = <int>{};
      for (final alias in aliases) {
        final foods = await searchFood(client, apiKey, alias);
        fdcIds.addAll(foods);
      }
      entry['usda'] = {
        'source': 'USDA FoodData Central',
        'url': 'https://fdc.nal.usda.gov/',
        'fdc_ids': fdcIds.take(10).toList(),
        'checked_at': DateTime.now().toUtc().toIso8601String(),
      };
      updated.add(entry);
    }
  } finally {
    client.close(force: true);
  }

  final result = Map<String, dynamic>.from(document);
  result['entries'] = updated;
  result['sync'] = {
    'provider': 'USDA FoodData Central',
    'checked_at': DateTime.now().toUtc().toIso8601String(),
    'method':
        'Search results are evidence links, not automatic dietary classifications.',
  };

  final temporary = File('$dietaryPath.tmp');
  await temporary.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(result)}\n',
  );
  await temporary.rename(dietaryPath);
  stdout.writeln('$dietaryPath USDA kaynak kimlikleriyle güncellendi.');
}

Future<List<int>> searchFood(
  HttpClient client,
  String apiKey,
  String query,
) async {
  final uri = Uri.parse(usdaEndpoint).replace(queryParameters: {
    'api_key': apiKey,
    'query': query,
    'pageSize': '5',
    'dataType': 'Foundation,SR Legacy,Branded',
  });
  final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
  final response = await request.close().timeout(const Duration(seconds: 20));
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      'USDA isteği başarısız (${response.statusCode})',
      uri: uri,
    );
  }
  final json = jsonDecode(body);
  if (json is! Map<String, dynamic> || json['foods'] is! List<dynamic>) {
    throw const FormatException('USDA yanıtı beklenen yapıda değil.');
  }
  return (json['foods'] as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map((food) => food['fdcId'])
      .whereType<int>()
      .toList();
}
