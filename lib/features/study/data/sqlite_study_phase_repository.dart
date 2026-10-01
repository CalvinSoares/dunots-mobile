import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_phase.dart';
import 'study_phase_repository.dart';

class SqliteStudyPhaseRepository implements StudyPhaseRepository {
  final Database database;

  SqliteStudyPhaseRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<StudyPhase>> getAll() async {
    final rows = await database.query(
      'study_phases',
      orderBy: 'sort_order ASC, updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(StudyPhase phase) async {
    await database.insert('study_phases', _toRow(phase));
  }

  @override
  Future<void> update(StudyPhase phase) async {
    final changed = await database.update(
      'study_phases',
      _toRow(phase),
      where: 'id = ?',
      whereArgs: [phase.id],
    );
    if (changed == 0) throw StateError('Fase de estudo não encontrada.');
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('study_phases', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> reorder(List<String> orderedIds) async {
    await database.transaction((transaction) async {
      for (var index = 0; index < orderedIds.length; index++) {
        await transaction.update(
          'study_phases',
          {'sort_order': index, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [orderedIds[index]],
        );
      }
    });
  }

  Map<String, Object?> _toRow(StudyPhase phase) {
    return {
      'id': phase.id,
      'title': phase.title,
      'description': phase.description,
      'flashcard_ids': jsonEncode(phase.flashcardIds),
      'problem_ids': jsonEncode(phase.challengeIds),
      'sort_order': phase.sortOrder,
      'created_at': phase.createdAt.toIso8601String(),
      'updated_at': phase.updatedAt.toIso8601String(),
    };
  }

  StudyPhase _fromRow(Map<String, Object?> row) {
    return StudyPhase(
      id: row['id']! as String,
      title: row['title']! as String,
      description: row['description'] as String? ?? '',
      flashcardIds: _decodeList(row['flashcard_ids']),
      challengeIds: _decodeList(row['problem_ids']),
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  List<String> _decodeList(Object? value) {
    if (value is String && value.isNotEmpty) {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.whereType<String>().toList();
    }
    return const [];
  }
}
