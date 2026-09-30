import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:dunots_mobile/core/database/app_database.dart';

import '../domain/question.dart';
import 'question_repository.dart';

class SqliteQuestionRepository implements QuestionRepository {
  final Database database;

  SqliteQuestionRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<Question>> getAll() async {
    final rows = await database.query(
      'questions',
      orderBy: 'question_number ASC, created_at ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(Question question) async {
    await database.insert('questions', _toRow(question));
  }

  @override
  Future<void> createMany(List<Question> questions) async {
    await database.transaction((transaction) async {
      final batch = transaction.batch();
      for (final question in questions) {
        batch.insert('questions', _toRow(question));
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> update(Question question) async {
    final changed = await database.update(
      'questions',
      _toRow(question),
      where: 'id = ?',
      whereArgs: [question.id],
    );
    if (changed == 0) {
      throw StateError('Questão não encontrada: ${question.id}');
    }
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(Question question) {
    return {
      'id': question.id,
      'question_number': question.number,
      'statement': question.statement,
      'alternatives': jsonEncode(question.alternatives),
      'correct_alternative_index': question.correctAlternativeIndex,
      'explanation': question.explanation,
      'contest': question.contest,
      'role': question.role,
      'topic': question.topic,
      'exam': question.exam,
      'exam_id': question.examId,
      'subject': question.subject,
      'notes': question.notes,
      'source_name': question.sourceName,
      'source_page': question.sourcePage,
      'visual_image': question.visualImage,
      'visual_images': jsonEncode(question.visualImages),
      'created_at': question.createdAt.toIso8601String(),
      'updated_at': question.updatedAt.toIso8601String(),
    };
  }

  Question _fromRow(Map<String, Object?> row) {
    final alternatives = (jsonDecode(row['alternatives']! as String) as List)
        .cast<String>();
    return Question(
      id: row['id']! as String,
      number: row['question_number'] as int?,
      statement: row['statement']! as String,
      alternatives: List.unmodifiable(alternatives),
      correctAlternativeIndex: row['correct_alternative_index']! as int,
      explanation: row['explanation']! as String,
      contest: row['contest']! as String,
      role: row['role']! as String,
      topic: row['topic'] as String? ?? '',
      exam: row['exam'] as String? ?? '',
      examId: row['exam_id'] as String?,
      subject: row['subject'] as String? ?? '',
      notes: row['notes'] as String? ?? '',
      sourceName: row['source_name'] as String?,
      sourcePage: row['source_page'] as int?,
      visualImage: row['visual_image'] as String?,
      visualImages: List.unmodifiable(
        ((jsonDecode(row['visual_images'] as String? ?? '[]') as List?) ??
                const <Object?>[])
            .whereType<String>(),
      ),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.parse(row['created_at']! as String),
    );
  }
}
