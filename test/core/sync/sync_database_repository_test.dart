import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/sync/sync_contract.dart';
import 'package:dunots_mobile/core/sync/sync_database_repository.dart';
import 'package:dunots_mobile/features/quizzes/data/sqlite_quiz_attempt_repository.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';

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

  test('aceita pacote legado sem metadados opcionais do envelope', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SyncDatabaseRepository(database.database);
    final package = repository.decodePackage(
      Uint8List.fromList(
        utf8.encode(
          jsonEncode({
            'format': 'dunots-sync',
            'version': 1,
            'collections': {
              'flashcards': [
                {'id': 'legacy-card', 'question': 'Frente antiga'},
              ],
            },
          }),
        ),
      ),
    );

    expect(package.source.deviceId, 'unknown');
    expect(package.source.deviceName, 'Dispositivo desconhecido');
    expect(package.exportedAt, isNotNull);
    expect(
      package.recordsFor(SyncCollections.flashcards).single.values['question'],
      'Frente antiga',
    );

    await database.close();
  });

  test(
    'normaliza tentativa exportada pelo desktop para o mural mobile',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final syncRepository = SyncDatabaseRepository(database.database);
      final package = SyncPackage(
        exportedAt: DateTime.utc(2026, 10, 3),
        source: const SyncIdentity(deviceId: 'desktop', deviceName: 'Desktop'),
        collections: {
          SyncCollections.quizAttempts: [
            SyncRecord({
              'id': 'desktop-attempt-1',
              'title': 'Simulado de redes',
              'questionIds': ['question-1'],
              'currentQuestionIndex': 2,
              'status': 'in-progress',
              'answers': {'question-1': 'B'},
              'startedAt': '2026-10-03T10:00:00.000Z',
              'updatedAt': '2026-10-03T10:05:00.000Z',
            }),
          ],
        },
      );

      final preview = await syncRepository.preview(package);
      await syncRepository.apply(
        preview,
        defaultResolution: SyncConflictResolution.useReceived,
      );

      final attempts = await SqliteQuizAttemptRepository(database).getAll();
      expect(attempts, hasLength(1));
      expect(attempts.single.status, QuizAttemptStatus.inProgress);
      expect(attempts.single.currentIndex, 2);
      expect(attempts.single.answers['question-1'], 1);
      expect(attempts.single.createdAt, DateTime.utc(2026, 10, 3, 10));

      await database.close();
    },
  );

  test(
    'repara tentativas desktop existentes ao migrar para a versão atual',
    () async {
      final databasePath = path.join(
        Directory.systemTemp.path,
        'dunots-attempt-migration-${DateTime.now().microsecondsSinceEpoch}.db',
      );
      addTearDown(() => deleteDatabase(databasePath));

      final current = await AppDatabase.open(
        databasePathOverride: databasePath,
      );
      await current.database.insert('quiz_attempts', {
        'id': 'legacy-desktop-attempt',
        'title': 'Tentativa desktop',
        'question_ids': '["question-1"]',
        'current_index': 0,
        'status': 'in-progress',
        'answers': '{"question-1":"A"}',
        'review_question_ids': '[]',
        'review_notes': '{}',
        'created_at': '',
        'updated_at': '2026-10-03T10:00:00.000Z',
      });
      await current.close();

      final raw = await databaseFactory.openDatabase(databasePath);
      await raw.execute('PRAGMA user_version = 29');
      await raw.close();

      final migrated = await AppDatabase.open(
        databasePathOverride: databasePath,
      );
      final attempt = (await SqliteQuizAttemptRepository(
        migrated,
      ).getAll()).single;
      expect(attempt.status, QuizAttemptStatus.inProgress);
      expect(attempt.createdAt, DateTime.utc(2026, 10, 3, 10));
      expect(attempt.answers['question-1'], 0);

      await migrated.close();
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

  test('exporta timestamps reais para trilha, tópico e vínculo', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SyncDatabaseRepository(database.database);
    final createdAt = DateTime.utc(2026, 9, 30, 8);
    final updatedAt = DateTime.utc(2026, 10, 1, 9);

    await database.database.insert('study_tracks', {
      'id': 'track-sync',
      'title': 'Redes',
      'description': 'Base',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    });
    await database.database.insert('study_nodes', {
      'id': 'node-sync',
      'track_id': 'track-sync',
      'title': 'OSI',
      'description': 'Camadas',
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    });
    await database.database.insert('study_node_materials', {
      'node_id': 'node-sync',
      'material_id': 'card-sync',
      'material_type': 'flashcard',
      'updated_at': updatedAt.toIso8601String(),
    });

    final package = await repository.exportPackage();
    final track = package.recordsFor(SyncCollections.studyRoadmaps).single;
    final node = package.recordsFor(SyncCollections.roadmapNodes).single;
    final link = package.recordsFor(SyncCollections.roadmapLinks).single;

    expect(track.values['createdAt'], createdAt.toIso8601String());
    expect(track.values['updatedAt'], updatedAt.toIso8601String());
    expect(node.values['createdAt'], createdAt.toIso8601String());
    expect(node.values['updatedAt'], updatedAt.toIso8601String());
    expect(link.values['updatedAt'], updatedAt.toIso8601String());
    expect(track.values['updatedAt'], isNot('1970-01-01T00:00:00.000Z'));

    await database.close();
  });

  test('importa timestamps recebidos de trilha, tópico e vínculo', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SyncDatabaseRepository(database.database);
    final package = SyncPackage(
      exportedAt: DateTime.utc(2026, 10, 1),
      source: const SyncIdentity(
        deviceId: 'desktop-sync',
        deviceName: 'Desktop',
      ),
      collections: {
        SyncCollections.studyRoadmaps: [
          SyncRecord({
            'id': 'track-received',
            'title': 'Trilha recebida',
            'description': 'Descrição',
            'completedItems': 1,
            'totalItems': 2,
            'createdAt': '2026-09-30T08:00:00.000Z',
            'updatedAt': '2026-10-01T09:00:00.000Z',
          }),
        ],
        SyncCollections.roadmapNodes: [
          SyncRecord({
            'id': 'node-received',
            'trackId': 'track-received',
            'parentId': null,
            'title': 'Tópico',
            'description': 'Descrição',
            'sortOrder': 0,
            'isCompleted': false,
            'notes': '',
            'priority': 0,
            'createdAt': '2026-09-30T08:00:00.000Z',
            'updatedAt': '2026-10-01T09:00:00.000Z',
          }),
        ],
        SyncCollections.roadmapLinks: [
          SyncRecord({
            'id': 'node-received:card-received:flashcard',
            'nodeId': 'node-received',
            'materialId': 'card-received',
            'materialType': 'flashcard',
            'updatedAt': '2026-10-01T09:00:00.000Z',
          }),
        ],
      },
    );

    final preview = await repository.preview(package);
    await repository.apply(
      preview,
      defaultResolution: SyncConflictResolution.useReceived,
    );

    final track = (await database.database.query(
      'study_tracks',
      where: 'id = ?',
      whereArgs: ['track-received'],
    )).single;
    final node = (await database.database.query(
      'study_nodes',
      where: 'id = ?',
      whereArgs: ['node-received'],
    )).single;
    final link = (await database.database.query(
      'study_node_materials',
      where: 'node_id = ?',
      whereArgs: ['node-received'],
    )).single;

    expect(track['updated_at'], '2026-10-01T09:00:00.000Z');
    expect(node['updated_at'], '2026-10-01T09:00:00.000Z');
    expect(link['updated_at'], '2026-10-01T09:00:00.000Z');

    await database.close();
  });

  test(
    'importa roadmap exportado pelo desktop com aliases e pais fora da ordem',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final repository = SyncDatabaseRepository(database.database);
      final package = SyncPackage(
        exportedAt: DateTime.utc(2026, 10, 2),
        source: const SyncIdentity(deviceId: 'desktop', deviceName: 'Desktop'),
        collections: {
          SyncCollections.studyRoadmaps: [
            SyncRecord({
              'id': 'desktop-roadmap',
              'title': 'Infraestrutura',
              'description': 'Trilha exportada',
              'createdAt': '2026-10-01T00:00:00.000Z',
              'updatedAt': '2026-10-02T00:00:00.000Z',
            }),
          ],
          SyncCollections.roadmapNodes: [
            SyncRecord({
              'id': 'desktop-child',
              'roadmapId': 'desktop-roadmap',
              'parentId': 'desktop-parent',
              'title': 'Subtópico',
              'description': '',
              'order': 1,
              'completed': true,
              'notes': 'Nota',
              'priority': 'high',
              'createdAt': '2026-10-01T00:00:00.000Z',
              'updatedAt': '2026-10-02T00:00:00.000Z',
            }),
            SyncRecord({
              'id': 'desktop-parent',
              'roadmapId': 'desktop-roadmap',
              'parentId': null,
              'title': 'Tópico',
              'description': '',
              'order': 0,
              'completed': false,
              'notes': '',
              'priority': 'none',
              'createdAt': '2026-10-01T00:00:00.000Z',
              'updatedAt': '2026-10-02T00:00:00.000Z',
            }),
          ],
          SyncCollections.roadmapLinks: [
            SyncRecord({
              'id': 'desktop-parent:card-1:flashcard',
              'nodeId': 'desktop-parent',
              'resourceId': 'card-1',
              'resourceType': 'flashcard',
              'updatedAt': '2026-10-02T00:00:00.000Z',
            }),
          ],
        },
      );

      await repository.apply(
        await repository.preview(package),
        defaultResolution: SyncConflictResolution.useReceived,
      );

      final child = (await database.database.query(
        'study_nodes',
        where: 'id = ?',
        whereArgs: ['desktop-child'],
      )).single;
      final link = (await database.database.query('study_node_materials'))
          .single;
      expect(child['track_id'], 'desktop-roadmap');
      expect(child['parent_id'], 'desktop-parent');
      expect(child['priority'], 3);
      expect(child['is_completed'], 1);
      expect(link['material_id'], 'card-1');
      expect(link['material_type'], 'flashcard');

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

  test(
    'restaura backup pela camada de persistência e cria backup de segurança',
    () async {
      final database = await AppDatabase.open(
        databasePathOverride: inMemoryDatabasePath,
      );
      final repository = SyncDatabaseRepository(database.database);
      await database.database.insert('flashcards', {
        'id': 'restore-card',
        'front': 'Estado que será restaurado',
        'back': 'Resposta',
        'created_at': '2026-09-30T00:00:00.000Z',
        'due_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });
      await database.database.insert('study_tracks', {
        'id': 'restore-track',
        'title': 'Trilha restaurada',
        'description': 'Descrição',
        'created_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });
      await database.database.insert('study_nodes', {
        'id': 'restore-node',
        'track_id': 'restore-track',
        'title': 'Tópico restaurado',
        'description': '',
        'created_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });
      await database.database.insert('study_node_materials', {
        'node_id': 'restore-node',
        'material_id': 'restore-card',
        'material_type': 'flashcard',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });

      final originalBackup = await repository.createBackup();
      await database.database.update(
        'flashcards',
        {'front': 'Estado alterado'},
        where: 'id = ?',
        whereArgs: ['restore-card'],
      );
      await database.database.insert('flashcards', {
        'id': 'extra-card',
        'front': 'Não existia no backup',
        'back': 'Resposta',
        'created_at': '2026-09-30T00:00:00.000Z',
        'due_at': '2026-09-30T00:00:00.000Z',
        'updated_at': '2026-09-30T00:00:00.000Z',
      });

      final result = await repository.restoreBackup(originalBackup.id);
      final cards = await database.database.query(
        'flashcards',
        orderBy: 'id ASC',
      );

      expect(result.restoredBackupId, originalBackup.id);
      expect(result.safetyBackupId, isNot(originalBackup.id));
      expect(cards, hasLength(1));
      expect(cards.single['id'], 'restore-card');
      expect(cards.single['front'], 'Estado que será restaurado');
      expect(
        (await database.database.query('study_tracks')).single['title'],
        'Trilha restaurada',
      );
      expect(
        (await database.database.query('study_nodes')).single['title'],
        'Tópico restaurado',
      );
      expect(
        (await database.database.query('study_node_materials'))
            .single['updated_at'],
        '2026-09-30T00:00:00.000Z',
      );
      expect(await repository.listBackups(), hasLength(2));

      await database.close();
    },
  );

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

  test('migra bancos da versão 25 sem deixar timestamps em 1970', () async {
    final directory = await Directory.systemTemp.createTemp(
      'dunots-timestamp-migration-',
    );
    final databasePath = path.join(directory.path, 'legacy.db');
    final current = await AppDatabase.open(databasePathOverride: databasePath);
    await current.database.insert('study_tracks', {
      'id': 'legacy-track',
      'title': 'Legado',
      'description': '',
      'created_at': '',
      'updated_at': '',
    });
    await current.database.insert('study_nodes', {
      'id': 'legacy-node',
      'track_id': 'legacy-track',
      'title': 'Tópico legado',
      'description': '',
      'created_at': '',
      'updated_at': '',
    });
    await current.database.insert('study_node_materials', {
      'node_id': 'legacy-node',
      'material_id': 'legacy-card',
      'material_type': 'flashcard',
      'updated_at': '',
    });
    await current.close();

    final raw = await databaseFactory.openDatabase(databasePath);
    await raw.execute('PRAGMA user_version = 25');
    await raw.close();

    final migrated = await AppDatabase.open(databasePathOverride: databasePath);
    final track = (await migrated.database.query('study_tracks')).single;
    final node = (await migrated.database.query('study_nodes')).single;
    final link = (await migrated.database.query('study_node_materials')).single;

    expect(track['created_at'], isNotEmpty);
    expect(track['updated_at'], isNotEmpty);
    expect(node['created_at'], isNotEmpty);
    expect(node['updated_at'], isNotEmpty);
    expect(link['updated_at'], isNotEmpty);
    expect(track['updated_at'], isNot('1970-01-01T00:00:00.000Z'));

    await migrated.close();
    await directory.delete(recursive: true);
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
