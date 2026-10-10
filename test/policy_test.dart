import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/policy.dart';

import 'dart:io';

void main() {
  final policy = Policy.decode(File('assets/policy.json').readAsStringSync());
  test('Margarin trans yağ sonucuna dönüşmez', () {
    expect(policy.evaluate('Margarin', 'food').map((r) => r.id), ['margarine']);
  });
  test('Tam eşleşme yanlış pozitifleri engeller', () {
    expect(
      policy.evaluate('maltitol içermez, maltitol syrup', 'food'),
      isEmpty,
    );
    expect(
      policy.evaluate('Sodium Laureth Sulfate', 'cosmetic').single.id,
      'sulfates',
    );
  });
  test('Kategori ayrımı ve Di-HEMA ayrımı korunur', () {
    expect(policy.evaluate('Maltitol', 'cosmetic'), isEmpty);
    expect(
      policy
          .evaluate('Di-HEMA Trimethylhexyl Dicarbamate', 'cosmetic')
          .single
          .id,
      'dihema',
    );
  });
  test('Başlangıç sözlüğünün kimlikleri benzersizdir', () {
    expect(policy.rules.map((r) => r.id).toSet().length, policy.rules.length);
  });
}
