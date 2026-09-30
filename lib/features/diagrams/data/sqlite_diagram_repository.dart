import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/study_diagram.dart';
import 'diagram_repository.dart';

class SqliteDiagramRepository implements DiagramRepository {
  final Database database;
  SqliteDiagramRepository(AppDatabase appDatabase)
    : database = appDatabase.database;
  @override
  Future<List<StudyDiagram>> getAll() async => (await database.query(
    'diagrams',
    orderBy: 'updated_at DESC',
  )).map(_fromRow).toList(growable: false);
  @override
  Future<void> create(StudyDiagram diagram) async =>
      database.insert('diagrams', _toRow(diagram));
  @override
  Future<void> update(StudyDiagram diagram) async {
    final changed = await database.update(
      'diagrams',
      _toRow(diagram)..remove('id'),
      where: 'id = ?',
      whereArgs: [diagram.id],
    );
    if (changed == 0) throw StateError('Fluxograma não encontrado.');
  }

  @override
  Future<void> delete(String id) async =>
      database.delete('diagrams', where: 'id = ?', whereArgs: [id]);
  Map<String, Object?> _toRow(StudyDiagram item) => {
    'id': item.id,
    'title': item.title,
    'description': item.description,
    'nodes': jsonEncode(item.nodes),
    'edges': jsonEncode(item.edges),
    'phase_ids': jsonEncode(item.phaseIds),
    'flashcard_ids': jsonEncode(item.flashcardIds),
    'problem_ids': jsonEncode(item.problemIds),
    'created_at': item.createdAt.toIso8601String(),
    'updated_at': item.updatedAt.toIso8601String(),
  };
  StudyDiagram _fromRow(Map<String, Object?> row) => StudyDiagram(
    id: row['id']! as String,
    title: row['title']! as String,
    description: row['description'] as String? ?? '',
    nodes: _maps(row['nodes']),
    edges: _maps(row['edges']),
    phaseIds: _strings(row['phase_ids']),
    flashcardIds: _strings(row['flashcard_ids']),
    problemIds: _strings(row['problem_ids']),
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );
  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    final decoded = jsonDecode(value);
    return decoded is List
        ? decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
        : const [];
  }

  List<String> _strings(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    final decoded = jsonDecode(value);
    return decoded is List
        ? decoded.map((item) => item.toString()).toList(growable: false)
        : const [];
  }
}
