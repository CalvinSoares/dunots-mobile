import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_material.dart';
import '../domain/study_material_completion.dart';
import 'study_material_progress_repository.dart';

class SqliteStudyMaterialProgressRepository
    implements StudyMaterialProgressRepository {
  final Database database;

  SqliteStudyMaterialProgressRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<StudyMaterialCompletion>> getForNode(String nodeId) async {
    final rows = await database.query(
      'study_material_progress',
      where: 'node_id = ?',
      whereArgs: [nodeId],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<bool> isCompleted(StudyMaterialLink link) async {
    final rows = await database.query(
      'study_material_progress',
      columns: const ['node_id'],
      where: 'node_id = ? AND material_id = ? AND material_type = ?',
      whereArgs: [link.nodeId, link.materialId, link.materialType.name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  @override
  Future<void> markCompleted(
    StudyMaterialLink link, {
    DateTime? completedAt,
  }) async {
    final now = (completedAt ?? DateTime.now()).toUtc().toIso8601String();
    await database.insert('study_material_progress', {
      'node_id': link.nodeId,
      'material_id': link.materialId,
      'material_type': link.materialType.name,
      'completed_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteForNode(String nodeId) async {
    await database.delete(
      'study_material_progress',
      where: 'node_id = ?',
      whereArgs: [nodeId],
    );
  }

  StudyMaterialCompletion _fromRow(Map<String, Object?> row) {
    return StudyMaterialCompletion(
      nodeId: row['node_id']! as String,
      materialId: row['material_id']! as String,
      materialType: StudyMaterialType.values.firstWhere(
        (type) => type.name == row['material_type'],
        orElse: () => StudyMaterialType.document,
      ),
      completedAt: DateTime.parse(row['completed_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }
}
