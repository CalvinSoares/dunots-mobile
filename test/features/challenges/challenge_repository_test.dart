import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/challenges/data/challenge_repository.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge.dart';

void main() {
  test('registra revisão, atualiza SRS e preserva histórico', () async {
    final repository = InMemoryChallengeRepository(
      items: [
        Challenge(
          id: 'challenge-1',
          title: 'Two Sum',
          createdAt: DateTime(2026, 9, 30),
        ),
      ],
    );
    final reviewedAt = DateTime(2026, 9, 30, 10);

    await repository.recordReview(
      challengeId: 'challenge-1',
      rating: 'fácil',
      reviewedAt: reviewedAt,
    );

    final challenge = (await repository.getAll()).single;
    final history = await repository.getReviewHistory('challenge-1');

    expect(challenge.repetitions, 1);
    expect(challenge.interval, 4);
    expect(challenge.dueAt, reviewedAt.add(const Duration(days: 4)));
    expect(history, hasLength(1));
    expect(history.single.rating, 'fácil');
    expect(history.single.nextInterval, 4);
  });

  test('dificuldade reinicia a repetição e agenda revisão curta', () async {
    final repository = InMemoryChallengeRepository(
      items: [
        Challenge(
          id: 'challenge-1',
          title: 'Binary Tree',
          interval: 5,
          repetitions: 2,
          createdAt: DateTime(2026, 9, 30),
        ),
      ],
    );
    final reviewedAt = DateTime(2026, 9, 30, 10);

    await repository.recordReview(
      challengeId: 'challenge-1',
      rating: 'difícil',
      reviewedAt: reviewedAt,
    );

    final challenge = (await repository.getAll()).single;
    expect(challenge.repetitions, 0);
    expect(challenge.interval, 0);
    expect(challenge.dueAt, reviewedAt.add(const Duration(minutes: 10)));
  });
}
