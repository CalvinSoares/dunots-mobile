import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/main.dart';
import 'package:dunots_mobile/shared/widgets/dunots_bottom_navigation.dart';

void main() {
  testWidgets('renderiza o shell inicial do Dunots', (tester) async {
    await tester.pumpWidget(const DunotsMobileApp());
    await tester.pumpAndSettle();

    expect(find.text('Hoje'), findsAtLeastNWidgets(1));
    expect(find.text('Estudar'), findsOneWidget);
    expect(find.text('Questões'), findsOneWidget);
    expect(find.text('Trilhas'), findsOneWidget);
    expect(find.text('Mais'), findsNothing);
    expect(find.byType(DunotsBottomNavigation), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNothing);
  });

  testWidgets('navega entre as áreas principais', (tester) async {
    await tester.pumpWidget(const DunotsMobileApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Estudar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pendentes hoje'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Desafios'), findsNothing);

    await tester.tap(find.text('Trilhas'));
    await tester.pumpAndSettle();
    expect(find.text('Minhas trilhas'), findsOneWidget);

    await tester.tap(find.text('Questões'));
    await tester.pumpAndSettle();
    expect(find.text('Questões'), findsAtLeastNWidgets(2));
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
    expect(find.byType(DunotsBottomNavigation), findsNothing);
    expect(find.text('Hoje'), findsAtLeastNWidgets(1));
    expect(find.text('Estudar'), findsOneWidget);
    expect(find.text('Questões'), findsOneWidget);
    expect(find.text('Trilhas'), findsOneWidget);
    expect(find.text('Mais'), findsNothing);

    await tester.tap(find.text('Estudar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('pendentes hoje'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Desafios'), findsNothing);
  });
}
