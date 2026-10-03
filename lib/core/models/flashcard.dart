class Flashcard {
  final String id;
  final String front;
  final String back;
  final String code;
  final String language;
  final String? quizQuestionId;
  final List<String> tags;
  final List<String> linkedMaterialIds;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final String? lastRating;
  final int interval;
  final double easeFactor;
  final int repetitions;
  final DateTime updatedAt;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.code = '',
    this.language = '',
    this.quizQuestionId,
    this.tags = const [],
    this.linkedMaterialIds = const [],
    required this.createdAt,
    this.dueAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.lastRating,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? code,
    String? language,
    String? quizQuestionId,
    List<String>? tags,
    List<String>? linkedMaterialIds,
    DateTime? createdAt,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    String? lastRating,
    int? interval,
    double? easeFactor,
    int? repetitions,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      code: code ?? this.code,
      language: language ?? this.language,
      quizQuestionId: quizQuestionId ?? this.quizQuestionId,
      tags: tags ?? this.tags,
      linkedMaterialIds: linkedMaterialIds ?? this.linkedMaterialIds,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastRating: lastRating ?? this.lastRating,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isDueAt(DateTime now) => dueAt == null || !dueAt!.isAfter(now);
}
