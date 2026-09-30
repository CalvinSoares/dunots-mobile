import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_session_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_session_history_page.dart';

void main() {
  testWidgets('exibe métricas acumuladas das sessões recentes', (tester) async {
    final now = DateTime.now();
    final repository = InMemoryFlashcardSessionRepository(
      sessions: [
        FlashcardSessionSummary(
          id: 'today',
          startedAt: now.subtract(const Duration(minutes: 10)),
          finishedAt: now,
          cardCount: 3,
          difficultCount: 1,
          goodCount: 1,
          easyCount: 1,
        ),
        FlashcardSessionSummary(
          id: 'yesterday',
          startedAt: now.subtract(const Duration(days: 1, minutes: 20)),
          finishedAt: now.subtract(const Duration(days: 1)),
          cardCount: 2,
          difficultCount: 0,
          goodCount: 1,
          easyCount: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: FlashcardSessionHistoryPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Últimos 7 dias'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('5'), findsWidgets);
    expect(find.text('Sessões recentes'), findsOneWidget);
    expect(find.textContaining('3 cards'), findsOneWidget);
    expect(find.textContaining('2 cards'), findsOneWidget);
  });
}
