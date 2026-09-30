class FlashcardSessionSummary {
  final String id;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int cardCount;
  final int difficultCount;
  final int goodCount;
  final int easyCount;

  const FlashcardSessionSummary({
    required this.id,
    required this.startedAt,
    required this.finishedAt,
    required this.cardCount,
    required this.difficultCount,
    required this.goodCount,
    required this.easyCount,
  });

  int get answeredCount => difficultCount + goodCount + easyCount;
}
