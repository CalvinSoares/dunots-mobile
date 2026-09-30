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

  test(
    'exporta pacote .dunots e preserva a identidade do dispositivo',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final repository = SyncDatabaseRepository(database.database);

      await database.database.insert('flashcards', {
        'id': 'card-1',
        'front': 'O que é uma VLAN?',
        'back': 'Uma rede lógica.',
        'created_at': '2026-09-30T00:00:00.000Z',
        'due_at': '2026-09-30T00:00:00.000Z',
      });

      final first = await repository.exportPackage();
      final decoded = repository.decodePackage(await repository.exportBytes());

      expect(first.source.deviceId, decoded.source.deviceId);
      expect(decoded.recordsFor(SyncCollections.flashcards), hasLength(1));
      expect(
        decoded.recordsFor(SyncCollections.flashcards).single.id,
        'card-1',
      );

      await database.close();
    },
  );

  test('gera tombstone quando um registro local é excluído', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SyncDatabaseRepository(database.database);

    await database.database.insert('flashcards', {
      'id': 'card-deleted',
      'front': 'Frente',
      'back': 'Verso',
      'created_at': '2026-09-30T00:00:00.000Z',
      'due_at': '2026-09-30T00:00:00.000Z',
    });
    await database.database.delete(
      'flashcards',
      where: 'id = ?',
      whereArgs: ['card-deleted'],
    );

    final package = await repository.exportPackage();
    final tombstones = package.recordsFor(SyncCollections.syncTombstones);
    expect(tombstones, hasLength(1));
    expect(tombstones.single.values['recordId'], 'card-deleted');

    await database.close();
  });

  test(
    'mostra conflito no preview e permite usar o registro recebido',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final repository = SyncDatabaseRepository(database.database);
      await database.database.insert('flashcards', {
        'id': 'card-conflict',
        'front': 'Local',
        'back': 'Verso local',
        'created_at': '2026-09-30T00:00:00.000Z',
        'due_at': '2026-09-30T00:00:00.000Z',
      });

      final package = SyncPackage(
        exportedAt: DateTime.utc(2026, 9, 30, 12),
        source: const SyncIdentity(
          deviceId: 'notebook-2',
          deviceName: 'Notebook',
        ),
        collections: {
          SyncCollections.flashcards: [
            SyncRecord({
              'id': 'card-conflict',
              'front': 'Recebido',
              'back': 'Verso recebido',
              'code': '',
              'tags': <String>[],
              'linkedMaterialIds': <String>[],
              'createdAt': '2026-09-30T00:00:00.000Z',
              'dueAt': '2026-09-30T00:00:00.000Z',
              'lastReviewedAt': null,
              'reviewCount': 0,
              'lastRating': null,
              'updatedAt': '2026-10-01T00:00:00.000Z',
            }),
          ],
        },
      );

      final preview = await repository.preview(package);
      expect(preview.conflicts, hasLength(1));
      final result = await repository.apply(
        preview,
        defaultResolution: SyncConflictResolution.useReceived,
      );

      expect(result.updated, 1);
      final row = (await database.database.query('flashcards')).single;
      expect(row['front'], 'Recebido');

      await database.close();
    },
  );
}
