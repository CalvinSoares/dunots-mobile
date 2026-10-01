import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/challenges/challenges_preview_page.dart';
import 'package:dunots_mobile/features/challenges/data/challenge_repository.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge.dart';

void main() {
  testWidgets('abre detalhes e registra uma revisão do desafio', (
    tester,
  ) async {
    final repository = InMemoryChallengeRepository(
      items: [
        Challenge(
          id: 'challenge-1',
          title: 'Two Sum',
          solution: 'Use um mapa para guardar os complementos.',
          createdAt: DateTime(2026, 9, 30),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChallengesPreviewPage(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Two Sum');
    await tester.ensureVisible(title);
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(find.text('Detalhes do desafio'), findsOneWidget);
    expect(find.text('Resolver desafio'), findsOneWidget);

    await tester.tap(find.text('Resolver desafio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar solução'));
    await tester.pumpAndSettle();
    expect(
      find.text('Use um mapa para guardar os complementos.'),
      findsOneWidget,
    );

    await tester.tap(find.text('fácil'));
    await tester.pumpAndSettle();
    expect(find.text('Histórico de revisões'), findsOneWidget);
    expect(find.text('fácil'), findsWidgets);
  });
}
