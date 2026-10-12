import 'dart:convert';
import 'dart:io';
import 'package:navilo/domain/dietary.dart';
void main() {
  const text = 'pirinç, kahverengi pirinç, deniz tuzu';
  final data = jsonDecode(File('assets/dietary.json').readAsStringSync());
  final entries = (data['entries'] as List).map((e) => DietaryEntry(Map<String, dynamic>.from(e))).where((e) => e.matches(text)).toList();
  final lactose = entries.where((e) => e.kind == 'lactose_check').toList();
  final rice = isSimpleRiceList(text);
  final sugar = listedSugarAdditions(text);
  if (!rice || lactose.isNotEmpty || sugar.isNotEmpty) throw StateError('Rice badge regression');
  stdout.writeln('PASS: exact user text; rice=true, lactose warnings=0, listed sugar additions=0');
}
