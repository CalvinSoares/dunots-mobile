import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/core/srs/srs_scheduler.dart';

import 'flashcard_repository.dart';

class SqliteFlashcardRepository implements FlashcardRepository {
  final Database database;

  SqliteFlashcardRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<Flashcard>> getAll() async {
    final rows = await database.query('flashcards', orderBy: 'created_at ASC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(Flashcard card) async {
    await database.insert('flashcards', _toRow(card));
  }

  @override
  Future<void> update(Flashcard card) async {
    final updated = await database.update(
      'flashcards',
      _toRow(card)..remove('id'),
      where: 'id = ?',
      whereArgs: [card.id],
    );
    if (updated == 0) throw StateError('Flashcard não encontrado.');
  }

  @override
  Future<void> delete(String cardId) async {
    await database.delete('flashcards', where: 'id = ?', whereArgs: [cardId]);
  }

  @override
  Future<void> recordReview({
    required String cardId,
    required String rating,
    required DateTime reviewedAt,
    required DateTime dueAt,
  }) async {
    final rows = await database.query(
      'flashcards',
      columns: ['interval', 'ease_factor', 'repetitions'],
      where: 'id = ?',
      whereArgs: [cardId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Flashcard não encontrado.');

    final currentInterval = rows.first['interval'] as int? ?? 0;
    final currentEase = (rows.first['ease_factor'] as num?)?.toDouble() ?? 2.5;
    final currentRepetitions = rows.first['repetitions'] as int? ?? 0;
    final schedule = SrsScheduler.next(
      rating: rating,
      reviewedAt: reviewedAt,
      interval: currentInterval,
      easeFactor: currentEase,
      repetitions: currentRepetitions,
    );
    final updated = await database.rawUpdate(
      'UPDATE flashcards SET due_at = ?, last_reviewed_at = ?, '
      'review_count = review_count + 1, last_rating = ?, interval = ?, '
      'ease_factor = ?, repetitions = ?, updated_at = ? WHERE id = ?',
      [
        schedule.dueAt.toIso8601String(),
        reviewedAt.toIso8601String(),
        rating,
        schedule.interval,
        schedule.easeFactor,
        schedule.repetitions,
        reviewedAt.toIso8601String(),
        cardId,
      ],
    );
    if (updated == 0) {
      throw StateError('Flashcard não encontrado.');
    }
  }

  Map<String, Object?> _toRow(Flashcard card) {
    return {
      'id': card.id,
      'front': card.front,
      'back': card.back,
      'code': card.code,
      'language': card.language,
      'quiz_question_id': card.quizQuestionId,
      'tags': jsonEncode(card.tags),
      'linked_material_ids': jsonEncode(card.linkedMaterialIds),
      'diagram_ids': jsonEncode(card.diagramIds),
      'created_at': card.createdAt.toIso8601String(),
      'due_at':
          card.dueAt?.toIso8601String() ?? card.createdAt.toIso8601String(),
      'last_reviewed_at': card.lastReviewedAt?.toIso8601String(),
      'review_count': card.reviewCount,
      'last_rating': card.lastRating,
      'interval': card.interval,
      'ease_factor': card.easeFactor,
      'repetitions': card.repetitions,
      'updated_at': card.updatedAt.toIso8601String(),
    };
  }

  Flashcard _fromRow(Map<String, Object?> row) {
    return Flashcard(
      id: row['id']! as String,
      front: row['front']! as String,
      back: row['back']! as String,
      code: row['code'] as String? ?? '',
      language: row['language'] as String? ?? '',
      quizQuestionId: row['quiz_question_id'] as String?,
      tags: _parseTags(row['tags']),
      linkedMaterialIds: _parseTags(row['linked_material_ids']),
      diagramIds: _parseTags(row['diagram_ids']),
      createdAt: DateTime.parse(row['created_at']! as String),
      dueAt: _parseDate(row['due_at']),
      lastReviewedAt: _parseDate(row['last_reviewed_at']),
      reviewCount: row['review_count'] as int? ?? 0,
      lastRating: row['last_rating'] as String?,
      interval: row['interval'] as int? ?? 0,
      easeFactor: (row['ease_factor'] as num?)?.toDouble() ?? 2.5,
      repetitions: row['repetitions'] as int? ?? 0,
      updatedAt:
          _parseDate(row['updated_at']) ??
          DateTime.parse(row['created_at']! as String),
    );
  }

  DateTime? _parseDate(Object? value) {
    final text = value as String?;
    if (text == null || text.isEmpty) return null;
    return DateTime.parse(text);
  }

  List<String> _parseTags(Object? value) {
    final text = value as String?;
    if (text == null || text.isEmpty) return const [];
    final decoded = jsonDecode(text);
    if (decoded is! List) return const [];
    return decoded.map((tag) => tag.toString()).toList(growable: false);
  }
}
