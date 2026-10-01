import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/sync/sync_contract.dart';
import 'package:dunots_mobile/core/sync/sync_database_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('aplica resoluções diferentes para conflitos diferentes', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SyncDatabaseRepository(database.database);
    for (final id in ['keep-local', 'use-received']) {
      await database.database.insert('flashcards', {
        'id': id,
        'front': 'Local $id',
        'back': 'Verso local',
        'created_at': '2026-09-30T00:00:00.000Z',
        'due_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });
    }
    final package = SyncPackage(
      exportedAt: DateTime.utc(2026, 10, 1),
      source: const SyncIdentity(deviceId: 'desktop', deviceName: 'Desktop'),
      collections: {
        SyncCollections.flashcards: [
          for (final id in ['keep-local', 'use-received'])
            SyncRecord({
              'id': id,
              'question': 'Recebido $id',
              'answer': 'Verso recebido',
              'codeSnippet': '',
              'language': '',
              'tags': <String>[],
              'linkedMaterialIds': <String>[],
              'diagramIds': <String>[],
              'createdAt': '2026-09-30T00:00:00.000Z',
              'updatedAt': '2026-10-01T00:00:00.000Z',
              'nextReviewAt': '2026-10-01T00:00:00.000Z',
              'lastReviewedAt': null,
              'reviewCount': 0,
              'lastRating': null,
              'interval': 0,
              'easeFactor': 2.5,
              'repetitions': 0,
            }),
        ],
      },
    );
    final preview = await repository.preview(package);
    expect(preview.conflicts, hasLength(2));
    final result = await repository.apply(
      preview,
      defaultResolution: SyncConflictResolution.keepLocal,
      resolutions: {
        'flashcards:use-received': SyncConflictResolution.useReceived,
      },
    );

    expect(result.updated, 1);
    expect(result.keptLocal, 1);
    final rows = await database.database.query('flashcards', orderBy: 'id ASC');
    expect(rows[0]['front'], 'Local keep-local');
    expect(rows[1]['front'], 'Recebido use-received');

    await database.close();
  });
}
