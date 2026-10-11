import 'dart:convert';
import 'dart:io';

class AppSettings {
  final bool introSeen, english;
  final String skin;
  final List<String> preferences;
  const AppSettings(
      {this.introSeen = false,
      this.english = false,
      this.skin = 'Henüz seçilmedi',
      this.preferences = const []});
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        introSeen: json['introSeen'] == true,
        english: json['english'] == true,
        skin: ['Henüz seçilmedi', 'Kuru', 'Yağlı', 'Karma', 'Normal']
                .contains(json['skin'])
            ? json['skin'] as String
            : 'Henüz seçilmedi',
        preferences:
            (json['preferences'] as List? ?? []).whereType<String>().toList(),
      );
  Map<String, dynamic> toJson() => {
        'introSeen': introSeen,
        'english': english,
        'skin': skin,
        'preferences': preferences
      };
}

class AppSettingsStore {
  final Directory directory;
  Future<void> _pendingSave = Future.value();
  AppSettingsStore(this.directory);
  File get _file => File('${directory.path}/navilo_settings.json');
  Future<AppSettings> load() async {
    if (!await _file.exists()) return const AppSettings();
    try {
      return AppSettings.fromJson(
          jsonDecode(await _file.readAsString()) as Map<String, dynamic>);
    } on FormatException {
      return const AppSettings();
    } on TypeError {
      return const AppSettings();
    }
  }

  // Serialize rapid preference taps so an older write cannot replace a newer one.
  Future<void> save(AppSettings settings) {
    final next = _pendingSave.then((_) async {
      await directory.create(recursive: true);
      final temporary = File('${_file.path}.tmp');
      await temporary.writeAsString(jsonEncode(settings.toJson()), flush: true);
      await temporary.rename(_file.path);
    });
    _pendingSave = next.catchError((Object _) {});
    return next;
  }
}
