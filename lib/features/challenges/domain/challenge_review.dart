class ChallengeReview {
  final String id;
  final String challengeId;
  final String rating;
  final DateTime reviewedAt;
  final int previousInterval;
  final int nextInterval;
  final DateTime dueAt;

  const ChallengeReview({
    required this.id,
    required this.challengeId,
    required this.rating,
    required this.reviewedAt,
    required this.previousInterval,
    required this.nextInterval,
    required this.dueAt,
  });
}
