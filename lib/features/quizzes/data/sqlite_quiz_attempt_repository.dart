import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:dunots_mobile/core/database/app_database.dart';

import '../domain/quiz_attempt.dart';
import 'quiz_attempt_repository.dart';

class SqliteQuizAttemptRepository implements QuizAttemptRepository {
  final Database database;

  SqliteQuizAttemptRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<QuizAttempt>> getAll() async {
    final rows = await database.query(
      'quiz_attempts',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(QuizAttempt attempt) async {
    await database.insert('quiz_attempts', _toRow(attempt));
  }

  @override
  Future<void> update(QuizAttempt attempt) async {
    final changed = await database.update(
      'quiz_attempts',
      _toRow(attempt),
      where: 'id = ?',
      whereArgs: [attempt.id],
    );
    if (changed == 0) {
      throw StateError('Simulado não encontrado: ${attempt.id}');
    }
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('quiz_attempts', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(QuizAttempt attempt) {
    return {
      'id': attempt.id,
      'title': attempt.title,
      'question_ids': jsonEncode(attempt.questionIds),
      'current_index': attempt.currentIndex,
      'status': attempt.status.name,
      'answers': jsonEncode(attempt.answers),
      'review_question_ids': jsonEncode(attempt.reviewQuestionIds),
      'review_notes': jsonEncode(attempt.reviewNotes),
      'created_at': attempt.createdAt.toIso8601String(),
      'updated_at': attempt.updatedAt.toIso8601String(),
    };
  }

  QuizAttempt _fromRow(Map<String, Object?> row) {
    final decodedAnswers = jsonDecode(row['answers']! as String) as Map;
    final decodedReviewQuestionIds =
        jsonDecode((row['review_question_ids'] ?? '[]') as String) as List;
    final decodedReviewNotes =
        jsonDecode((row['review_notes'] ?? '{}') as String) as Map;
    return QuizAttempt(
      id: row['id']! as String,
      title: row['title']! as String,
      questionIds: (jsonDecode(row['question_ids']! as String) as List)
          .cast<String>(),
      currentIndex: row['current_index']! as int,
      status: QuizAttemptStatus.values.byName(row['status']! as String),
      answers: decodedAnswers.map(
        (key, value) => MapEntry(key.toString(), value as int?),
      ),
      reviewQuestionIds: decodedReviewQuestionIds.cast<String>(),
      reviewNotes: decodedReviewNotes.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
