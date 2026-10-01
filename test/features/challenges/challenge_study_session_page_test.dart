import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/challenges/challenge_study_session_page.dart';
import 'package:dunots_mobile/features/challenges/data/challenge_repository.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge.dart';

void main() {
  testWidgets('avança por vários desafios e exibe o resumo', (tester) async {
    final now = DateTime(2026, 9, 30);
    final repository = InMemoryChallengeRepository(
      items: [
        Challenge(id: 'one', title: 'Two Sum', createdAt: now),
        Challenge(id: 'two', title: 'Binary Tree', createdAt: now),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChallengeStudySessionPage(
          challenges: await repository.getAll(),
          repository: repository,
        ),
      ),
    );

    expect(find.text('Two Sum'), findsOneWidget);
    await tester.tap(find.text('Mostrar solução'));
    await tester.pump();
    await tester.tap(find.text('fácil'));
    await tester.pump();

    expect(find.text('Binary Tree'), findsOneWidget);
    await tester.tap(find.text('Mostrar solução'));
    await tester.pump();
    await tester.tap(find.text('fácil'));
    await tester.pump();

    expect(find.text('Sessão concluída'), findsNWidgets(2));
    expect(find.text('2 desafios revisados.'), findsOneWidget);
    expect(find.text('Fácil: 2'), findsOneWidget);
  });
}
