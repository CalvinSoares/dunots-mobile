import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/features/quizzes/data/sqlite_quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persiste seleção, posição e respostas do simulado', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SqliteQuizAttemptRepository(appDatabase);
    final now = DateTime(2026, 9, 30);
    final attempt = QuizAttempt(
      id: 'quiz-sqlite',
      title: 'Revisão de redes',
      questionIds: const ['q-1', 'q-2'],
      currentIndex: 1,
      status: QuizAttemptStatus.inProgress,
      answers: const {'q-1': 2},
      reviewQuestionIds: const ['q-2'],
      reviewNotes: const {'q-2': 'Revisar subnetting'},
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(attempt);
    final saved = (await repository.getAll()).single;

    expect(saved.title, attempt.title);
    expect(saved.questionIds, attempt.questionIds);
    expect(saved.currentIndex, 1);
    expect(saved.answers['q-1'], 2);
    expect(saved.reviewQuestionIds, ['q-2']);
    expect(saved.reviewNotes, {'q-2': 'Revisar subnetting'});
    expect(saved.status, QuizAttemptStatus.inProgress);

    await appDatabase.close();
  });
}
