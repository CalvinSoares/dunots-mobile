import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/main.dart';

void main() {
  testWidgets('renderiza o shell inicial do Dunots', (tester) async {
    await tester.pumpWidget(const DunotsMobileApp());

    expect(find.text('dunots'), findsOneWidget);
    expect(find.text('revisões de hoje'), findsOneWidget);
    expect(find.text('32'), findsOneWidget);
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Cards'), findsOneWidget);
  });

  testWidgets('navega entre as áreas principais', (tester) async {
    await tester.pumpWidget(const DunotsMobileApp());

    await tester.tap(find.text('Cards'));
    await tester.pumpAndSettle();
    expect(find.text('Flashcards'), findsOneWidget);

    await tester.tap(find.text('Trilhas'));
    await tester.pumpAndSettle();
    expect(find.text('Trilhas de estudo'), findsOneWidget);
  });
}