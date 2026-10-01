import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_track.dart';
import 'study_track_repository.dart';

class SqliteStudyTrackRepository implements StudyTrackRepository {
  final Database database;

  SqliteStudyTrackRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<StudyTrack>> getAll() async {
    final rows = await database.query('study_tracks', orderBy: 'rowid ASC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(StudyTrack track) async {
    await database.insert('study_tracks', _toRow(track));
  }

  @override
  Future<void> update(StudyTrack track) async {
    final changed = await database.update(
      'study_tracks',
      _toRow(track),
      where: 'id = ?',
      whereArgs: [track.id],
    );

    if (changed == 0) {
      throw StateError('Trilha não encontrada.');
    }
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('study_tracks', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(StudyTrack track) {
    final now = DateTime.now().toUtc();
    return {
      'id': track.id,
      'title': track.title,
      'description': track.description,
      'completed_items': track.completedItems,
      'total_items': track.totalItems,
      'created_at': (track.createdAt ?? now).toIso8601String(),
      'updated_at': (track.updatedAt ?? now).toIso8601String(),
    };
  }

  StudyTrack _fromRow(Map<String, Object?> row) {
    return StudyTrack(
      id: row['id']! as String,
      title: row['title']! as String,
      description: row['description']! as String,
      completedItems: row['completed_items']! as int,
      totalItems: row['total_items']! as int,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
    );
  }
}
