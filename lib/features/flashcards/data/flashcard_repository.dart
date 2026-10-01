import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/srs/srs_scheduler.dart';

import '../flashcard_demo_data.dart';

abstract interface class FlashcardRepository {
  Future<List<Flashcard>> getAll();

  Future<void> create(Flashcard card);

  Future<void> update(Flashcard card);

  Future<void> delete(String cardId);

  Future<void> recordReview({
    required String cardId,
    required String rating,
    required DateTime reviewedAt,
    required DateTime dueAt,
  });
}

class InMemoryFlashcardRepository implements FlashcardRepository {
  final List<Flashcard> _cards;

  InMemoryFlashcardRepository({List<Flashcard>? cards})
    : _cards = List.of(cards ?? demoFlashcards);

  @override
  Future<List<Flashcard>> getAll() async => List.unmodifiable(_cards);

  @override
  Future<void> create(Flashcard card) async {
    _cards.add(card);
  }

  @override
  Future<void> update(Flashcard card) async {
    final index = _cards.indexWhere((item) => item.id == card.id);
    if (index < 0) throw StateError('Flashcard não encontrado.');
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
  }) async {
    final index = _cards.indexWhere((card) => card.id == cardId);
    if (index < 0) {
      throw StateError('Flashcard não encontrado.');
    }
    final card = _cards[index];
    final schedule = SrsScheduler.next(
      rating: rating,
      reviewedAt: reviewedAt,
      interval: card.interval,
      easeFactor: card.easeFactor,
      repetitions: card.repetitions,
    );
    _cards[index] = card.copyWith(
      dueAt: schedule.dueAt,
      lastReviewedAt: reviewedAt,
      reviewCount: card.reviewCount + 1,
      lastRating: rating,
      interval: schedule.interval,
      easeFactor: schedule.easeFactor,
      repetitions: schedule.repetitions,
      updatedAt: reviewedAt,
    );
  }
}
