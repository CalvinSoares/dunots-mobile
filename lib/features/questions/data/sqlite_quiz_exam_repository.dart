import 'package:sqflite/sqflite.dart';

import 'package:dunots_mobile/core/database/app_database.dart';

import '../domain/quiz_exam.dart';
import 'quiz_exam_repository.dart';

class SqliteQuizExamRepository implements QuizExamRepository {
  final Database database;

  SqliteQuizExamRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<QuizExam>> getAll() async {
    final rows = await database.query(
      'quiz_exams',
      orderBy: 'year DESC, title COLLATE NOCASE ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(QuizExam exam) async {
    await database.insert('quiz_exams', _toRow(exam));
  }

  @override
  Future<void> update(QuizExam exam) async {
    final changed = await database.update(
      'quiz_exams',
      _toRow(exam),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
    if (changed == 0) {
      throw StateError('Prova não encontrada: ${exam.id}');
    }
  }

  @override
  Future<void> delete(String id) async {
    await database.transaction((transaction) async {
      await transaction.update(
        'questions',
        {'exam_id': null},
        where: 'exam_id = ?',
        whereArgs: [id],
      );
      await transaction.delete('quiz_exams', where: 'id = ?', whereArgs: [id]);
    });
  }

  Map<String, Object?> _toRow(QuizExam exam) {
    return {
      'id': exam.id,
      'title': exam.title,
      'contest_name': exam.contestName,
      'vacancy': exam.vacancy,
      'board': exam.board,
      'year': exam.year,
      'proof_version': exam.proofVersion,
      'source_name': exam.sourceName,
      'answer_key_name': exam.answerKeyName,
      'created_at': exam.createdAt.toIso8601String(),
      'updated_at': exam.updatedAt.toIso8601String(),
    };
  }

  QuizExam _fromRow(Map<String, Object?> row) {
    final createdAt = DateTime.parse(row['created_at']! as String);
    return QuizExam(
      id: row['id']! as String,
      title: row['title']! as String,
      contestName: row['contest_name']! as String,
      vacancy: row['vacancy']! as String,
      board: row['board'] as String?,
      year: row['year'] as int?,
      proofVersion: row['proof_version'] as String?,
      sourceName: row['source_name'] as String?,
      answerKeyName: row['answer_key_name'] as String?,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ?? createdAt,
    );
  }
}
