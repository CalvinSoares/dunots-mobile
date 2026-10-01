import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persiste e recupera flashcards do SQLite', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SqliteFlashcardRepository(appDatabase);
    final card = Flashcard(
      id: 'card-sqlite',
      front: 'O que é um pacote?',
      back: 'Unidade de dados da camada de rede.',
      createdAt: DateTime(2026, 9, 30),
      code: 'SELECT * FROM pacotes;',
      tags: const ['redes', 'SQL'],
      linkedMaterialIds: const ['question-1', 'document-1'],
    );

    await repository.create(card);
    final saved = (await repository.getAll()).single;

    expect(saved.id, card.id);
    expect(saved.front, card.front);
    expect(saved.createdAt, card.createdAt);
    expect(saved.code, card.code);
    expect(saved.tags, card.tags);
    expect(saved.linkedMaterialIds, card.linkedMaterialIds);

    final reviewedAt = DateTime(2026, 9, 30, 10);
    final dueAt = DateTime(2026, 10, 4, 10);
    await repository.recordReview(
      cardId: card.id,
      rating: 'fácil',
      reviewedAt: reviewedAt,
      dueAt: dueAt,
    );

    final reviewed = (await repository.getAll()).single;
    expect(reviewed.reviewCount, 1);
    expect(reviewed.lastRating, 'fácil');
    expect(reviewed.lastReviewedAt, reviewedAt);
    expect(reviewed.dueAt, dueAt);
    expect(reviewed.interval, 4);
    expect(reviewed.repetitions, 1);
    expect(reviewed.easeFactor, 2.65);

    final updated = reviewed.copyWith(
      front: 'O que é um segmento?',
      tags: const ['TCP'],
    );
    await repository.update(updated);
    final edited = (await repository.getAll()).single;
    expect(edited.front, 'O que é um segmento?');
    expect(edited.tags, ['TCP']);

    await repository.delete(card.id);
    expect(await repository.getAll(), isEmpty);

    await appDatabase.close();
  });
}
