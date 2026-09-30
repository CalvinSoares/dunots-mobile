import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';

void main() {
  test('atualiza e remove uma tentativa em memória', () async {
    final repository = InMemoryQuizAttemptRepository();
    final now = DateTime(2026, 9, 30);
    final attempt = QuizAttempt(
      id: 'quiz-1',
      title: 'Redes',
      questionIds: const ['q-1'],
      currentIndex: 0,
      status: QuizAttemptStatus.inProgress,
      answers: const {},
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(attempt);
    await repository.update(
      attempt.copyWith(currentIndex: 1, answers: const {'q-1': 0}),
    );
    expect((await repository.getAll()).single.currentIndex, 1);
    expect((await repository.getAll()).single.answers['q-1'], 0);

    await repository.delete(attempt.id);
    expect(await repository.getAll(), isEmpty);
  });
}
