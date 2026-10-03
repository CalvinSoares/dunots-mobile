import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcards_preview_page.dart';

void main() {
  testWidgets('mostra o card criado sem aguardar uma nova leitura lenta', (
    tester,
  ) async {
    final repository = _DelayedReadFlashcardRepository(
      initialCards: [
        Flashcard(
          id: 'existing-card',
          front: 'Card existente',
          back: 'Resposta existente',
          createdAt: DateTime(2026, 10, 1),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FlashcardsPreviewPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Novo'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Card criado');
    await tester.enterText(fields.at(1), 'Resposta criada');
    await tester.tap(find.text('Criar'));
    await tester.pump();

    expect(find.text('Card criado'), findsOneWidget);
  });

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

    expect(find.byTooltip('Filtrar flashcards'), findsOneWidget);
    expect(find.text('Todos (4)'), findsNothing);
    expect(find.text('3 cards para revisar'), findsOneWidget);
    expect(find.text('1 card difícil · priorize redes.'), findsOneWidget);

    final recommendedButton = find.widgetWithText(TextButton, 'Revisar');
    await tester.ensureVisible(recommendedButton);
    await tester.tap(recommendedButton);
    await tester.pumpAndSettle();
    expect(find.text('Montar revisão recomendada'), findsOneWidget);
    expect(find.textContaining('3 cards disponíveis'), findsOneWidget);
    expect(find.text('Todos os cards (3)'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'futuro');
    await tester.pump();
    expect(find.text('Card futuro'), findsOneWidget);
    expect(find.text('Card vencido'), findsNothing);

    await tester.enterText(searchField, '');
    await tester.tap(find.byTooltip('Filtrar flashcards'));
    await tester.pumpAndSettle();
    expect(find.text('Todos (4)'), findsOneWidget);
    expect(find.text('Vencidos (3)'), findsOneWidget);
    expect(find.text('Novos (1)'), findsOneWidget);
    expect(find.text('Difíceis (1)'), findsOneWidget);
    expect(find.text('Revisados (3)'), findsOneWidget);

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

  testWidgets('salva as preferências alteradas na tela', (tester) async {
    final preferencesRepository =
        InMemoryFlashcardReviewPreferencesRepository();
    final now = DateTime.now();
    final repository = InMemoryFlashcardRepository(
      cards: [
        Flashcard(
          id: 'card',
          front: 'Card',
          back: 'Resposta',
          createdAt: now,
          dueAt: now,
          reviewCount: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlashcardsPreviewPage(
            repository: repository,
            preferencesRepository: preferencesRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mais ações dos flashcards'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configurar revisão'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10 cards').last);
    await tester.pump();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();

    final saved = await preferencesRepository.get();
    expect(saved.dailyLimit, 10);
    expect(saved.preferRecommended, isTrue);
  });

  testWidgets('mantém ações e filtros utilizáveis em tela estreita', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 800,
            child: FlashcardsPreviewPage(
              repository: InMemoryFlashcardRepository(
                cards: [
                  Flashcard(
                    id: 'mobile-card',
                    front: 'Pergunta longa para testar a largura',
                    back: 'Resposta',
                    createdAt: now,
                    tags: const ['redes', 'infraestrutura', 'prioridade'],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mais ações dos flashcards'), findsOneWidget);
    expect(find.byTooltip('Histórico'), findsNothing);
    expect(find.byTooltip('Progresso'), findsNothing);
    expect(find.text('Novo'), findsOneWidget);
    expect(find.byTooltip('Filtrar flashcards'), findsOneWidget);
    expect(find.text('Configurar revisão'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Mais ações dos flashcards'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico'), findsOneWidget);
    expect(find.text('Progresso'), findsOneWidget);
    expect(find.text('Configurar revisão'), findsOneWidget);
  });
}

class _DelayedReadFlashcardRepository implements FlashcardRepository {
  final List<Flashcard> _cards;
  bool _delayReads = false;

  _DelayedReadFlashcardRepository({List<Flashcard> initialCards = const []})
    : _cards = List.of(initialCards);

  @override
  Future<List<Flashcard>> getAll() {
    if (!_delayReads) return Future.value(List.unmodifiable(_cards));
    return Future<List<Flashcard>>.delayed(
      const Duration(seconds: 5),
      () => List.unmodifiable(_cards),
    );
  }

  @override
  Future<void> create(Flashcard card) async {
    _cards.add(card);
    _delayReads = true;
  }

  @override
  Future<void> update(Flashcard card) async {
    final index = _cards.indexWhere((item) => item.id == card.id);
    _cards[index] = card;
  }

  @override
  Future<void> delete(String cardId) async {
    _cards.removeWhere((card) => card.id == cardId);
  }

  @override
  Future<void> recordReview({
    required String cardId,
    required String rating,
    required DateTime reviewedAt,
    required DateTime dueAt,
  }) async {}
}
