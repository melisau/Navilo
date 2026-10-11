import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/domain/policy.dart';

import 'dart:io';

void main() {
  final policy = Policy.decode(File('assets/policy.json').readAsStringSync());
  test('Separate positive occurrence survives a negative claim', () {
    expect(
        policy.evaluate('Maltitol içermez, Maltitol', 'food').map((r) => r.id),
        contains('maltitol'));
    expect(policy.evaluate('without maltitol', 'food'), isEmpty);
    expect(policy.evaluate('maltitol-free', 'food'), isEmpty);
  });
  test('Group names never replace canonical ingredient text', () {
    for (final input in ['Dimethicone', 'Sodium Laureth Sulfate']) {
      expect(policy.correctOcrText(input), input);
      expect(policy.evaluate(input, 'cosmetic'), isNotEmpty);
    }
  });
  test('Margarin trans yağ sonucuna dönüşmez', () {
    expect(policy.evaluate('Margarin', 'food').map((r) => r.id), ['margarine']);
  });
  test('Tam eşleşme yanlış pozitifleri engeller', () {
    expect(
      policy.evaluate('maltitol içermez', 'food'),
      isEmpty,
    );
    expect(
      policy.evaluate('Sodium Laureth Sulfate', 'cosmetic').single.id,
      'sulfates',
    );
  });
  test('İçerik açıklaması içinde geçen maddeyi bulur', () {
    expect(
      policy.evaluate('Buğday unu (buğday unu içerir), kakao', 'food'),
      isEmpty,
    );
    expect(
      policy.evaluate('Sodyum benzoat (koruyucu)', 'food').single.id,
      'benzoate',
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
  test('OCR metnini değiştirmeden korur', () {
    expect(
      policy.correctOcrText('maltitoI, sodyum benzoaI'),
      'maltitoI, sodyum benzoaI',
    );
  });
  test('Belirsiz OCR kelimesini sessizce içeriğe dönüştürmez', () {
    expect(policy.correctOcrText('çikolata aroması'), 'çikolata aroması');
  });
}
