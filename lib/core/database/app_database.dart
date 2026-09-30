import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  final Database database;

  const AppDatabase._(this.database);

  static Future<AppDatabase> open({String? databasePathOverride}) async {
    final databasePath =
        databasePathOverride ??
        path.join(await getDatabasesPath(), 'dunots.db');
    final database = await openDatabase(
      databasePath,
      version: 3,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE study_tracks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            completed_items INTEGER NOT NULL DEFAULT 0,
            total_items INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await database.execute('''
          CREATE TABLE study_nodes (
            id TEXT PRIMARY KEY,
            track_id TEXT NOT NULL,
            parent_id TEXT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            sort_order INTEGER NOT NULL DEFAULT 0,
            is_completed INTEGER NOT NULL DEFAULT 0,
            notes TEXT NOT NULL DEFAULT '',
            priority INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (track_id) REFERENCES study_tracks(id) ON DELETE CASCADE,
            FOREIGN KEY (parent_id) REFERENCES study_nodes(id) ON DELETE CASCADE
          )
        ''');
        await database.execute(
          'CREATE INDEX study_nodes_track_index ON study_nodes(track_id)',
        );
        await database.execute(
          'CREATE INDEX study_nodes_parent_index ON study_nodes(parent_id)',
        );
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute(
            'ALTER TABLE study_nodes ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0',
          );
        }
        if (oldVersion < 3) {
          await database.execute(
            "ALTER TABLE study_nodes ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            'ALTER TABLE study_nodes ADD COLUMN priority INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );

    return AppDatabase._(database);
  }

  Future<void> close() => database.close();
}
