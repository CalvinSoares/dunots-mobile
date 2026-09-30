import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt_result.dart';

void main() {
  test('calcula acertos, erros, não respondidas e percentual', () {
    final now = DateTime(2026, 9, 30);
    final attempt = QuizAttempt(
      id: 'quiz-result',
      title: 'Resultado',
      questionIds: const ['q-1', 'q-2', 'q-3'],
      currentIndex: 2,
      status: QuizAttemptStatus.finished,
      answers: const {'q-1': 0, 'q-2': 1},
      createdAt: now,
      updatedAt: now,
    );
    final questions = [
      Question(
        id: 'q-1',
        statement: '1',
        alternatives: const ['A', 'B'],
        correctAlternativeIndex: 0,
        explanation: '',
        contest: '',
        role: '',
        topic: 'Redes',
        exam: 'Prova 6',
        createdAt: now,
      ),
      Question(
        id: 'q-2',
        statement: '2',
        alternatives: const ['A', 'B'],
        correctAlternativeIndex: 0,
        explanation: '',
        contest: '',
        role: '',
        topic: 'Redes',
        exam: 'Prova 6',
        createdAt: now,
      ),
      Question(
        id: 'q-3',
        statement: '3',
        alternatives: const ['A', 'B'],
        correctAlternativeIndex: 0,
        explanation: '',
        contest: '',
        role: '',
        topic: 'Segurança',
        exam: 'Prova 7',
        createdAt: now,
      ),
    ];

    final result = QuizAttemptResult.fromAttempt(attempt, questions);

    expect(result.total, 3);
    expect(result.correct, 1);
    expect(result.incorrect, 1);
    expect(result.unanswered, 1);
    expect(result.percentage, closeTo(33.33, 0.01));
    expect(QuizAttemptResult.byTopic(attempt, questions)['Redes']?.correct, 1);
    expect(
      QuizAttemptResult.byTopic(attempt, questions)['Segurança']?.unanswered,
      1,
    );
    expect(
      QuizAttemptResult.byExam(attempt, questions)['Prova 6']?.incorrect,
      1,
    );
  });
}
