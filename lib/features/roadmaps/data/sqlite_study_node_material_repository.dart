import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_material.dart';
import 'study_material_repository.dart';

class SqliteStudyNodeMaterialRepository implements StudyNodeMaterialRepository {
  final Database database;

  SqliteStudyNodeMaterialRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<StudyMaterialLink>> getForNode(String nodeId) async {
    final rows = await database.query(
      'study_node_materials',
      where: 'node_id = ?',
      whereArgs: [nodeId],
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> replaceForNode(
    String nodeId,
    List<StudyMaterialLink> links,
  ) async {
    await database.transaction((transaction) async {
      await transaction.delete(
        'study_node_materials',
        where: 'node_id = ?',
        whereArgs: [nodeId],
      );

      for (final link in links) {
        await transaction.insert('study_node_materials', _toRow(link));
      }
    });
  }

  @override
  Future<void> deleteForNode(String nodeId) async {
    await database.delete(
      'study_node_materials',
      where: 'node_id = ?',
      whereArgs: [nodeId],
    );
  }

  Map<String, Object?> _toRow(StudyMaterialLink link) {
    return {
      'node_id': link.nodeId,
      'material_id': link.materialId,
      'material_type': link.materialType.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  StudyMaterialLink _fromRow(Map<String, Object?> row) {
    return StudyMaterialLink(
      nodeId: row['node_id']! as String,
      materialId: row['material_id']! as String,
      materialType: StudyMaterialType.values.firstWhere(
        (type) => type.name == row['material_type'],
        orElse: () => StudyMaterialType.document,
      ),
    );
  }
}
