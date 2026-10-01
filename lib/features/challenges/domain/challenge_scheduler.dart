import '../../../core/srs/srs_scheduler.dart';

class ChallengeSchedule {
  final DateTime dueAt;
  final int interval;
  final double easeFactor;
  final int repetitions;

  const ChallengeSchedule({
    required this.dueAt,
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
  });
}

class ChallengeScheduler {
  const ChallengeScheduler._();

  static ChallengeSchedule next({
    required String rating,
    required DateTime reviewedAt,
    required int interval,
    required double easeFactor,
    required int repetitions,
  }) {
    final schedule = SrsScheduler.next(
      rating: rating,
      reviewedAt: reviewedAt,
      interval: interval,
      easeFactor: easeFactor,
      repetitions: repetitions,
    );
    return ChallengeSchedule(
      dueAt: schedule.dueAt,
      interval: schedule.interval,
      easeFactor: schedule.easeFactor,
      repetitions: schedule.repetitions,
    );
  }
}
