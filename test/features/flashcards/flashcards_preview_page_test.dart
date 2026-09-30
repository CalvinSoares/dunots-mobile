import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcards_preview_page.dart';

void main() {
  testWidgets('exibe métricas e filtra flashcards por situação', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = InMemoryFlashcardRepository(
      cards: [
        Flashcard(
          id: 'new',
          front: 'Card novo',
          back: 'Resposta nova',
          createdAt: now,
          tags: const ['redes'],
        ),
        Flashcard(
          id: 'due',
          front: 'Card vencido',
          back: 'Resposta vencida',
          createdAt: now,
          dueAt: now.subtract(const Duration(minutes: 1)),
          reviewCount: 2,
          lastRating: 'bom',
          tags: const ['SQL'],
        ),
        Flashcard(
          id: 'future',
          front: 'Card futuro',
          back: 'Resposta futura',
          createdAt: now,
          dueAt: now.add(const Duration(days: 1)),
          reviewCount: 1,
          lastRating: 'fácil',
          tags: const ['redes'],
        ),
        Flashcard(
          id: 'difficult',
          front: 'Card difícil',
          back: 'Resposta difícil',
          createdAt: now,
          dueAt: now,
          reviewCount: 3,
          lastRating: 'difícil',
          tags: const ['redes'],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlashcardsPreviewPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Todos os cards (4)'), findsOneWidget);
    expect(find.text('Vencidos (3)'), findsOneWidget);
    expect(find.text('Novos (1)'), findsOneWidget);
    expect(find.text('Difíceis (1)'), findsOneWidget);
    expect(find.text('Revisados (3)'), findsOneWidget);
    expect(find.text('3 pendentes hoje · 3 já revisados'), findsOneWidget);
    expect(find.text('Recomendação de revisão'), findsOneWidget);
    expect(find.text('Tema para priorizar: redes.'), findsOneWidget);

    final recommendedButton = find.widgetWithText(
      FilledButton,
      'Iniciar recomendada',
    );
    await tester.ensureVisible(recommendedButton);
    await tester.tap(recommendedButton);
    await tester.pumpAndSettle();
    expect(find.text('Montar revisão recomendada'), findsOneWidget);
    expect(find.text('4 cards disponíveis · 1 classificados como difíceis.'),
        findsOneWidget);
    expect(find.text('Todos (4)'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'futuro');
    await tester.pump();
    expect(find.text('Card futuro'), findsOneWidget);
    expect(find.text('Card vencido'), findsNothing);

    await tester.enterText(searchField, '');
    final redesChip = find.widgetWithText(FilterChip, 'redes');
    await tester.ensureVisible(redesChip);
    await tester.tap(redesChip);
    await tester.pump();
    expect(find.text('Card novo'), findsOneWidget);
    expect(find.text('Card futuro'), findsOneWidget);
    expect(find.text('Card vencido'), findsNothing);

    final todasChip = find.widgetWithText(FilterChip, 'Todas');
    await tester.ensureVisible(todasChip);
    await tester.tap(todasChip);
    await tester.pump();

    final reviewedChip = find.text('Revisados (3)');
    await tester.ensureVisible(reviewedChip);
    await tester.tap(reviewedChip);
    await tester.pump();

    expect(find.text('Card vencido'), findsOneWidget);
    expect(find.text('Card futuro'), findsOneWidget);
    expect(find.text('Card novo'), findsNothing);
  });
}
