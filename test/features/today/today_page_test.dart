import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/models/flashcard_review_preferences.dart';
import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/core/notifications/local_notification_service.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_session_repository.dart';
import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/today/today_page.dart';

void main() {
  testWidgets('exibe foco de revisão e ações secundárias do mural', (
    tester,
  ) async {
    var openedCards = false;
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lembrete de revisão'), findsNothing);
    expect(find.text('Trilha real'), findsOneWidget);
    expect(find.text('2/4 itens concluídos'), findsOneWidget);
    expect(find.byTooltip('Mais ações de estudo'), findsNothing);
    expect(find.text('Abrir flashcards'), findsNothing);
    expect(openedCards, isFalse);
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

  testWidgets('abre o cadastro ao tocar no estado sem fases', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TodayPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nenhuma fase criada'));
    await tester.pumpAndSettle();

    expect(find.text('Nova fase de estudo'), findsOneWidget);
  });

  testWidgets('aciona a abertura de trilhas no estado vazio', (tester) async {
    var openedTracks = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          trackRepository: InMemoryStudyTrackRepository(tracks: const []),
          onOpenTracks: () => openedTracks = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final emptyTracks = find.text('Nenhuma trilha criada');
    await tester.ensureVisible(emptyTracks);
    await tester.tap(emptyTracks);
    await tester.pumpAndSettle();

    expect(openedTracks, isTrue);
  });

  testWidgets('não bloqueia o mural quando a notificação falha', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          localNotificationService: _FailingNotificationService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Não foi possível carregar o mural.'), findsNothing);
  });

  testWidgets('centraliza os estados de erro do mural', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          child: TodayPage(flashcardRepository: _FailingFlashcardRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final error = find.text('Não foi possível carregar o mural.');
    expect(error, findsOneWidget);
    expect(
      find.ancestor(of: error, matching: find.byType(Center)),
      findsOneWidget,
    );
  });
}

class _FailingNotificationService implements LocalNotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> syncDailyFlashcardReminder({
    required FlashcardReviewPreferences preferences,
    required int completedToday,
    required int dueCount,
  }) async {
    throw StateError('notificação indisponível');
  }
}

class _FailingFlashcardRepository implements FlashcardRepository {
  @override
  Future<List<Flashcard>> getAll() async {
    throw StateError('banco indisponível');
  }

  @override
  Future<void> create(Flashcard card) async {}

  @override
  Future<void> update(Flashcard card) async {}

  @override
  Future<void> delete(String cardId) async {}

  @override
  Future<void> recordReview({
    required String cardId,
    required String rating,
    required DateTime reviewedAt,
    required DateTime dueAt,
  }) async {}
}
