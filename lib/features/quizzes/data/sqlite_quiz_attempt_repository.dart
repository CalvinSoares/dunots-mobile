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
    final decodedAnswers = _decodeMap(row['answers']);
    final decodedReviewQuestionIds = _decodeList(row['review_question_ids']);
    final decodedReviewNotes = _decodeMap(row['review_notes']);
    return QuizAttempt(
      id: row['id']! as String,
      title: row['title']! as String,
      questionIds: _decodeList(row['question_ids'])
          .map((value) => value.toString())
          .toList(growable: false),
      currentIndex: row['current_index']! as int,
      status: _status(row['status']),
      answers: decodedAnswers.map(
        (key, value) => MapEntry(key, _answerIndex(value)),
      ),
      reviewQuestionIds: decodedReviewQuestionIds
          .map((value) => value.toString())
          .toList(growable: false),
      reviewNotes: decodedReviewNotes.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      createdAt: _date(row['created_at'], fallback: row['updated_at']),
      updatedAt: _date(row['updated_at'], fallback: row['created_at']),
    );
  }

  Map<String, Object?> _decodeMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    if (value is! String || value.isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? Map<String, Object?>.from(decoded) : const {};
    } catch (_) {
      return const {};
    }
  }

  List<Object?> _decodeList(Object? value) {
    if (value is List) return List<Object?>.from(value);
    if (value is! String || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? List<Object?>.from(decoded) : const [];
    } catch (_) {
      return const [];
    }
  }

  QuizAttemptStatus _status(Object? value) {
    final normalized = value?.toString().toLowerCase().replaceAll('-', '_');
    return normalized == 'finished' || normalized == 'completed'
        ? QuizAttemptStatus.finished
        : QuizAttemptStatus.inProgress;
  }

  int? _answerIndex(Object? value) {
    if (value is num) return value.toInt();
    final text = value?.toString().trim() ?? '';
    final numeric = int.tryParse(text);
    if (numeric != null) return numeric;
    if (RegExp(r'^[A-Ea-e]$').hasMatch(text)) {
      return text.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
    }
    return null;
  }

  DateTime _date(Object? value, {Object? fallback}) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    final fallbackParsed = DateTime.tryParse(fallback?.toString() ?? '');
    return fallbackParsed ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
