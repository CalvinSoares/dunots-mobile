import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../features/questions/domain/question.dart';
import 'quiz_sync_mappers.dart';
import 'sync_contract.dart';

enum SyncConflictResolution { keepLocal, useReceived }

class SyncConflict {
  final String collection;
  final String recordId;
  final SyncRecord local;
  final SyncRecord received;

  const SyncConflict({
    required this.collection,
    required this.recordId,
    required this.local,
    required this.received,
  });

  String get key => '$collection:$recordId';
}

class SyncMergePreview {
  final SyncPackage package;
  final int additions;
  final int unchanged;
  final int deletions;
  final List<SyncConflict> conflicts;
  final Set<String> unsupportedCollections;

  const SyncMergePreview({
    required this.package,
    required this.additions,
    required this.unchanged,
    required this.deletions,
    required this.conflicts,
    required this.unsupportedCollections,
  });

  bool get requiresDecision => conflicts.isNotEmpty;
}

class SyncApplyResult {
  final int added;
  final int updated;
  final int deleted;
  final int keptLocal;

  const SyncApplyResult({
    required this.added,
    required this.updated,
    required this.deleted,
    required this.keptLocal,
  });
}

/// Persiste o contrato de sincronização e faz merge com o SQLite local.
///
/// O arquivo `.dunots` é JSON UTF-8 com extensão própria. Isso o mantém
/// inspecionável, portátil e compatível com desktop/web sem criar dependência
/// de um compactador específico nesta primeira versão.
class SyncDatabaseRepository {
  final Database database;

  const SyncDatabaseRepository(this.database);

  static const supportedCollections = <String>{
    SyncCollections.flashcards,
    SyncCollections.leetcodeProblems,
    SyncCollections.diagrams,
    SyncCollections.quizExams,
    SyncCollections.quizQuestions,
    SyncCollections.quizAttempts,
    SyncCollections.studyRoadmaps,
    SyncCollections.roadmapNodes,
    SyncCollections.roadmapLinks,
    SyncCollections.syncTombstones,
  };

  Future<SyncIdentity> getIdentity() async {
    final rows = await database.query(
      'sync_metadata',
      where: 'key IN (?, ?)',
      whereArgs: ['device_id', 'device_name'],
    );
    final values = <String, String>{
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
    final existingId = values['device_id'];
    final existingName = values['device_name'];
    if (existingId != null && existingName != null) {
      return SyncIdentity(deviceId: existingId, deviceName: existingName);
    }

    final now = DateTime.now().microsecondsSinceEpoch;
    final identity = SyncIdentity(
      deviceId: 'mobile-$now',
      deviceName: 'Dunots Mobile',
    );
    await database.insert('sync_metadata', {
      'key': 'device_id',
      'value': identity.deviceId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await database.insert('sync_metadata', {
      'key': 'device_name',
      'value': identity.deviceName,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return identity;
  }

  Future<SyncPackage> exportPackage() async {
    final identity = await getIdentity();
    return SyncPackage(
      exportedAt: DateTime.now().toUtc(),
      source: identity,
      collections: await _readCollections(),
    );
  }

  Future<Uint8List> exportBytes() async {
    final package = await exportPackage();
    return Uint8List.fromList(utf8.encode(jsonEncode(package.toJson())));
  }

  SyncPackage decodePackage(Uint8List bytes) {
    try {
      final value = jsonDecode(utf8.decode(bytes));
      return SyncPackage.fromJson(value);
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Não foi possível ler o pacote .dunots: $error');
    }
  }

  Future<SyncMergePreview> preview(SyncPackage package) async {
    final local = await _readCollections();
    final localByCollection = {
      for (final entry in local.entries)
        entry.key: {for (final record in entry.value) record.id: record},
    };
    final localTombstones = _tombstoneMap(
      local[SyncCollections.syncTombstones],
    );
    final conflicts = <SyncConflict>[];
    var additions = 0;
    var unchanged = 0;
    var deletions = 0;
    final unsupported = <String>{};

    for (final collection in SyncCollections.all) {
      if (!supportedCollections.contains(collection)) {
        if (package.recordsFor(collection).isNotEmpty) {
          unsupported.add(collection);
        }
        continue;
      }
      if (collection == SyncCollections.syncTombstones) continue;
      final current =
          localByCollection[collection] ?? const <String, SyncRecord>{};
      for (final received in package.recordsFor(collection)) {
        final tombstone = localTombstones['$collection:${received.id}'];
        if (tombstone != null &&
            _date(tombstone.values['deletedAt'])
                .isAfter(_recordDate(received))) {
          unchanged++;
          continue;
        }
        final localRecord = current[received.id];
        if (localRecord == null) {
          additions++;
        } else if (_sameRecord(localRecord, received)) {
          unchanged++;
        } else {
          conflicts.add(
            SyncConflict(
              collection: collection,
              recordId: received.id,
              local: localRecord,
              received: received,
            ),
          );
        }
      }
    }

    for (final tombstone in package.recordsFor(
      SyncCollections.syncTombstones,
    )) {
      final collection = tombstone.values['collection'];
      final recordId = tombstone.values['recordId'];
      if (collection is! String || recordId is! String) continue;
      final localRecord = localByCollection[collection]?[recordId];
      if (localRecord == null) continue;
      if (_date(tombstone.values['deletedAt'])
          .isAfter(_recordDate(localRecord))) {
        deletions++;
      }
    }

    return SyncMergePreview(
      package: package,
      additions: additions,
      unchanged: unchanged,
      deletions: deletions,
      conflicts: List.unmodifiable(conflicts),
      unsupportedCollections: Set.unmodifiable(unsupported),
    );
  }

  Future<SyncApplyResult> apply(
    SyncMergePreview preview, {
    SyncConflictResolution defaultResolution = SyncConflictResolution.keepLocal,
    Map<String, SyncConflictResolution> resolutions = const {},
  }) async {
    final local = await _readCollections();
    final localByCollection = {
      for (final entry in local.entries)
        entry.key: {for (final record in entry.value) record.id: record},
    };
    final localTombstones = _tombstoneMap(
      local[SyncCollections.syncTombstones],
    );
    var added = 0;
    var updated = 0;
    var deleted = 0;
    var keptLocal = 0;

    await database.transaction((transaction) async {
      for (final collection in SyncCollections.all) {
        if (!supportedCollections.contains(collection) ||
            collection == SyncCollections.syncTombstones) {
          continue;
        }
        final current =
            localByCollection[collection] ?? const <String, SyncRecord>{};
        for (final received in preview.package.recordsFor(collection)) {
          final tombstone = localTombstones['$collection:${received.id}'];
          if (tombstone != null &&
              _date(tombstone.values['deletedAt'])
                  .isAfter(_recordDate(received))) {
            keptLocal++;
            continue;
          }
          final localRecord = current[received.id];
          if (localRecord == null) {
            await _upsert(transaction, collection, received);
            added++;
            continue;
          }
          if (_sameRecord(localRecord, received)) continue;
          final resolution =
              resolutions['$collection:${received.id}'] ?? defaultResolution;
          if (resolution == SyncConflictResolution.useReceived) {
            await _upsert(transaction, collection, received);
            updated++;
          } else {
            keptLocal++;
          }
        }
      }

      for (final tombstone in preview.package.recordsFor(
        SyncCollections.syncTombstones,
      )) {
        final collection = tombstone.values['collection'];
        final recordId = tombstone.values['recordId'];
        if (collection is! String || recordId is! String) continue;
        final localRecord = localByCollection[collection]?[recordId];
        if (localRecord != null &&
            _date(tombstone.values['deletedAt'])
                .isAfter(_recordDate(localRecord))) {
          await _deleteBySyncId(transaction, collection, recordId);
          deleted++;
        }
        await transaction.insert(
          'sync_tombstones',
          _tombstoneRow(tombstone),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    return SyncApplyResult(
      added: added,
      updated: updated,
      deleted: deleted,
      keptLocal: keptLocal,
    );
  }

  Future<Map<String, List<SyncRecord>>> _readCollections() async {
    final collections = <String, List<SyncRecord>>{
      for (final collection in SyncCollections.all) collection: <SyncRecord>[],
    };
    collections[SyncCollections.flashcards] = (await database.query(
      'flashcards',
    )).map(_flashcardRecord).toList(growable: false);
    collections[SyncCollections.leetcodeProblems] = (await database.query(
      'challenges',
    )).map(_challengeRecord).toList(growable: false);
    collections[SyncCollections.diagrams] = (await database.query('diagrams'))
        .map(_diagramRecord)
        .toList(growable: false);
    collections[SyncCollections.quizExams] = (await database.query(
      'quiz_exams',
    )).map(_examRecord).toList(growable: false);
    collections[SyncCollections.quizQuestions] = (await database.query(
      'questions',
    )).map(_questionRecord).toList(growable: false);
    collections[SyncCollections.quizAttempts] = (await database.query(
      'quiz_attempts',
    )).map(_attemptRecord).toList(growable: false);
    collections[SyncCollections.studyRoadmaps] = (await database.query(
      'study_tracks',
    )).map(_trackRecord).toList(growable: false);
    collections[SyncCollections.roadmapNodes] = (await database.query(
      'study_nodes',
    )).map(_nodeRecord).toList(growable: false);
    collections[SyncCollections.roadmapLinks] = (await database.query(
      'study_node_materials',
    )).map(_linkRecord).toList(growable: false);
    collections[SyncCollections.syncTombstones] = (await database.query(
      'sync_tombstones',
    )).map(_tombstoneRecord).toList(growable: false);
    return collections;
  }

  SyncRecord _flashcardRecord(Map<String, Object?> row) {
    final createdAt = _string(row['created_at']);
    return SyncRecord({
      'id': _string(row['id']),
      'front': _string(row['front']),
      'back': _string(row['back']),
      'code': _string(row['code']),
      'tags': _decodeList(row['tags']),
      'linkedMaterialIds': _decodeList(row['linked_material_ids']),
      'diagramIds': _decodeList(row['diagram_ids']),
      'createdAt': createdAt,
      'dueAt': _string(row['due_at']),
      'lastReviewedAt': _optionalString(row['last_reviewed_at']),
      'reviewCount': row['review_count'] ?? 0,
      'lastRating': _optionalString(row['last_rating']),
      'interval': row['interval'] ?? 0,
      'easeFactor': row['ease_factor'] ?? 2.5,
      'repetitions': row['repetitions'] ?? 0,
      'updatedAt':
          _optionalString(row['updated_at']) ??
          _optionalString(row['last_reviewed_at']) ??
          createdAt,
    });
  }

  SyncRecord _challengeRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'problemId': _string(row['problem_id']),
      'title': _string(row['title']),
      'variantName': _string(row['variant_name']),
      'strategy': _string(row['strategy']),
      'url': _string(row['url']),
      'difficulty': _string(row['difficulty']),
      'tags': _decodeList(row['tags']),
      'complexity': _string(row['complexity']),
      'timeComplexity': _string(row['time_complexity']),
      'spaceComplexity': _string(row['space_complexity']),
      'tradeoffs': _string(row['tradeoffs']),
      'diagramIds': _decodeList(row['diagram_ids']),
      'solution': _string(row['solution']),
      'notes': _string(row['notes']),
      'solvedAt': _optionalString(row['solved_at']),
      'dueAt': _optionalString(row['due_at']),
      'interval': row['interval'] ?? 0,
      'easeFactor': row['ease_factor'] ?? 2.5,
      'repetitions': row['repetitions'] ?? 0,
      'createdAt': _string(row['created_at']),
      'updatedAt': _string(row['updated_at']),
    });
  }

  SyncRecord _diagramRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'title': _string(row['title']),
      'description': row['description'],
      'nodes': _decodeList(row['nodes']),
      'edges': _decodeList(row['edges']),
      'phaseIds': _decodeList(row['phase_ids']),
      'flashcardIds': _decodeList(row['flashcard_ids']),
      'problemIds': _decodeList(row['problem_ids']),
      'createdAt': _string(row['created_at']),
      'updatedAt': _string(row['updated_at']),
    });
  }

  SyncRecord _examRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'title': _string(row['title']),
      'contestName': _string(row['contest_name']),
      'vacancy': _string(row['vacancy']),
      if (row['proof_version'] != null) 'proofVersion': row['proof_version'],
      if (row['board'] != null) 'board': row['board'],
      if (row['year'] != null) 'year': row['year'],
      if (row['source_name'] != null) 'sourceName': row['source_name'],
      if (row['answer_key_name'] != null)
        'answerKeyName': row['answer_key_name'],
      'createdAt': _string(row['created_at']),
      'updatedAt': _string(row['updated_at']),
    });
  }

  SyncRecord _questionRecord(Map<String, Object?> row) {
    final alternatives = _decodeList(row['alternatives']);
    return SyncRecord({
      'id': _string(row['id']),
      if (row['exam_id'] != null) 'examId': row['exam_id'],
      if (row['question_number'] != null) 'order': row['question_number'],
      'statement': _string(row['statement']),
      'options': alternatives
          .asMap()
          .entries
          .map(
            (entry) => {
              'id': String.fromCharCode(65 + entry.key),
              'text': entry.value,
            },
          )
          .toList(growable: false),
      'correctOption': String.fromCharCode(
        65 + (row['correct_alternative_index'] as int),
      ),
      'explanation': _string(row['explanation']),
      'notes': _string(row['notes']),
      'contestName': _string(row['contest']),
      'vacancy': _string(row['role']),
      'examName': _string(row['exam']),
      'subject': _string(row['subject']),
      'topic': _string(row['topic']),
      if (row['source_name'] != null) 'sourceName': row['source_name'],
      if (row['source_page'] != null) 'sourcePage': row['source_page'],
      if (row['visual_image'] != null) 'visualImage': row['visual_image'],
      'visualImages': _decodeList(row['visual_images']),
      'createdAt': _string(row['created_at']),
      'updatedAt': _string(row['updated_at']),
    });
  }

  SyncRecord _attemptRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'title': _string(row['title']),
      'questionIds': _decodeList(row['question_ids']),
      'currentIndex': row['current_index'],
      'status': row['status'],
      'answers': _decodeMap(row['answers']),
      'reviewQuestionIds': _decodeList(row['review_question_ids']),
      'reviewNotes': _decodeMap(row['review_notes']),
      'createdAt': _string(row['created_at']),
      'updatedAt': _string(row['updated_at']),
    });
  }

  SyncRecord _trackRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'title': _string(row['title']),
      'description': _string(row['description']),
      'completedItems': row['completed_items'],
      'totalItems': row['total_items'],
      'updatedAt': '1970-01-01T00:00:00.000Z',
    });
  }

  SyncRecord _nodeRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'trackId': _string(row['track_id']),
      'parentId': row['parent_id'],
      'title': _string(row['title']),
      'description': _string(row['description']),
      'sortOrder': row['sort_order'],
      'isCompleted': row['is_completed'] == 1,
      'notes': _string(row['notes']),
      'priority': row['priority'],
      'updatedAt': '1970-01-01T00:00:00.000Z',
    });
  }

  SyncRecord _linkRecord(Map<String, Object?> row) {
    final id = _linkId(row);
    return SyncRecord({
      'id': id,
      'nodeId': _string(row['node_id']),
      'materialId': _string(row['material_id']),
      'materialType': _string(row['material_type']),
      'updatedAt': '1970-01-01T00:00:00.000Z',
    });
  }

  SyncRecord _tombstoneRecord(Map<String, Object?> row) {
    return SyncRecord({
      'id': _string(row['id']),
      'collection': _string(row['collection']),
      'recordId': _string(row['record_id']),
      'deletedAt': _string(row['deleted_at']),
      'deletedBy': _string(row['deleted_by']),
    });
  }

  Future<void> _upsert(
    DatabaseExecutor executor,
    String collection,
    SyncRecord record,
  ) async {
    final values = record.values;
    switch (collection) {
      case SyncCollections.flashcards:
        await executor.insert('flashcards', {
          'id': record.id,
          'front': _string(values['front']),
          'back': _string(values['back']),
          'code': _string(values['code']),
          'tags': jsonEncode(_list(values['tags'])),
          'linked_material_ids': jsonEncode(_list(values['linkedMaterialIds'])),
          'diagram_ids': jsonEncode(_list(values['diagramIds'])),
          'created_at': _string(values['createdAt']),
          'due_at': _string(values['dueAt']),
          'last_reviewed_at': values['lastReviewedAt'],
          'review_count': values['reviewCount'] ?? 0,
          'last_rating': values['lastRating'],
          'interval': values['interval'] ?? 0,
          'ease_factor': values['easeFactor'] ?? 2.5,
          'repetitions': values['repetitions'] ?? 0,
          'updated_at': _string(values['updatedAt']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.leetcodeProblems:
        await executor.insert('challenges', {
          'id': record.id,
          'problem_id': _string(values['problemId']),
          'title': _string(values['title']),
          'variant_name': _string(values['variantName']),
          'strategy': _string(values['strategy']),
          'url': _string(values['url']),
          'difficulty': _string(values['difficulty']),
          'tags': jsonEncode(_list(values['tags'])),
          'complexity': _string(values['complexity']),
          'time_complexity': _string(values['timeComplexity']),
          'space_complexity': _string(values['spaceComplexity']),
          'tradeoffs': _string(values['tradeoffs']),
          'diagram_ids': jsonEncode(_list(values['diagramIds'])),
          'solution': _string(values['solution']),
          'notes': _string(values['notes']),
          'solved_at': values['solvedAt'],
          'due_at': values['dueAt'],
          'interval': values['interval'] ?? 0,
          'ease_factor': values['easeFactor'] ?? 2.5,
          'repetitions': values['repetitions'] ?? 0,
          'created_at': _string(values['createdAt']),
          'updated_at': _string(values['updatedAt']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.diagrams:
        await executor.insert('diagrams', {
          'id': record.id,
          'title': _string(values['title']),
          'description': values['description'],
          'nodes': jsonEncode(_list(values['nodes'])),
          'edges': jsonEncode(_list(values['edges'])),
          'phase_ids': jsonEncode(_list(values['phaseIds'])),
          'flashcard_ids': jsonEncode(_list(values['flashcardIds'])),
          'problem_ids': jsonEncode(_list(values['problemIds'])),
          'created_at': _string(values['createdAt']),
          'updated_at': _string(values['updatedAt']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.quizExams:
        final exam = QuizExamSyncMapper.fromRecord(record);
        await executor.insert('quiz_exams', {
          'id': exam.id,
          'title': exam.title,
          'contest_name': exam.contestName,
          'vacancy': exam.vacancy,
          'board': exam.board,
          'year': exam.year,
          'proof_version': exam.proofVersion,
          'source_name': exam.sourceName,
          'answer_key_name': exam.answerKeyName,
          'created_at': exam.createdAt.toIso8601String(),
          'updated_at': exam.updatedAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.quizQuestions:
        final question = QuestionSyncMapper.fromRecord(record);
        await executor.insert(
          'questions',
          _questionRow(question),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return;
      case SyncCollections.quizAttempts:
        await executor.insert('quiz_attempts', {
          'id': record.id,
          'title': _string(values['title']),
          'question_ids': jsonEncode(_list(values['questionIds'])),
          'current_index': values['currentIndex'] ?? 0,
          'status': _string(values['status']),
          'answers': jsonEncode(_map(values['answers'])),
          'review_question_ids': jsonEncode(_list(values['reviewQuestionIds'])),
          'review_notes': jsonEncode(_map(values['reviewNotes'])),
          'created_at': _string(values['createdAt']),
          'updated_at': _string(values['updatedAt']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.studyRoadmaps:
        await executor.insert('study_tracks', {
          'id': record.id,
          'title': _string(values['title']),
          'description': _string(values['description']),
          'completed_items': values['completedItems'] ?? 0,
          'total_items': values['totalItems'] ?? 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.roadmapNodes:
        await executor.insert('study_nodes', {
          'id': record.id,
          'track_id': _string(values['trackId']),
          'parent_id': values['parentId'],
          'title': _string(values['title']),
          'description': _string(values['description']),
          'sort_order': values['sortOrder'] ?? 0,
          'is_completed': values['isCompleted'] == true ? 1 : 0,
          'notes': _string(values['notes']),
          'priority': values['priority'] ?? 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
      case SyncCollections.roadmapLinks:
        await executor.insert('study_node_materials', {
          'node_id': _string(values['nodeId']),
          'material_id': _string(values['materialId']),
          'material_type': _string(values['materialType']),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        return;
    }
  }

  Map<String, Object?> _questionRow(Question question) {
    return {
      'id': question.id,
      'question_number': question.number,
      'statement': question.statement,
      'alternatives': jsonEncode(question.alternatives),
      'correct_alternative_index': question.correctAlternativeIndex,
      'explanation': question.explanation,
      'contest': question.contest,
      'role': question.role,
      'topic': question.topic,
      'exam': question.exam,
      'exam_id': question.examId,
      'subject': question.subject,
      'notes': question.notes,
      'source_name': question.sourceName,
      'source_page': question.sourcePage,
      'visual_image': question.visualImage,
      'visual_images': jsonEncode(question.visualImages),
      'created_at': question.createdAt.toIso8601String(),
      'updated_at': question.updatedAt.toIso8601String(),
    };
  }

  Future<void> _deleteBySyncId(
    DatabaseExecutor executor,
    String collection,
    String id,
  ) async {
    switch (collection) {
      case SyncCollections.flashcards:
        await executor.delete('flashcards', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.leetcodeProblems:
        await executor.delete('challenges', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.diagrams:
        await executor.delete('diagrams', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.quizExams:
        await executor.delete('quiz_exams', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.quizQuestions:
        await executor.delete('questions', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.quizAttempts:
        await executor.delete(
          'quiz_attempts',
          where: 'id = ?',
          whereArgs: [id],
        );
        break;
      case SyncCollections.studyRoadmaps:
        await executor.delete('study_tracks', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.roadmapNodes:
        await executor.delete('study_nodes', where: 'id = ?', whereArgs: [id]);
        break;
      case SyncCollections.roadmapLinks:
        final parts = id.split(':');
        if (parts.length == 3) {
          await executor.delete(
            'study_node_materials',
            where: 'node_id = ? AND material_id = ? AND material_type = ?',
            whereArgs: parts,
          );
        }
        break;
    }
  }

  Map<String, Object?> _tombstoneRow(SyncRecord record) {
    return {
      'id': record.id,
      'collection': record.values['collection'],
      'record_id': record.values['recordId'],
      'deleted_at': record.values['deletedAt'],
      'deleted_by': record.values['deletedBy'] ?? 'received',
    };
  }

  Map<String, SyncRecord> _tombstoneMap(List<SyncRecord>? values) {
    return {
      for (final record in values ?? const <SyncRecord>[])
        '${record.values['collection']}:${record.values['recordId']}': record,
    };
  }

  bool _sameRecord(SyncRecord first, SyncRecord second) {
    return jsonEncode(first.toJson()) == jsonEncode(second.toJson());
  }

  DateTime _recordDate(SyncRecord record) {
    return _date(record.values['updatedAt'] ?? record.values['createdAt']);
  }

  DateTime _date(Object? value) {
    return value is String
        ? DateTime.tryParse(value) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
        : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  String _string(Object? value) => value?.toString() ?? '';

  String? _optionalString(Object? value) {
    final string = value?.toString();
    return string == null || string.isEmpty ? null : string;
  }

  List<Object?> _decodeList(Object? value) {
    if (value is List) return List<Object?>.from(value);
    if (value is! String || value.isEmpty) return <Object?>[];
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? List<Object?>.from(decoded) : <Object?>[];
    } catch (_) {
      return <Object?>[];
    }
  }

  Map<String, Object?> _decodeMap(Object? value) {
    if (value is Map) return Map<String, Object?>.from(value);
    if (value is! String || value.isEmpty) return <String, Object?>{};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map
          ? Map<String, Object?>.from(decoded)
          : <String, Object?>{};
    } catch (_) {
      return <String, Object?>{};
    }
  }

  List<Object?> _list(Object? value) => value is List ? value : <Object?>[];

  Map<String, Object?> _map(Object? value) =>
      value is Map ? Map<String, Object?>.from(value) : <String, Object?>{};

  String _linkId(Map<String, Object?> row) =>
      '${_string(row['node_id'])}:${_string(row['material_id'])}:${_string(row['material_type'])}';
}
