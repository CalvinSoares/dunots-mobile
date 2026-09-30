import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_session_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persiste e consulta resumo diário de flashcards', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SqliteFlashcardSessionRepository(appDatabase);
    final startedAt = DateTime(2026, 9, 30, 10);
    final summary = FlashcardSessionSummary(
      id: 'session-sqlite',
      startedAt: startedAt,
      finishedAt: startedAt.add(const Duration(minutes: 5)),
      cardCount: 4,
      difficultCount: 1,
      goodCount: 1,
      easyCount: 2,
    );

    await repository.create(summary);
    final saved = await repository.getForDay(DateTime(2026, 9, 30));

    expect(saved, hasLength(1));
    expect(saved.single.id, summary.id);
    expect(saved.single.answeredCount, 4);
    expect(saved.single.easyCount, 2);
    expect(await repository.getRecent(days: 7), hasLength(1));

    await appDatabase.close();
  });
}
