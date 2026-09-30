import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/models/flashcard.dart';

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
    final normalizedRating = rating.toLowerCase();
    final isAgain =
        normalizedRating.contains('dif') || normalizedRating.contains('again');
    final isEasy =
        normalizedRating.contains('fác') ||
        normalizedRating.contains('fac') ||
        normalizedRating.contains('easy');
    final nextEase = isAgain
        ? (currentEase - 0.2).clamp(1.3, 3.0).toDouble()
        : isEasy
        ? (currentEase + 0.15).clamp(1.3, 3.0).toDouble()
        : currentEase;
    final nextInterval = isAgain
        ? 0
        : currentInterval == 0
        ? (isEasy ? 2 : 1)
        : (currentInterval * nextEase * (isEasy ? 1.3 : 1.0)).round().clamp(
            1,
            3650,
          );
    final nextRepetitions = isAgain ? 0 : currentRepetitions + 1;
    final updated = await database.rawUpdate(
      'UPDATE flashcards SET due_at = ?, last_reviewed_at = ?, '
      'review_count = review_count + 1, last_rating = ?, interval = ?, '
      'ease_factor = ?, repetitions = ?, updated_at = ? WHERE id = ?',
      [
        dueAt.toIso8601String(),
        reviewedAt.toIso8601String(),
        rating,
        nextInterval,
        nextEase,
        nextRepetitions,
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
