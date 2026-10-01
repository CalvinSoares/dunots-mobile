import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_session_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_srs.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_study_page.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';

void main() {
  final card = Flashcard(
    id: 'study-card',
    front: 'Qual é a resposta?',
    back: 'Uma resposta correta',
    createdAt: DateTime(2026, 9, 30),
  );

  testWidgets('exige resposta correta antes de mostrar classificações', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FlashcardStudyPage(cards: [card])),
    );

    expect(find.text('Conferir resposta'), findsOneWidget);
    expect(find.text('Fácil'), findsNothing);

    await tester.enterText(find.byType(TextField), 'resposta errada');
    await tester.tap(find.text('Conferir resposta'));
    await tester.pump();

    expect(
      find.text('A resposta precisa estar correta para continuar.'),
      findsOneWidget,
    );
    expect(find.text('Fácil'), findsNothing);
  });

  testWidgets('mostra classificações e conclui após resposta correta', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: FlashcardStudyPage(cards: [card])),
    );

    await tester.enterText(find.byType(TextField), 'Uma   resposta correta');
    await tester.tap(find.text('Conferir resposta'));
    await tester.pump();

    expect(find.text('Resposta correta'), findsOneWidget);
    expect(find.text('Difícil'), findsOneWidget);
    expect(find.text('Bom'), findsOneWidget);
    expect(find.text('Fácil'), findsOneWidget);

    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();

    expect(find.text('Sessão concluída'), findsOneWidget);
    expect(find.text('1 flashcards respondidos.'), findsOneWidget);
  });

  test('calcula os próximos intervalos da revisão', () {
    final reviewedAt = DateTime(2026, 9, 30, 10);

    expect(
      FlashcardScheduler.nextReviewAt(
        rating: 'difícil',
        reviewedAt: reviewedAt,
      ),
      DateTime(2026, 10, 1, 10),
    );
  });

  test('repositório em memória persiste a classificação', () async {
    final repository = InMemoryFlashcardRepository(cards: [card]);
    final reviewedAt = DateTime(2026, 9, 30, 10);
    final dueAt = DateTime(2026, 10, 4, 10);

    await repository.recordReview(
      cardId: card.id,
      rating: 'fácil',
      reviewedAt: reviewedAt,
      dueAt: dueAt,
    );

    final saved = (await repository.getAll()).single;
    expect(saved.reviewCount, 1);
    expect(saved.lastRating, 'fácil');
    expect(saved.lastReviewedAt, reviewedAt);
    expect(saved.dueAt, dueAt);
    expect(saved.interval, 4);
    expect(saved.repetitions, 1);
    expect(saved.easeFactor, 2.65);
  });

  testWidgets('exibe materiais relacionados depois do acerto', (tester) async {
    final linkedCard = card.copyWith(linkedMaterialIds: const ['question-1']);
    final materials = InMemoryStudyMaterialRepository(
      materials: const [
        StudyMaterial(
          id: 'question-1',
          type: StudyMaterialType.question,
          title: 'Questão relacionada',
          subtitle: 'Questão · Redes',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardStudyPage(
          cards: [linkedCard],
          materialRepository: materials,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), card.back);
    await tester.tap(find.text('Conferir resposta'));
    await tester.pump();

    expect(find.text('Ver materiais relacionados (1)'), findsOneWidget);
    await tester.tap(find.text('Ver materiais relacionados (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Questão relacionada'), findsOneWidget);
  });

  testWidgets('persiste o resumo ao concluir a sessão', (tester) async {
    final sessionRepository = InMemoryFlashcardSessionRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardStudyPage(
          cards: [card],
          sessionRepository: sessionRepository,
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), card.back);
    await tester.tap(find.text('Conferir resposta'));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pumpAndSettle();

    final summaries = await sessionRepository.getForDay(DateTime.now());
    expect(summaries, hasLength(1));
    expect(summaries.single.cardCount, 1);
    expect(summaries.single.easyCount, 1);
    expect(summaries.single.answeredCount, 1);
  });
}
