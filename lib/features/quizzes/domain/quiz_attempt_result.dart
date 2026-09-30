import '../../questions/domain/question.dart';
import 'quiz_attempt.dart';

class QuizAttemptResult {
  final int total;
  final int correct;
  final int incorrect;
  final int unanswered;

  const QuizAttemptResult({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unanswered,
  });

  double get percentage => total == 0 ? 0 : correct / total * 100;

  factory QuizAttemptResult.fromAttempt(
    QuizAttempt attempt,
    Iterable<Question> questions,
  ) {
    final questionsById = {
      for (final question in questions) question.id: question,
    };
    var correct = 0;
    var incorrect = 0;
    var unanswered = 0;

    for (final questionId in attempt.questionIds) {
      final question = questionsById[questionId];
      final answer = attempt.answers[questionId];
      if (question == null || answer == null) {
        unanswered++;
      } else if (answer == question.correctAlternativeIndex) {
        correct++;
      } else {
        incorrect++;
      }
    }

    return QuizAttemptResult(
      total: attempt.questionIds.length,
      correct: correct,
      incorrect: incorrect,
      unanswered: unanswered,
    );
  }

  static Map<String, QuizAttemptResult> byTopic(
    QuizAttempt attempt,
    Iterable<Question> questions,
  ) {
    final questionsById = {
      for (final question in questions) question.id: question,
    };
    final grouped = <String, List<Question>>{};
    for (final questionId in attempt.questionIds) {
      final question = questionsById[questionId];
      if (question == null) {
        continue;
      }
      final topic = question.topic.trim().isEmpty
          ? 'Sem tópico'
          : question.topic;
      grouped.putIfAbsent(topic, () => []).add(question);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: QuizAttemptResult.fromAttempt(
          attempt.copyWith(
            questionIds: entry.value.map((item) => item.id).toList(),
          ),
          entry.value,
        ),
    };
  }

  static Map<String, QuizAttemptResult> byExam(
    QuizAttempt attempt,
    Iterable<Question> questions,
  ) {
    final questionsById = {
      for (final question in questions) question.id: question,
    };
    final grouped = <String, List<Question>>{};
    for (final questionId in attempt.questionIds) {
      final question = questionsById[questionId];
      if (question == null) {
        continue;
      }
      final contest = question.contest.trim();
      final exam = question.exam.trim();
      final label = [
        contest,
        exam,
      ].where((value) => value.isNotEmpty).join(' · ');
      grouped
          .putIfAbsent(label.isEmpty ? 'Sem concurso/prova' : label, () => [])
          .add(question);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: QuizAttemptResult.fromAttempt(
          attempt.copyWith(
            questionIds: entry.value.map((item) => item.id).toList(),
          ),
          entry.value,
        ),
    };
  }
}
