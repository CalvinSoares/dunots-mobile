import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dunots_mobile/features/today/today_page.dart';

void main() {
  testWidgets('Hoje não exibe ações dos módulos removidos', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TodayPage()));
    await tester.pumpAndSettle();

    expect(find.text('Abrir desafios'), findsNothing);
    expect(find.text('Iniciar estudo misto'), findsNothing);
  });
}
