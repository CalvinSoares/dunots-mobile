class SrsSchedule {
  final DateTime dueAt;
  final int interval;
  final double easeFactor;
  final int repetitions;

  const SrsSchedule({
    required this.dueAt,
    required this.interval,
    required this.easeFactor,
    required this.repetitions,
  });
}

/// Implementa a mesma tabela de revisão usada pelo desktop/web.
class SrsScheduler {
  static const minEaseFactor = 1.3;
  static const defaultEaseFactor = 2.5;

  const SrsScheduler._();

  static SrsSchedule next({
    required String rating,
    required DateTime reviewedAt,
    int interval = 0,
    double easeFactor = defaultEaseFactor,
    int repetitions = 0,
  }) {
    final normalized = _normalizeRating(rating);
    final meta = switch (normalized) {
      'again' => const _RatingMeta(
        multiplier: 0,
        easeDelta: -0.2,
        resetRepetitions: true,
        resetInterval: true,
        firstInterval: 0,
      ),
      'hard' => const _RatingMeta(
        multiplier: 1.2,
        easeDelta: -0.15,
        firstInterval: 1,
      ),
      'medium' => const _RatingMeta(
        multiplier: 2.5,
        easeDelta: 0,
        firstInterval: 1,
      ),
      'easy' => const _RatingMeta(
        multiplier: 3.0,
        easeDelta: 0.15,
        firstInterval: 4,
      ),
      _ => throw ArgumentError.value(rating, 'rating'),
    };

    final nextEase = _clamp(easeFactor + meta.easeDelta, minEaseFactor, 3.0);
    final nextRepetitions = meta.resetRepetitions ? 0 : repetitions + 1;
    var nextInterval = interval;
    if (meta.resetInterval) {
      nextInterval = 0;
    } else if (nextRepetitions <= 1) {
      nextInterval = meta.firstInterval;
    } else {
      nextInterval = (interval * meta.multiplier).round();
    }
    nextInterval = nextInterval < meta.firstInterval
        ? meta.firstInterval
        : nextInterval;

    final dueAt = normalized == 'again'
        ? reviewedAt.add(const Duration(minutes: 10))
        : reviewedAt.add(Duration(days: nextInterval));
    return SrsSchedule(
      dueAt: dueAt,
      interval: nextInterval,
      easeFactor: nextEase,
      repetitions: nextRepetitions,
    );
  }

  static String normalizeRating(String rating) => _normalizeRating(rating);

  static String _normalizeRating(String rating) {
    final normalized = rating.trim().toLowerCase();
    if (normalized == 'again' || normalized.contains('novamente')) {
      return 'again';
    }
    if (normalized == 'hard' || normalized.contains('dif')) return 'hard';
    if (normalized == 'medium' || normalized == 'bom') return 'medium';
    if (normalized == 'easy' ||
        normalized.contains('fác') ||
        normalized.contains('fac')) {
      return 'easy';
    }
    return normalized;
  }

  static double _clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
}

class _RatingMeta {
  final double multiplier;
  final double easeDelta;
  final bool resetRepetitions;
  final bool resetInterval;
  final int firstInterval;

  const _RatingMeta({
    required this.multiplier,
    required this.easeDelta,
    this.resetRepetitions = false,
    this.resetInterval = false,
    required this.firstInterval,
  });
}
