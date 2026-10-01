import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/challenges/data/challenge_repository.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge_review.dart';
import 'package:dunots_mobile/features/today/today_page.dart';

void main() {
  testWidgets('mostra desempenho de desafios com base no histórico real', (
    tester,
  ) async {
    final now = DateTime.now();
    final repository = InMemoryChallengeRepository(
      items: [
        Challenge(
          id: 'due-challenge',
          title: 'Desafio pendente',
          dueAt: now.subtract(const Duration(hours: 1)),
          createdAt: now.subtract(const Duration(days: 4)),
        ),
      ],
      reviews: [
        ChallengeReview(
          id: 'review-1',
          challengeId: 'due-challenge',
          rating: 'easy',
          reviewedAt: now.subtract(const Duration(days: 2)),
          previousInterval: 1,
          nextInterval: 4,
          dueAt: now.add(const Duration(days: 2)),
        ),
        ChallengeReview(
          id: 'review-2',
          challengeId: 'due-challenge',
          rating: 'again',
          reviewedAt: now.subtract(const Duration(days: 1)),
          previousInterval: 4,
          nextInterval: 0,
          dueAt: now.add(const Duration(minutes: 10)),
        ),
        ChallengeReview(
          id: 'review-3',
          challengeId: 'due-challenge',
          rating: 'medium',
          reviewedAt: now.subtract(const Duration(hours: 2)),
          previousInterval: 0,
          nextInterval: 1,
          dueAt: now.add(const Duration(days: 1)),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: TodayPage(challengeRepository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Desempenho dos desafios'), 300);

    expect(find.text('Desempenho dos desafios'), findsOneWidget);
    expect(find.text('67% aproveitamento'), findsOneWidget);
    expect(find.text('3 revisões'), findsOneWidget);
    expect(find.text('1 pendentes'), findsOneWidget);
    expect(find.text('novamente 1'), findsOneWidget);
    expect(find.text('bom 1'), findsOneWidget);
    expect(find.text('fácil 1'), findsOneWidget);
  });
}
