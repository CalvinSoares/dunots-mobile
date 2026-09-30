import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/challenge.dart';
import 'challenge_repository.dart';

class SqliteChallengeRepository implements ChallengeRepository {
  final Database database;

  SqliteChallengeRepository(AppDatabase appDatabase)
    : database = appDatabase.database;

  @override
  Future<List<Challenge>> getAll() async {
    final rows = await database.query('challenges', orderBy: 'updated_at DESC');
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(Challenge challenge) async =>
      database.insert('challenges', _toRow(challenge));

  @override
  Future<void> update(Challenge challenge) async {
    final changed = await database.update(
      'challenges',
      _toRow(challenge)..remove('id'),
      where: 'id = ?',
      whereArgs: [challenge.id],
    );
    if (changed == 0) throw StateError('Desafio não encontrado.');
  }

  @override
  Future<void> delete(String id) async =>
      database.delete('challenges', where: 'id = ?', whereArgs: [id]);

  Map<String, Object?> _toRow(Challenge item) => {
    'id': item.id,
    'problem_id': item.problemId,
    'title': item.title,
    'variant_name': item.variantName,
    'strategy': item.strategy,
    'url': item.url,
    'difficulty': item.difficulty.name,
    'tags': jsonEncode(item.tags),
    'complexity': item.complexity,
    'time_complexity': item.timeComplexity,
    'space_complexity': item.spaceComplexity,
    'tradeoffs': item.tradeoffs,
    'diagram_ids': jsonEncode(item.diagramIds),
    'solution': item.solution,
    'notes': item.notes,
    'solved_at': item.solvedAt?.toIso8601String(),
    'due_at': item.dueAt?.toIso8601String(),
    'interval': item.interval,
    'ease_factor': item.easeFactor,
    'repetitions': item.repetitions,
    'created_at': item.createdAt.toIso8601String(),
    'updated_at': item.updatedAt.toIso8601String(),
  };

  Challenge _fromRow(Map<String, Object?> row) => Challenge(
    id: row['id']! as String,
    problemId: row['problem_id'] as String? ?? '',
    title: row['title']! as String,
    variantName: row['variant_name'] as String? ?? '',
    strategy: row['strategy'] as String? ?? '',
    url: row['url'] as String? ?? '',
    difficulty: ChallengeDifficulty.values.firstWhere(
      (item) => item.name == row['difficulty'],
      orElse: () => ChallengeDifficulty.medium,
    ),
    tags: _list(row['tags']),
    complexity: row['complexity'] as String? ?? '',
    timeComplexity: row['time_complexity'] as String? ?? '',
    spaceComplexity: row['space_complexity'] as String? ?? '',
    tradeoffs: row['tradeoffs'] as String? ?? '',
    diagramIds: _list(row['diagram_ids']),
    solution: row['solution'] as String? ?? '',
    notes: row['notes'] as String? ?? '',
    solvedAt: _date(row['solved_at']),
    dueAt: _date(row['due_at']),
    interval: row['interval'] as int? ?? 0,
    easeFactor: (row['ease_factor'] as num?)?.toDouble() ?? 2.5,
    repetitions: row['repetitions'] as int? ?? 0,
    createdAt: DateTime.parse(row['created_at']! as String),
    updatedAt: DateTime.parse(row['updated_at']! as String),
  );

  List<String> _list(Object? value) {
    if (value is! String || value.isEmpty) return const [];
    final decoded = jsonDecode(value);
    return decoded is List
        ? decoded.map((item) => item.toString()).toList(growable: false)
        : const [];
  }

  DateTime? _date(Object? value) =>
      value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}
