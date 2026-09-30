enum QuizAttemptStatus { inProgress, finished }

class QuizAttempt {
  final String id;
  final String title;
  final List<String> questionIds;
  final int currentIndex;
  final QuizAttemptStatus status;
  final Map<String, int?> answers;
  final List<String> reviewQuestionIds;
  final Map<String, String> reviewNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuizAttempt({
    required this.id,
    required this.title,
    required this.questionIds,
    required this.currentIndex,
    required this.status,
    required this.answers,
    this.reviewQuestionIds = const [],
    this.reviewNotes = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  QuizAttempt copyWith({
    String? id,
    String? title,
    List<String>? questionIds,
    int? currentIndex,
    QuizAttemptStatus? status,
    Map<String, int?>? answers,
    List<String>? reviewQuestionIds,
    Map<String, String>? reviewNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizAttempt(
      id: id ?? this.id,
      title: title ?? this.title,
      questionIds: questionIds ?? this.questionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      answers: answers ?? this.answers,
      reviewQuestionIds: reviewQuestionIds ?? this.reviewQuestionIds,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
