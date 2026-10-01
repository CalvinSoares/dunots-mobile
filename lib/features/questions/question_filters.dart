import 'domain/question.dart';
import 'domain/quiz_exam.dart';

class QuestionFilters {
  const QuestionFilters({
    this.search = '',
    this.contest,
    this.role,
    this.examId,
    this.board,
    this.year,
    this.proofVersion,
  });

  final String search;
  final String? contest;
  final String? role;
  final String? examId;
  final String? board;
  final int? year;
  final String? proofVersion;

  List<Question> apply(
    Iterable<Question> questions, {
    Iterable<QuizExam> exams = const <QuizExam>[],
  }) {
    final normalizedSearch = search.trim().toLowerCase();
    final examsById = {for (final exam in exams) exam.id: exam};
    return questions
        .where((question) {
          final exam = question.examId == null
              ? null
              : examsById[question.examId];
          final matchesSearch =
              normalizedSearch.isEmpty ||
              '${question.number ?? ''} ${question.statement} '
                      '${question.contest} ${question.role} ${question.topic} '
                      '${question.exam} '
                      '${question.alternatives.join(' ')}'
                  .toLowerCase()
                  .contains(normalizedSearch);
          final matchesContest = contest == null || question.contest == contest;
          final matchesRole = role == null || question.role == role;
          final matchesExam = examId == null || question.examId == examId;
          final matchesBoard = board == null || exam?.board == board;
          final matchesYear = year == null || exam?.year == year;
          final matchesVersion =
              proofVersion == null || exam?.proofVersion == proofVersion;
          return matchesSearch &&
              matchesContest &&
              matchesRole &&
              matchesExam &&
              matchesBoard &&
              matchesYear &&
              matchesVersion;
        })
        .toList(growable: false);
  }
}
