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

  testWidgets('mantém o fim da sessão acima da navegação do sistema', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final viewport in const [
      Size(320, 800),
      Size(360, 800),
      Size(390, 800),
      Size(414, 800),
      Size(840, 800),
      Size(800, 360),
    ]) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(bottom: 24),
              viewPadding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: FlashcardStudyPage(cards: [card]),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(SafeArea),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byType(SingleChildScrollView)).bottom,
        lessThanOrEqualTo(viewport.height - 24),
      );
    }
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

  testWidgets('revela o gabarito e avança registrando o card como difícil', (
    tester,
  ) async {
    final secondCard = card.copyWith(
      id: 'study-card-2',
      front: 'Qual é a segunda resposta?',
    );
    final repository = InMemoryFlashcardRepository(cards: [card, secondCard]);

    await tester.pumpWidget(
      MaterialApp(
        home: FlashcardStudyPage(
          cards: [card, secondCard],
          repository: repository,
        ),
      ),
    );

    await tester.tap(find.text('Não lembro — ver resposta'));
    await tester.pump();

    expect(find.text('Gabarito'), findsOneWidget);
    expect(find.text(card.back), findsOneWidget);
    expect(find.text('Próximo card'), findsOneWidget);

    await tester.tap(find.text('Próximo card'));
    await tester.pumpAndSettle();

    expect(find.text(secondCard.front), findsOneWidget);
    final savedCard = (await repository.getAll()).first;
    expect(savedCard.lastRating, 'difícil');
    expect(savedCard.reviewCount, 1);
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
