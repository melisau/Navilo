import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'skin_type.dart';
import 'skin_test_questions.dart';

class SkinTestResult {
  final SkinType type;
  final Map<SkinType, int> scores;
  final bool isSensitive;
  final DateTime date;
  SkinTestResult(
      {required this.type,
      required Map<SkinType, int> scores,
      required this.isSensitive,
      required this.date})
      : scores = Map.unmodifiable(scores);
  Map<String, dynamic> toJson() => {
        'version': 1,
        'type': type.name,
        'scores': {for (final t in SkinType.values) t.name: scores[t]},
        'sensitive': isSensitive,
        'date': date.toUtc().toIso8601String()
      };
  factory SkinTestResult.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['sensitive'] is! bool) {
      throw const FormatException('Invalid skin profile');
    }
    final scores = {
      for (final t in SkinType.values) t: (json['scores'] as Map)[t.name] as int
    };
    if (scores.values.any((s) => s < 0 || s > 24) ||
        scores.values.every((s) => s == 0)) {
      throw const FormatException('Invalid scores');
    }
    return SkinTestResult(
        type: SkinType.values.byName(json['type'] as String),
        scores: scores,
        isSensitive: json['sensitive'] as bool,
        date: DateTime.parse(json['date'] as String));
  }
}

class SkinTestEngine {
  static SkinTestResult evaluate(List<int?> answers, {DateTime? now}) {
    if (answers.length != skinQuestions.length) {
      throw ArgumentError('All nine answers are required');
    }
    final scores = {for (final t in SkinType.values) t: 0};
    var sensitivity = 0;
    for (var i = 0; i < answers.length; i++) {
      final answer = answers[i];
      if (answer == null ||
          answer < 0 ||
          answer >= skinQuestions[i].options.length) {
        throw ArgumentError('Invalid answer at question ${i + 1}');
      }
      final option = skinQuestions[i].options[answer];
      option.points.forEach((t, p) => scores[t] = scores[t]! + p);
      sensitivity += option.sensitivity;
    }
    return SkinTestResult(
        type: resolve(scores),
        scores: scores,
        isSensitive: sensitivity >= 2,
        date: now ?? DateTime.now());
  }

  static SkinType resolve(Map<SkinType, int> scores) {
    const priority = [
      SkinType.combination,
      SkinType.oily,
      SkinType.dry,
      SkinType.normal
    ];
    final ranked = [...priority]..sort((a, b) {
        final diff = scores[b]!.compareTo(scores[a]!);
        return diff != 0
            ? diff
            : priority.indexOf(a).compareTo(priority.indexOf(b));
      });
    final first = ranked[0], second = ranked[1];
    final oilyDry = {first, second}.containsAll([SkinType.oily, SkinType.dry]);
    if (oilyDry && (scores[first]! - scores[second]!).abs() <= 2) {
      return SkinType.combination;
    }
    if (first != SkinType.normal &&
        scores[SkinType.combination]! > 0 &&
        scores[first]! - scores[SkinType.combination]! <= 1) {
      return SkinType.combination;
    }
    return first;
  }
}

class SkinTestStorage {
  static const key = 'navilo_skin_test_result_v1';
  static Future<void> save(SkinTestResult result) async {
    if (!await (await SharedPreferences.getInstance())
        .setString(key, jsonEncode(result.toJson()))) {
      throw StateError('Skin profile could not be saved');
    }
  }

  static Future<SkinTestResult?> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null) return null;
    try {
      return SkinTestResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static Future<void> clear() async {
    if (!await (await SharedPreferences.getInstance()).remove(key)) {
      throw StateError('Skin profile could not be removed');
    }
  }
}
