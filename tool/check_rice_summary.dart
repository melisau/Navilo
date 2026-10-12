// ignore_for_file: avoid_print
import 'package:navilo/domain/dietary.dart';

void main() {
  final cases = <String, bool>{
    'Pirinç, kahverengi pirinç, deniz tuzu': true,
    'İçindekiler: PİRİNÇ (%99), DENİZ TUZU.': true,
    'Rice, brown rice, sea salt': true,
    'Pirinç\nKahverengi pirinç\nDeniz tuzu': true,
    'Pirinç, tam tahıllı pirinç, tuz': true,
    'Pirinç\nsüt tozu': false,
    'pirinç, süt tozu': false,
    'pirinç, buğday': false,
    'pirinç, aroma verici': false,
    'pirinç, bilinmeyen': false,
    'pirinç,': false,
    'pirinç (süt, tuz)': false,
    'pirinç, eser miktarda gluten içerebilir': false,
    'iyi, deniz tuzu': false,
    '': false,
  };
  for (final entry in cases.entries) {
    if (isSimpleRiceList(entry.key) != entry.value) throw StateError(entry.key);
  }
  print('PASS: 15 positive-evidence and unknown-ingredient checks');
}
