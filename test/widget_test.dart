import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/main.dart';

void main() {
  testWidgets('renderiza o shell inicial do Dunots', (tester) async {
    await tester.pumpWidget(const DunotsMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('dunots'), findsOneWidget);
    expect(find.text('revisões de hoje'), findsOneWidget);
    expect(find.text('flashcards cadastrados'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
  });

  testWidgets('navega entre as áreas principais', (tester) async {
    await tester.pumpWidget(const DunotsMobileApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    expect(find.text('Flashcards'), findsOneWidget);

    await tester.tap(find.text('Trilhas'));
    await tester.pumpAndSettle();
    expect(find.text('Trilhas de estudo'), findsOneWidget);
  });

  testWidgets('troca a barra inferior por rail em telas largas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DunotsMobileApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    expect(find.text('Flashcards'), findsOneWidget);
  });
}
