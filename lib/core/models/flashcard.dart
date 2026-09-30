class Flashcard {
  final String id;
  final String front;
  final String back;
  final String code;
  final List<String> tags;
  final List<String> linkedMaterialIds;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final String? lastRating;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.code = '',
    this.tags = const [],
    this.linkedMaterialIds = const [],
    required this.createdAt,
    this.dueAt,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.lastRating,
  });

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? code,
    List<String>? tags,
    List<String>? linkedMaterialIds,
    DateTime? createdAt,
    DateTime? dueAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    String? lastRating,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      code: code ?? this.code,
      tags: tags ?? this.tags,
      linkedMaterialIds: linkedMaterialIds ?? this.linkedMaterialIds,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      lastRating: lastRating ?? this.lastRating,
    );
  }

  bool isDueAt(DateTime now) => dueAt == null || !dueAt!.isAfter(now);
}
