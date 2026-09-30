import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/features/questions/data/sqlite_question_repository.dart';
import 'package:dunots_mobile/features/questions/data/sqlite_quiz_exam_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/questions/domain/quiz_exam.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persiste prova/vaga e transforma questões vinculadas em avulsas ao excluir', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final examRepository = SqliteQuizExamRepository(appDatabase);
    final questionRepository = SqliteQuestionRepository(appDatabase);
    final exam = QuizExam(
      id: 'exam-sqlite',
      title: 'DATAPREV 2026',
      contestName: 'DATAPREV',
      vacancy: 'Desenvolvimento de Software',
      board: 'FGV',
      year: 2026,
      proofVersion: 'Versão 1',
      sourceName: 'edital.pdf',
      answerKeyName: 'gabarito.pdf',
      createdAt: DateTime(2026, 9, 30),
    );
    final question = Question(
      id: 'question-linked',
      statement: 'Enunciado',
      alternatives: const ['A', 'B'],
      correctAlternativeIndex: 0,
      explanation: '',
      contest: exam.contestName,
      role: exam.vacancy,
      exam: exam.title,
      examId: exam.id,
      createdAt: DateTime(2026, 9, 30),
    );

    await examRepository.create(exam);
    await questionRepository.create(question);
    expect((await examRepository.getAll()).single.board, 'FGV');

    await examRepository.delete(exam.id);
    expect((await examRepository.getAll()), isEmpty);
    expect((await questionRepository.getAll()).single.examId, isNull);

    await appDatabase.close();
  });
}
