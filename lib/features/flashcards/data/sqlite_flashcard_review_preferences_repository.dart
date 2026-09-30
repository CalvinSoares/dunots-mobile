import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/flashcard_review_preferences.dart';
import 'flashcard_review_preferences_repository.dart';

class SqliteFlashcardReviewPreferencesRepository
    implements FlashcardReviewPreferencesRepository {
  final Database database;

  SqliteFlashcardReviewPreferencesRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<FlashcardReviewPreferences> get() async {
    final rows = await database.query(
      'flashcard_review_preferences',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (rows.isEmpty) {
      const defaults = FlashcardReviewPreferences();
      await save(defaults);
      return defaults;
    }
    final row = rows.single;
    return FlashcardReviewPreferences(
      dailyLimit: row['daily_limit']! as int,
      dailyGoal: row['daily_goal']! as int,
      weeklyGoal: row['weekly_goal']! as int,
      sort: row['sort']! as String,
      preferRecommended: (row['prefer_recommended']! as int) == 1,
      reminderEnabled: (row['reminder_enabled']! as int) == 1,
      reminderHour: row['reminder_hour']! as int,
      reminderMinute: row['reminder_minute']! as int,
    );
  }

  @override
  Future<void> save(FlashcardReviewPreferences preferences) async {
    await database.insert('flashcard_review_preferences', {
      'id': 1,
      'daily_limit': preferences.dailyLimit,
      'daily_goal': preferences.dailyGoal,
      'weekly_goal': preferences.weeklyGoal,
      'sort': preferences.sort,
      'prefer_recommended': preferences.preferRecommended ? 1 : 0,
      'reminder_enabled': preferences.reminderEnabled ? 1 : 0,
      'reminder_hour': preferences.reminderHour,
      'reminder_minute': preferences.reminderMinute,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
