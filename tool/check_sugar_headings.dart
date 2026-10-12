import 'dart:io';

import 'package:navilo/domain/dietary.dart';
import 'package:navilo/domain/ingredient_text.dart';

void main() {
  for (final heading in [
    'içindekiler:',
    'İÇİNDEKİLER:',
    'icindekiler',
    'Içındekiler',
    'Içindekiler'
  ]) {
    final parsed = IngredientText.parse('$heading Pirinç, deniz tuzu.');
    if (!parsed.headingFound ||
        parsed.ingredients != 'Pirinç, deniz tuzu.' ||
        !isSimpleRiceList('$heading Pirinç, deniz tuzu.')) {
      throw StateError('Heading: $heading');
    }
  }
  for (final text in [
    'Pirinç, şeker',
    'Rice, glucose syrup',
    'Yulaf, bal',
    'Pirinç, dekstroz'
  ]) {
    if (listedSugarAdditions(text).isEmpty) throw StateError(text);
  }
  for (final text in [
    'Pirinç, kahverengi pirinç, deniz tuzu',
    'Sugar-free rice',
    'Şekersiz pirinç'
  ]) {
    if (listedSugarAdditions(text).isNotEmpty) throw StateError(text);
  }
  stdout.writeln('PASS: 12 heading and listed-sugar checks');
}
