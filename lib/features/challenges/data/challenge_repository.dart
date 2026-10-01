import '../domain/challenge.dart';
import '../domain/challenge_review.dart';
import '../domain/challenge_scheduler.dart';

abstract interface class ChallengeRepository {
  Future<List<Challenge>> getAll();
  Future<void> create(Challenge challenge);
  Future<void> update(Challenge challenge);
  Future<void> delete(String id);
  Future<void> recordReview({
    required String challengeId,
    required String rating,
    required DateTime reviewedAt,
  });
  Future<List<ChallengeReview>> getReviewHistory(String challengeId);
}

class InMemoryChallengeRepository implements ChallengeRepository {
  final List<Challenge> _items;
  final List<ChallengeReview> _reviews;

  InMemoryChallengeRepository({
    List<Challenge>? items,
    List<ChallengeReview>? reviews,
  }) : _items = List.of(items ?? const []),
       _reviews = List.of(reviews ?? const []);

  @override
  Future<List<Challenge>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> create(Challenge challenge) async => _items.add(challenge);

  @override
  Future<void> update(Challenge challenge) async {
    final index = _items.indexWhere((item) => item.id == challenge.id);
    if (index < 0) throw StateError('Desafio não encontrado.');
    _items[index] = challenge;
  }

  @override
  Future<void> delete(String id) async =>
      _items.removeWhere((item) => item.id == id);

  @override
  Future<void> recordReview({
    required String challengeId,
    required String rating,
    required DateTime reviewedAt,
  }) async {
    final index = _items.indexWhere((item) => item.id == challengeId);
    if (index < 0) throw StateError('Desafio não encontrado.');
    final challenge = _items[index];
    final schedule = ChallengeScheduler.next(
      rating: rating,
      reviewedAt: reviewedAt,
      interval: challenge.interval,
      easeFactor: challenge.easeFactor,
      repetitions: challenge.repetitions,
    );
    _items[index] = challenge.copyWith(
      dueAt: schedule.dueAt,
      interval: schedule.interval,
      easeFactor: schedule.easeFactor,
      repetitions: schedule.repetitions,
      solvedAt: reviewedAt,
      updatedAt: reviewedAt,
    );
    _reviews.add(
      ChallengeReview(
        id: 'challenge-review-${reviewedAt.microsecondsSinceEpoch}',
        challengeId: challengeId,
        rating: rating,
        reviewedAt: reviewedAt,
        previousInterval: challenge.interval,
        nextInterval: schedule.interval,
        dueAt: schedule.dueAt,
      ),
    );
  }

  @override
  Future<List<ChallengeReview>> getReviewHistory(String challengeId) async =>
      List.unmodifiable(
        _reviews.where((review) => review.challengeId == challengeId),
      );
}
