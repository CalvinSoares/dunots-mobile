import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/models/flashcard_review_preferences.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/shared/widgets/dunots_app_header.dart';

void main() {
  testWidgets('mostra o sino com pendências e abre a configuração', (
    tester,
  ) async {
    final now = DateTime.now();
    final preferencesRepository =
        InMemoryFlashcardReviewPreferencesRepository(
          preferences: const FlashcardReviewPreferences(
            reminderEnabled: true,
            reminderHour: 20,
            reminderMinute: 30,
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        home: DunotsAppHeader(
          flashcardRepository: InMemoryFlashcardRepository(
            cards: [
              Flashcard(
                id: 'header-card',
                front: 'Frente',
                back: 'Verso',
                createdAt: now,
                dueAt: now,
              ),
            ],
          ),
          flashcardReviewPreferencesRepository: preferencesRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Notificações pendentes'), findsOneWidget);
    await tester.tap(find.byTooltip('Notificações pendentes'));
    await tester.pumpAndSettle();

    expect(find.text('Revisões pendentes'), findsOneWidget);
    expect(find.text('1 card(s) aguardam revisão.'), findsOneWidget);
    expect(find.text('Lembrete diário'), findsOneWidget);

    await tester.tap(find.text('Lembrete diário'));
    await tester.pumpAndSettle();
    expect(find.text('Receber lembrete'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect((await preferencesRepository.get()).reminderEnabled, isFalse);
  });
}
