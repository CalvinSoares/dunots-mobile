import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/models/flashcard_review_preferences.dart';
import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_session_repository.dart';
import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/today/today_page.dart';

void main() {
  testWidgets('exibe métricas reais e atalhos do mural', (tester) async {
    var openedCards = false;
    var openedQuestions = false;
    final now = DateTime(2026, 9, 30);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          flashcardRepository: InMemoryFlashcardRepository(
            cards: [
              Flashcard(
                id: 'card-today',
                front: 'Frente',
                back: 'Verso',
                createdAt: now,
              ),
            ],
          ),
          trackRepository: InMemoryStudyTrackRepository(
            tracks: [
              const StudyTrack(
                id: 'track-today',
                title: 'Trilha real',
                description: 'Descrição',
                completedItems: 2,
                totalItems: 4,
              ),
            ],
          ),
          attemptRepository: InMemoryQuizAttemptRepository(
            attempts: [
              QuizAttempt(
                id: 'attempt-today',
                title: 'Simulado real',
                questionIds: const ['question-1'],
                currentIndex: 0,
                status: QuizAttemptStatus.inProgress,
                answers: const {},
                createdAt: now,
                updatedAt: now,
              ),
            ],
          ),
          onOpenFlashcards: () => openedCards = true,
          onOpenQuestions: () => openedQuestions = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 cartões cadastrados'), findsOneWidget);
    expect(find.text('Lembrete de revisão'), findsOneWidget);
    expect(find.text('Simulado real'), findsOneWidget);
    expect(find.text('Trilha real'), findsOneWidget);
    expect(find.text('2/4 itens concluídos'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Abrir flashcards'), 300);
    await tester.tap(find.text('Abrir flashcards'));
    expect(openedCards, isTrue);
    await tester.scrollUntilVisible(find.text('Continuar simulado'), 300);
    await tester.tap(find.text('Continuar simulado'));
    expect(openedQuestions, isTrue);
  });

  testWidgets('oculta o lembrete quando a meta diária foi concluída', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          flashcardRepository: InMemoryFlashcardRepository(
            cards: [
              Flashcard(
                id: 'completed-card',
                front: 'Frente',
                back: 'Verso',
                createdAt: now,
                dueAt: now,
              ),
            ],
          ),
          flashcardSessionRepository: InMemoryFlashcardSessionRepository(
            sessions: [
              FlashcardSessionSummary(
                id: 'today',
                startedAt: now.subtract(const Duration(minutes: 5)),
                finishedAt: now,
                cardCount: 1,
                difficultCount: 0,
                goodCount: 1,
                easyCount: 0,
              ),
            ],
          ),
          flashcardReviewPreferencesRepository:
              InMemoryFlashcardReviewPreferencesRepository(
                preferences: const FlashcardReviewPreferences(dailyGoal: 1),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lembrete de revisão'), findsNothing);
  });

  testWidgets('permite desativar o lembrete pelo modal de horário', (
    tester,
  ) async {
    final now = DateTime.now();
    final preferencesRepository =
        InMemoryFlashcardReviewPreferencesRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          flashcardRepository: InMemoryFlashcardRepository(
            cards: [
              Flashcard(
                id: 'reminder-card',
                front: 'Frente',
                back: 'Verso',
                createdAt: now,
              ),
            ],
          ),
          flashcardReviewPreferencesRepository: preferencesRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Configurar horário'), 300);
    await tester.tap(find.text('Configurar horário'));
    await tester.pumpAndSettle();
    expect(find.text('Configurar lembrete'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect((await preferencesRepository.get()).reminderEnabled, isFalse);
    expect(find.text('Lembrete de revisão'), findsNothing);
  });
}
