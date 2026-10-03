import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/study/data/study_phase_repository.dart';
import 'package:dunots_mobile/features/today/today_page.dart';

void main() {
  testWidgets('cria uma fase pelo Hoje e exibe seu progresso', (tester) async {
    final now = DateTime(2026, 9, 30);
    final phaseRepository = InMemoryStudyPhaseRepository();
    final card = Flashcard(
      id: 'phase-card',
      front: 'O que é VLAN?',
      back: 'Uma rede lógica.',
      createdAt: now,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(
          phaseRepository: phaseRepository,
          flashcardRepository: InMemoryFlashcardRepository(cards: [card]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('Nova fase de estudo'),
      300,
    );
    await tester.tap(find.byTooltip('Nova fase de estudo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Redes');
    await tester.pump();
    await tester.tap(find.text('O que é VLAN?'));
    await tester.tap(find.widgetWithText(FilledButton, 'Criar fase'));
    await tester.pumpAndSettle();

    expect(find.text('Redes'), findsOneWidget);
    expect(find.textContaining('1/1 concluídos'), findsNothing);
    expect((await phaseRepository.getAll()).single.flashcardIds, [
      'phase-card',
    ]);

    await tester.scrollUntilVisible(find.text('Redes'), 300);
    await tester.tap(find.text('Redes'));
    await tester.pumpAndSettle();
    expect(find.text('Progresso'), findsOneWidget);
    await tester.tap(find.byTooltip('Editar fase'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Redes essenciais');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar alterações'));
    await tester.pumpAndSettle();

    expect((await phaseRepository.getAll()).single.title, 'Redes essenciais');
  });
}
