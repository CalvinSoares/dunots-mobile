class Question {
  final String id;
  final int? number;
  final String statement;
  final List<String> alternatives;
  final int correctAlternativeIndex;
  final String explanation;
  final String contest;
  final String role;
  final String topic;
  final String exam;
  final String? examId;
  final String subject;
  final String notes;
  final String? sourceName;
  final int? sourcePage;
  final String? visualImage;
  final List<String> visualImages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Question({
    required this.id,
    required this.statement,
    required this.alternatives,
    required this.correctAlternativeIndex,
    required this.explanation,
    required this.contest,
    required this.role,
    this.topic = '',
    this.exam = '',
    this.examId,
    this.subject = '',
    this.notes = '',
    this.sourceName,
    this.sourcePage,
    this.visualImage,
    this.visualImages = const [],
    required this.createdAt,
    DateTime? updatedAt,
    this.number,
  }) : updatedAt = updatedAt ?? createdAt;

  Question copyWith({
    String? id,
    int? number,
    String? statement,
    List<String>? alternatives,
    int? correctAlternativeIndex,
    String? explanation,
    String? contest,
    String? role,
    String? topic,
    String? exam,
    String? examId,
    String? subject,
    String? notes,
    String? sourceName,
    int? sourcePage,
    String? visualImage,
    List<String>? visualImages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Question(
      id: id ?? this.id,
      number: number ?? this.number,
      statement: statement ?? this.statement,
      alternatives: alternatives ?? this.alternatives,
      correctAlternativeIndex:
          correctAlternativeIndex ?? this.correctAlternativeIndex,
      explanation: explanation ?? this.explanation,
      contest: contest ?? this.contest,
      role: role ?? this.role,
      topic: topic ?? this.topic,
      exam: exam ?? this.exam,
      examId: examId ?? this.examId,
      subject: subject ?? this.subject,
      notes: notes ?? this.notes,
      sourceName: sourceName ?? this.sourceName,
      sourcePage: sourcePage ?? this.sourcePage,
      visualImage: visualImage ?? this.visualImage,
      visualImages: visualImages ?? this.visualImages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
