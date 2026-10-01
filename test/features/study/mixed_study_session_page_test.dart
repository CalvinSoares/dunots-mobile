import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/challenges/data/challenge_repository.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_session_repository.dart';
import 'package:dunots_mobile/features/study/mixed_study_session_page.dart';

void main() {
  testWidgets('mistura tipos, mantém progresso único e separa o resumo', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 30);
    final flashcardRepository = InMemoryFlashcardRepository(
      cards: [
        Flashcard(
          id: 'card-1',
          front: 'Qual é a capital do Brasil?',
          back: 'Brasília',
          createdAt: now,
        ),
      ],
    );
    final challengeRepository = InMemoryChallengeRepository(
      items: [
        Challenge(
          id: 'challenge-1',
          title: 'Two Sum',
          notes: 'Encontre os índices que somam o alvo.',
          solution: 'Use um mapa para guardar os complementos.',
          createdAt: now,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MixedStudySessionPage(
          cards: await flashcardRepository.getAll(),
          challenges: await challengeRepository.getAll(),
          flashcardRepository: flashcardRepository,
          challengeRepository: challengeRepository,
          sessionRepository: InMemoryFlashcardSessionRepository(),
        ),
      ),
    );

    expect(find.text('Flashcard'), findsOneWidget);
    expect(find.text('Estudo misto · 1/2'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Brasília');
    await tester.tap(find.text('Conferir resposta'));
    await tester.pump();
    await tester.tap(find.text('Bom'));
    await tester.pump();

    expect(find.text('Desafio'), findsOneWidget);
    expect(find.text('Estudo misto · 2/2'), findsOneWidget);
    await tester.tap(find.text('Mostrar solução'));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();

    expect(find.text('Resumo por tipo'), findsOneWidget);
    expect(find.text('Flashcards · 1'), findsOneWidget);
    expect(find.text('Desafios · 1'), findsOneWidget);
    expect(find.text('Bons: 1'), findsOneWidget);
    expect(find.text('Fáceis: 1'), findsOneWidget);
  });
}
