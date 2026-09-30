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
  });
}
