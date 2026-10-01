import 'challenge.dart';
import 'challenge_review.dart';

class ChallengePerformance {
  final int totalChallenges;
  final int dueChallenges;
  final int totalReviews;
  final int successfulReviews;
  final Map<String, int> ratings;

  const ChallengePerformance({
    required this.totalChallenges,
    required this.dueChallenges,
    required this.totalReviews,
    required this.successfulReviews,
    required this.ratings,
  });

  factory ChallengePerformance.from({
    required List<Challenge> challenges,
    required List<ChallengeReview> reviews,
    required DateTime now,
  }) {
    final ratings = <String, int>{
      'again': 0,
      'hard': 0,
      'medium': 0,
      'easy': 0,
    };
    for (final review in reviews) {
      final rating = _normalizeRating(review.rating);
      ratings[rating] = (ratings[rating] ?? 0) + 1;
    }

    return ChallengePerformance(
      totalChallenges: challenges.length,
      dueChallenges: challenges
          .where((challenge) => challenge.isDueAt(now))
          .length,
      totalReviews: reviews.length,
      successfulReviews: reviews.where((review) {
        return _normalizeRating(review.rating) != 'again';
      }).length,
      ratings: Map.unmodifiable(ratings),
    );
  }

  double get successRate {
    if (totalReviews == 0) return 0;
    return successfulReviews / totalReviews;
  }

  int ratingCount(String rating) => ratings[rating] ?? 0;

  static String _normalizeRating(String rating) {
    final normalized = rating.trim().toLowerCase();
    if (normalized == 'again' || normalized.contains('novamente')) {
      return 'again';
    }
    if (normalized == 'hard' || normalized.contains('dif')) return 'hard';
    if (normalized == 'medium' || normalized.contains('bom')) return 'medium';
    if (normalized == 'easy' ||
        normalized.contains('fác') ||
        normalized.contains('fac')) {
      return 'easy';
    }
    return normalized;
  }
}
