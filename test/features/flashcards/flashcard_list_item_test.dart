import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/flashcards/flashcard_demo_data.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_list_item.dart';

void main() {
  testWidgets('exibe os dados do flashcard', (tester) async {
    final card = demoFlashcards.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlashcardListItem(card: card)),
      ),
    );

    expect(find.text(card.front), findsOneWidget);
    expect(find.text(card.back), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(FlashcardListItem));
    expect(semantics.label, startsWith('Flashcard: ${card.front}.'));
    expect(semantics.hint, 'Toque para abrir os detalhes.');
  });

  testWidgets('abre os detalhes ao tocar no flashcard', (tester) async {
    final card = demoFlashcards.first;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlashcardListItem(card: card)),
      ),
    );

    await tester.tap(find.text(card.front));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do flashcard'), findsOneWidget);
    expect(find.text('Pergunta'), findsOneWidget);
    expect(find.text('Resposta'), findsOneWidget);
    expect(find.text(card.back), findsOneWidget);
  });
}
