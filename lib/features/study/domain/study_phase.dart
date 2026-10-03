import '../../../core/models/flashcard.dart';

class StudyPhase {
  final String id;
  final String title;
  final String description;
  final List<String> flashcardIds;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyPhase({
    required this.id,
    required this.title,
    this.description = '',
    this.flashcardIds = const [],
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalItems => flashcardIds.length;

  int completedItems({required Iterable<Flashcard> flashcards}) {
    return flashcards
        .where(
          (card) =>
              flashcardIds.contains(card.id) && card.lastReviewedAt != null,
        )
        .length;
  }

  double progress({required Iterable<Flashcard> flashcards}) {
    if (totalItems == 0) return 0;
    return completedItems(flashcards: flashcards) / totalItems;
  }

  StudyPhase copyWith({
    String? title,
    String? description,
    List<String>? flashcardIds,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return StudyPhase(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
