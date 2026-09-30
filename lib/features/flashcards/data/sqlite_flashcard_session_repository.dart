import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/flashcard_session_summary.dart';
import 'flashcard_session_repository.dart';

class SqliteFlashcardSessionRepository implements FlashcardSessionRepository {
  final Database database;

  SqliteFlashcardSessionRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<void> create(FlashcardSessionSummary summary) async {
    await database.insert('flashcard_sessions', {
      'id': summary.id,
      'started_at': summary.startedAt.toIso8601String(),
      'finished_at': summary.finishedAt.toIso8601String(),
      'card_count': summary.cardCount,
      'difficult_count': summary.difficultCount,
      'good_count': summary.goodCount,
      'easy_count': summary.easyCount,
    });
  }

  @override
  Future<List<FlashcardSessionSummary>> getForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await database.query(
      'flashcard_sessions',
      where: 'finished_at >= ? AND finished_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'finished_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<List<FlashcardSessionSummary>> getRecent({int days = 7}) async {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    final end = start.add(Duration(days: days));
    final rows = await database.query(
      'flashcard_sessions',
      where: 'finished_at >= ? AND finished_at < ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'finished_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  FlashcardSessionSummary _fromRow(Map<String, Object?> row) {
    return FlashcardSessionSummary(
      id: row['id']! as String,
      startedAt: DateTime.parse(row['started_at']! as String),
      finishedAt: DateTime.parse(row['finished_at']! as String),
      cardCount: row['card_count']! as int,
      difficultCount: row['difficult_count']! as int,
      goodCount: row['good_count']! as int,
      easyCount: row['easy_count']! as int,
    );
  }
}
