import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:navilo/main.dart';

void main() {
  testWidgets('Navilo loads policy and evaluation screen', (tester) async {
    await tester.pumpWidget(const IngredientApp());
    await tester.pumpAndSettle();
    expect(find.text('Navilo · Prototip'), findsOneWidget);
    expect(find.text('Kriterleri kontrol et'), findsOneWidget);
    expect(find.text('Fotoğraf çek'), findsOneWidget);
    expect(find.text('Görsel ekle'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('EN'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Add image'), findsOneWidget);
    expect(find.text('Check criteria'), findsOneWidget);
    await tester.tap(find.text('TR'));
    await tester.pumpAndSettle();
    expect(find.text('Fotoğraf çek'), findsOneWidget);
  });
}
