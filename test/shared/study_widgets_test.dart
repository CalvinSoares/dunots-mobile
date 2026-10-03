import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/shared/widgets/study_widgets.dart';

void main() {
  testWidgets('expõe ações customizadas com semântica de botão', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickAction(
            icon: Icons.style_outlined,
            title: 'Abrir flashcards',
            subtitle: '10 cartões para revisar',
            color: Colors.blue,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Abrir flashcards'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expõe o estado do card de revisão', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReviewCard(count: 4, onPressed: () {})),
      ),
    );

    final semantics = tester.getSemantics(find.byType(ReviewCard));
    expect(semantics.label, '4 revisões de hoje');
    expect(find.bySemanticsLabel('abrir flashcards'), findsOneWidget);
  });
}
