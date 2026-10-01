import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
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
    'importa fixture realista exportada pelo desktop sem perder campos',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final repository = SyncDatabaseRepository(database.database);
      final bytes = await File('test/fixtures/desktop_sync_v1.dunots.json')
          .readAsBytes();

      final package = repository.decodePackage(Uint8List.fromList(bytes));
      final preview = await repository.preview(package);
      final result = await repository.apply(
        preview,
        defaultResolution: SyncConflictResolution.useReceived,
      );

      expect(result.added, 7);
      expect(result.backupId, isNotNull);
      expect(
        (await database.database.query('flashcards')).single['front'],
        'O que é uma VLAN?',
      );
      final card = (await database.database.query('flashcards')).single;
      expect(card['language'], 'cisco');
      expect(card['quiz_question_id'], 'question-1');
      final challenges = await database.database.query('challenges');
      expect(challenges, hasLength(2));
      expect(
        challenges.map((row) => row['problem_id']),
        everyElement('two-sum'),
      );
      expect(
        challenges.map((row) => row['variant_name']),
        containsAll(['Hash Map', 'Ordenação']),
      );
      expect(challenges.first['url'], 'https://leetcode.com/problems/two-sum/');
      expect(challenges.first['strategy'], contains('mapa'));
      expect(challenges.first['time_complexity'], 'O(n)');
      expect(challenges.first['space_complexity'], 'O(n)');
      expect(challenges.first['tradeoffs'], contains('memória'));
      expect(challenges.first['diagram_ids'], '["diagram-1"]');
      expect(challenges.first['solution'], contains('twoSum'));
      expect(challenges.first['notes'], contains('colisões'));
      expect(challenges.first['solved_at'], isNotNull);
      expect(
        (await database.database.query('study_phases')).single['title'],
        'Redes fundamentais',
      );
      expect(
        (await database.database.query('diagrams')).single['phase_ids'],
        '["phase-1"]',
      );
      expect(
        (await database.database.query('diagrams')).single['nodes'],
        contains('node-a'),
      );
      final question = (await database.database.query('questions')).single;
      expect(question['question_number'], 1);
      expect(question['statement'], 'Qual alternativa está correta?');
      expect(question['alternatives'], '["Primeira","Segunda"]');
      expect(question['correct_alternative_index'], 1);
      expect(question['explanation'], contains('segunda'));
      expect(question['notes'], contains('capítulo'));
      expect(question['exam'], 'Prova 6');
      expect(question['subject'], 'Redes');
      expect(question['topic'], 'VLAN');
      expect(question['source_name'], 'prova.pdf');
      expect(question['source_page'], 1);
      expect(question['visual_images'], '["diagram-question.png"]');

      await database.close();
    },
  );

  test(
    'exporta pacote mobile com nomes e campos aceitos pelo desktop',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final repository = SyncDatabaseRepository(database.database);
      await database.database.insert('flashcards', {
        'id': 'mobile-card-1',
        'front': 'Pergunta',
        'back': 'Resposta',
        'code': 'SELECT 1',
        'language': 'sql',
        'quiz_question_id': 'question-1',
        'tags': jsonEncode(['sql']),
        'diagram_ids': jsonEncode(['diagram-1']),
        'created_at': '2026-09-30T00:00:00.000Z',
        'due_at': '2026-10-01T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });
      await database.database.insert('study_phases', {
        'id': 'mobile-phase-1',
        'title': 'Fase mobile',
        'description': 'Compatibilidade',
        'flashcard_ids': jsonEncode(['mobile-card-1']),
        'problem_ids': jsonEncode(['challenge-1']),
        'sort_order': 3,
        'created_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });

      final package = await repository.exportPackage();
      final card = package.recordsFor(SyncCollections.flashcards).single;
      final phase = package.recordsFor(SyncCollections.studyPhases).single;

      expect(card.values['question'], 'Pergunta');
      expect(card.values['answer'], 'Resposta');
      expect(card.values['codeSnippet'], 'SELECT 1');
      expect(card.values['language'], 'sql');
      expect(card.values['quizQuestionId'], 'question-1');
      expect(card.values['nextReviewAt'], '2026-10-01T00:00:00.000Z');
      expect(phase.values['flashcardIds'], ['mobile-card-1']);
      expect(phase.values['problemIds'], ['challenge-1']);
      expect(phase.values['sortOrder'], 3);
      expect(
        package.toJson()['collections'],
        containsPair(SyncCollections.studyPhases, isA<List<Object>>()),
      );

      await database.close();
    },
  );

  test('cria e recupera backup antes de aplicar uma mesclagem', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SyncDatabaseRepository(database.database);
    await database.database.insert('flashcards', {
      'id': 'backup-card',
      'front': 'Estado local',
      'back': 'Preservado no backup',
      'created_at': '2026-09-30T00:00:00.000Z',
      'due_at': '2026-09-30T00:00:00.000Z',
    });

    final emptyPackage = SyncPackage.empty(
      exportedAt: DateTime.utc(2026, 9, 30, 12),
      source: const SyncIdentity(deviceId: 'desktop-1', deviceName: 'Desktop'),
    );
    final result = await repository.apply(
      await repository.preview(emptyPackage),
    );

    expect(result.backupId, isNotNull);
    final backups = await repository.listBackups();
    expect(backups, hasLength(1));
    final backup = repository.decodePackage(
      await repository.readBackup(backups.single.id),
    );
    expect(
      backup.recordsFor(SyncCollections.flashcards).single.id,
      'backup-card',
    );

    await database.close();
  });

  test('atualiza bancos das versões 22 e 23 para o esquema atual', () async {
    for (final oldVersion in [22, 23]) {
      final directory = await Directory.systemTemp.createTemp(
        'dunots-migration-',
      );
      final databasePath = path.join(directory.path, 'legacy.db');
      final current = await AppDatabase.open(
        databasePathOverride: databasePath,
      );
      await current.close();

      final raw = await databaseFactory.openDatabase(databasePath);
      await raw.execute('PRAGMA user_version = $oldVersion');
      await raw.close();

      final migrated = await AppDatabase.open(
        databasePathOverride: databasePath,
      );
      final phaseTables = await migrated.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('study_phases', 'sync_backups')",
      );
      final flashcardColumns = await migrated.database.rawQuery(
        'PRAGMA table_info(flashcards)',
      );
      expect(
        phaseTables.map((row) => row['name']),
        containsAll(['study_phases', 'sync_backups']),
      );
      expect(
        flashcardColumns.map((row) => row['name']),
        containsAll(['language', 'quiz_question_id']),
      );
      await migrated.close();
      await directory.delete(recursive: true);
    }
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
      await database.database.insert('challenges', {
        'id': 'challenge-1',
        'problem_id': 'two-sum',
        'title': 'Two Sum',
        'difficulty': 'easy',
        'created_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });
      await database.database.insert('challenge_reviews', {
        'id': 'challenge-review-1',
        'challenge_id': 'challenge-1',
        'rating': 'easy',
        'reviewed_at': '2026-09-30T10:00:00.000Z',
        'previous_interval': 0,
        'next_interval': 4,
        'due_at': '2026-10-04T10:00:00.000Z',
      });

      final first = await repository.exportPackage();
      final decoded = repository.decodePackage(await repository.exportBytes());

      expect(first.source.deviceId, decoded.source.deviceId);
      expect(decoded.recordsFor(SyncCollections.flashcards), hasLength(1));
      expect(
        decoded.recordsFor(SyncCollections.flashcards).single.id,
        'card-1',
      );
      expect(
        decoded.recordsFor(SyncCollections.challengeReviews).single.values,
        containsPair('challengeId', 'challenge-1'),
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
