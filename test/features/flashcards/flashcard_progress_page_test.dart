import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/core/models/flashcard_review_preferences.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_session_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_progress_page.dart';

void main() {
  testWidgets('exibe progresso agregado e distribuição por classificação', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = InMemoryFlashcardSessionRepository(
      sessions: [
        FlashcardSessionSummary(
          id: 'today',
          startedAt: now.subtract(const Duration(minutes: 10)),
          finishedAt: now,
          cardCount: 4,
          difficultCount: 1,
          goodCount: 1,
          easyCount: 2,
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
    final preferencesRepository = InMemoryFlashcardReviewPreferencesRepository(
      preferences: const FlashcardReviewPreferences(dailyGoal: 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardProgressPage(
          repository: repository,
          preferencesRepository: preferencesRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Progresso dos flashcards'), findsOneWidget);
    expect(find.text('Últimos 7 dias'), findsOneWidget);
    expect(find.text('Hoje: 4/5 cards revisados.'), findsOneWidget);
    await tester.tap(find.text('Alterar'));
    await tester.pumpAndSettle();
    expect(find.text('Definir meta diária'), findsOneWidget);
    await tester.tap(find.text('10 cards por dia'));
    await tester.pumpAndSettle();
    expect((await preferencesRepository.get()).dailyGoal, 10);
    expect(find.text('6'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Meta semanal'), 250);
    await tester.tap(find.text('Definir'));
    await tester.pumpAndSettle();
    expect(find.text('Definir meta semanal'), findsOneWidget);
    await tester.tap(find.text('150 cards por semana'));
    await tester.pumpAndSettle();
    expect((await preferencesRepository.get()).weeklyGoal, 150);

    await tester.scrollUntilVisible(
      find.text('Distribuição das classificações'),
      500,
    );
    expect(find.text('Distribuição das classificações'), findsOneWidget);
    expect(find.textContaining('Difíceis'), findsOneWidget);
    expect(find.textContaining('33%'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Detalhamento por dia'), 300);
    expect(find.text('Detalhamento por dia'), findsOneWidget);
  });
}
