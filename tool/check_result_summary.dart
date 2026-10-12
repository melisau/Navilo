import 'dart:io';

import 'package:navilo/domain/dietary.dart';
import 'package:navilo/domain/policy.dart';

void main() {
  void check(bool value) {
    if (!value) throw StateError('Summary regression');
  }

  check(glutenFreeIngredients('MISIR NİŞASTASI, PİRİNÇ UNU, PATATES NİŞASTASI')
          .length ==
      3);
  check(glutenFreeIngredients('Mısır nişastası, pirinç unu, patates nişastası')
          .length ==
      3);
  check(glutenFreeIngredients('iyi, bilinmeyen nişasta').isEmpty);
  check(hasGlutenFreeClaim('GLUTENSİZ Ekmek Unu'));
  check(!hasGlutenFreeClaim('glutenli, pirinç unu'));
  check(containsIngredient('SÜT TOZU', 'süt tozu'));
  check(normalize('I İ ı i i\u0307') == 'i i i i i');
  stdout.writeln('PASS: 7 summary and Turkish-letter checks');
}
