import '../../core/srs/srs_scheduler.dart';

class FlashcardScheduler {
  const FlashcardScheduler._();

  static DateTime nextReviewAt({
    required String rating,
    required DateTime reviewedAt,
    int interval = 0,
    double easeFactor = SrsScheduler.defaultEaseFactor,
    int repetitions = 0,
  }) {
    return SrsScheduler.next(
      rating: rating,
      reviewedAt: reviewedAt,
      interval: interval,
      easeFactor: easeFactor,
      repetitions: repetitions,
    ).dueAt;
  }
}
