class FlashcardScheduler {
  const FlashcardScheduler._();

  static DateTime nextReviewAt({
    required String rating,
    required DateTime reviewedAt,
  }) {
    final delay = switch (rating) {
      'difícil' => const Duration(minutes: 10),
      'bom' => const Duration(days: 1),
      'fácil' => const Duration(days: 3),
      _ => throw ArgumentError.value(rating, 'rating'),
    };
    return reviewedAt.add(delay);
  }
}
