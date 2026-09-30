class QuizExam {
  final String id;
  final String title;
  final String contestName;
  final String vacancy;
  final String? board;
  final int? year;
  final String? proofVersion;
  final String? sourceName;
  final String? answerKeyName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuizExam({
    required this.id,
    required this.title,
    required this.contestName,
    required this.vacancy,
    this.board,
    this.year,
    this.proofVersion,
    this.sourceName,
    this.answerKeyName,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  QuizExam copyWith({
    String? id,
    String? title,
    String? contestName,
    String? vacancy,
    String? board,
    int? year,
    String? proofVersion,
    String? sourceName,
    String? answerKeyName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuizExam(
      id: id ?? this.id,
      title: title ?? this.title,
      contestName: contestName ?? this.contestName,
      vacancy: vacancy ?? this.vacancy,
      board: board ?? this.board,
      year: year ?? this.year,
      proofVersion: proofVersion ?? this.proofVersion,
      sourceName: sourceName ?? this.sourceName,
      answerKeyName: answerKeyName ?? this.answerKeyName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
