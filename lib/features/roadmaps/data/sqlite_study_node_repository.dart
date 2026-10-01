import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_node.dart';
import 'study_node_repository.dart';

class SqliteStudyNodeRepository implements StudyNodeRepository {
  final Database database;

  SqliteStudyNodeRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<StudyNode>> getForTrack(String trackId) async {
    final rows = await database.query(
      'study_nodes',
      where: 'track_id = ?',
      whereArgs: [trackId],
      orderBy: 'sort_order ASC, rowid ASC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(StudyNode node) async {
    await database.insert('study_nodes', _toRow(node));
  }

  @override
  Future<void> update(StudyNode node) async {
    final changed = await database.update(
      'study_nodes',
      _toRow(node),
      where: 'id = ?',
      whereArgs: [node.id],
    );

    if (changed == 0) {
      throw StateError('Tópico não encontrado.');
    }
  }

  @override
  Future<void> delete(String nodeId) async {
    await database.delete('study_nodes', where: 'id = ?', whereArgs: [nodeId]);
  }

  Map<String, Object?> _toRow(StudyNode node) {
    final now = DateTime.now().toUtc();
    return {
      'id': node.id,
      'track_id': node.trackId,
      'parent_id': node.parentId,
      'title': node.title,
      'description': node.description,
      'sort_order': node.sortOrder,
      'is_completed': node.isCompleted ? 1 : 0,
      'notes': node.notes,
      'priority': node.priority.index,
      'created_at': (node.createdAt ?? now).toIso8601String(),
      'updated_at': (node.updatedAt ?? now).toIso8601String(),
    };
  }

  StudyNode _fromRow(Map<String, Object?> row) {
    return StudyNode(
      id: row['id']! as String,
      trackId: row['track_id']! as String,
      parentId: row['parent_id'] as String?,
      title: row['title']! as String,
      description: row['description']! as String,
      sortOrder: row['sort_order']! as int,
      isCompleted: row['is_completed'] == 1,
      notes: row['notes']! as String,
      priority: _priorityFromValue(row['priority']! as int),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }

  StudyPriority _priorityFromValue(int value) {
    if (value < 0 || value >= StudyPriority.values.length) {
      return StudyPriority.none;
    }

    return StudyPriority.values[value];
  }
}
