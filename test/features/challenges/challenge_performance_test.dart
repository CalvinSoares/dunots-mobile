import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/challenges/domain/challenge.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge_performance.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge_review.dart';

void main() {
  test('calcula desempenho real por rating e pendências', () {
    final now = DateTime.utc(2026, 10, 1, 12);
    final challenges = [
      Challenge(
        id: 'due',
        title: 'Due',
        dueAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      Challenge(
        id: 'future',
        title: 'Future',
        dueAt: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 10)),
      ),
    ];
    final reviews = [
      ChallengeReview(
        id: 'review-1',
        challengeId: 'due',
        rating: 'fácil',
        reviewedAt: now.subtract(const Duration(days: 2)),
        previousInterval: 1,
        nextInterval: 4,
        dueAt: now.add(const Duration(days: 2)),
      ),
      ChallengeReview(
        id: 'review-2',
        challengeId: 'due',
        rating: 'again',
        reviewedAt: now.subtract(const Duration(days: 1)),
        previousInterval: 4,
        nextInterval: 0,
        dueAt: now.add(const Duration(minutes: 10)),
      ),
      ChallengeReview(
        id: 'review-3',
        challengeId: 'future',
        rating: 'bom',
        reviewedAt: now.subtract(const Duration(days: 3)),
        previousInterval: 1,
        nextInterval: 2,
        dueAt: now.add(const Duration(days: 1)),
      ),
    ];

    final performance = ChallengePerformance.from(
      challenges: challenges,
      reviews: reviews,
      now: now,
    );

    expect(performance.totalChallenges, 2);
    expect(performance.dueChallenges, 1);
    expect(performance.totalReviews, 3);
    expect(performance.successfulReviews, 2);
    expect(performance.successRate, closeTo(2 / 3, 0.0001));
    expect(performance.ratingCount('easy'), 1);
    expect(performance.ratingCount('medium'), 1);
    expect(performance.ratingCount('again'), 1);
  });
}
