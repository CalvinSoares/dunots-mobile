import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_document.dart';
import 'study_document_repository.dart';

class SqliteStudyDocumentRepository implements StudyDocumentRepository {
  final Database database;

  SqliteStudyDocumentRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<StudyDocument>> getAll() async {
    final rows = await database.query(
      'study_documents',
      orderBy: 'updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(StudyDocument document) async {
    await database.insert('study_documents', _toRow(document));
  }

  @override
  Future<void> update(StudyDocument document) async {
    await database.update(
      'study_documents',
      _toRow(document)..remove('id'),
      where: 'id = ?',
      whereArgs: [document.id],
    );
  }

  @override
  Future<void> delete(String id) async {
    await database.delete('study_documents', where: 'id = ?', whereArgs: [id]);
  }

  Map<String, Object?> _toRow(StudyDocument document) => {
    'id': document.id,
    'title': document.title,
    'description': document.description,
    'file_name': document.fileName,
    'file_path': document.filePath,
    'mime_type': document.mimeType,
    'byte_size': document.byteSize,
    'imported_at': document.importedAt.toUtc().toIso8601String(),
    'updated_at': document.updatedAt.toUtc().toIso8601String(),
  };

  StudyDocument _fromRow(Map<String, Object?> row) => StudyDocument(
    id: row['id']! as String,
    title: row['title']! as String,
    description: (row['description'] as String?) ?? '',
    fileName: row['file_name']! as String,
    filePath: row['file_path']! as String,
    mimeType: row['mime_type']! as String,
    byteSize: row['byte_size']! as int,
    importedAt: DateTime.parse(row['imported_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );
}
