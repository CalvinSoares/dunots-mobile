import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/models/flashcard_review_preferences.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_review_preferences_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('mantém preferências em memória', () async {
    final repository = InMemoryFlashcardReviewPreferencesRepository();
    const preferences = FlashcardReviewPreferences(
      dailyLimit: 10,
      sort: 'reviews',
      preferRecommended: true,
    );

    await repository.save(preferences);

    expect(await repository.get(), same(preferences));
  });

  test('persiste preferências no SQLite', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SqliteFlashcardReviewPreferencesRepository(appDatabase);
    const preferences = FlashcardReviewPreferences(
      dailyLimit: 50,
      dailyGoal: 100,
      sort: 'alphabetical',
      preferRecommended: true,
      reminderEnabled: false,
      reminderHour: 21,
      reminderMinute: 30,
    );

    await repository.save(preferences);
    final saved = await repository.get();

    expect(saved.dailyLimit, 50);
    expect(saved.dailyGoal, 100);
    expect(saved.sort, 'alphabetical');
    expect(saved.preferRecommended, isTrue);
    expect(saved.reminderEnabled, isFalse);
    expect(saved.reminderHour, 21);
    expect(saved.reminderMinute, 30);

    await appDatabase.close();
  });
}
