import '../../../core/models/flashcard.dart';
import '../../challenges/domain/challenge.dart';

class StudyPhase {
  final String id;
  final String title;
  final String description;
  final List<String> flashcardIds;
  final List<String> challengeIds;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyPhase({
    required this.id,
    required this.title,
    this.description = '',
    this.flashcardIds = const [],
    this.challengeIds = const [],
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalItems => flashcardIds.length + challengeIds.length;

  int completedItems({
    required Iterable<Flashcard> flashcards,
    required Iterable<Challenge> challenges,
  }) {
    final cardIds = flashcards
        .where(
          (card) =>
              flashcardIds.contains(card.id) && card.lastReviewedAt != null,
        )
        .length;
    final challengeIdsSet = challengeIds.toSet();
    final solvedChallenges = challenges
        .where(
          (challenge) =>
              challengeIdsSet.contains(challenge.id) &&
              challenge.solvedAt != null,
        )
        .length;
    return cardIds + solvedChallenges;
  }

  double progress({
    required Iterable<Flashcard> flashcards,
    required Iterable<Challenge> challenges,
  }) {
    if (totalItems == 0) return 0;
    return completedItems(flashcards: flashcards, challenges: challenges) /
        totalItems;
  }

  StudyPhase copyWith({
    String? title,
    String? description,
    List<String>? flashcardIds,
    List<String>? challengeIds,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return StudyPhase(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      flashcardIds: flashcardIds ?? this.flashcardIds,
      challengeIds: challengeIds ?? this.challengeIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
