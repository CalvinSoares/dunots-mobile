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
      version: 18,
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
        await _createMaterialLinksTable(database);
        await _createFlashcardsTable(database);
        await _createFlashcardSessionsTable(database);
        await _createFlashcardReviewPreferencesTable(database);
        await _createQuestionsTable(database);
        await _createQuizAttemptsTable(database);
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
        if (oldVersion < 4) {
          await _createMaterialLinksTable(database);
        }
        if (oldVersion < 5) {
          await _createFlashcardsTable(database);
        }
        if (oldVersion < 6) {
          await _createQuestionsTable(database);
        }
        if (oldVersion < 7) {
          await _createQuizAttemptsTable(database);
        }
        if (oldVersion < 8) {
          await database.execute(
            "ALTER TABLE questions ADD COLUMN topic TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 9) {
          await database.execute(
            "ALTER TABLE questions ADD COLUMN exam TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 10) {
          await database.execute(
            "ALTER TABLE quiz_attempts ADD COLUMN review_question_ids TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 11) {
          await database.execute(
            "ALTER TABLE quiz_attempts ADD COLUMN review_notes TEXT NOT NULL DEFAULT '{}'",
          );
        }
        if (oldVersion < 12) {
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN due_at TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            'ALTER TABLE flashcards ADD COLUMN last_reviewed_at TEXT',
          );
          await database.execute(
            'ALTER TABLE flashcards ADD COLUMN review_count INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN last_rating TEXT",
          );
          await database.execute(
            "UPDATE flashcards SET due_at = created_at WHERE due_at = ''",
          );
        }
        if (oldVersion < 13) {
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN code TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 14) {
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN linked_material_ids TEXT NOT NULL DEFAULT '[]'",
          );
        }
        if (oldVersion < 15) {
          await _createFlashcardSessionsTable(database);
        }
        if (oldVersion < 16) {
          await _createFlashcardReviewPreferencesTable(database);
        }
        if (oldVersion < 17) {
          await database.execute(
            'ALTER TABLE flashcard_review_preferences '
            'ADD COLUMN daily_goal INTEGER NOT NULL DEFAULT 20',
          );
        }
        if (oldVersion < 18) {
          await database.execute(
            'ALTER TABLE flashcard_review_preferences '
            'ADD COLUMN reminder_enabled INTEGER NOT NULL DEFAULT 1',
          );
          await database.execute(
            'ALTER TABLE flashcard_review_preferences '
            'ADD COLUMN reminder_hour INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute(
            'ALTER TABLE flashcard_review_preferences '
            'ADD COLUMN reminder_minute INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );

    return AppDatabase._(database);
  }

  Future<void> close() => database.close();

  static Future<void> _createMaterialLinksTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS study_node_materials (
        node_id TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_type TEXT NOT NULL,
        PRIMARY KEY (node_id, material_id, material_type),
        FOREIGN KEY (node_id) REFERENCES study_nodes(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createFlashcardsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        code TEXT NOT NULL DEFAULT '',
        tags TEXT NOT NULL DEFAULT '[]',
        linked_material_ids TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        due_at TEXT NOT NULL,
        last_reviewed_at TEXT,
        review_count INTEGER NOT NULL DEFAULT 0,
        last_rating TEXT
      )
    ''');
  }

  static Future<void> _createFlashcardSessionsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS flashcard_sessions (
        id TEXT PRIMARY KEY,
        started_at TEXT NOT NULL,
        finished_at TEXT NOT NULL,
        card_count INTEGER NOT NULL,
        difficult_count INTEGER NOT NULL DEFAULT 0,
        good_count INTEGER NOT NULL DEFAULT 0,
        easy_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS flashcard_sessions_finished_index '
      'ON flashcard_sessions(finished_at)',
    );
  }

  static Future<void> _createFlashcardReviewPreferencesTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS flashcard_review_preferences (
        id INTEGER PRIMARY KEY,
        daily_limit INTEGER NOT NULL DEFAULT 20,
        daily_goal INTEGER NOT NULL DEFAULT 20,
        sort TEXT NOT NULL DEFAULT 'due',
        prefer_recommended INTEGER NOT NULL DEFAULT 0,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_hour INTEGER NOT NULL DEFAULT 0,
        reminder_minute INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _createQuestionsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS questions (
        id TEXT PRIMARY KEY,
        question_number INTEGER,
        statement TEXT NOT NULL,
        alternatives TEXT NOT NULL,
        correct_alternative_index INTEGER NOT NULL,
        explanation TEXT NOT NULL,
        contest TEXT NOT NULL,
        role TEXT NOT NULL,
        topic TEXT NOT NULL DEFAULT '',
        exam TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS questions_number_index '
      'ON questions(question_number)',
    );
  }

  static Future<void> _createQuizAttemptsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS quiz_attempts (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        question_ids TEXT NOT NULL,
        current_index INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        answers TEXT NOT NULL,
        review_question_ids TEXT NOT NULL DEFAULT '[]',
        review_notes TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS quiz_attempts_status_index '
      'ON quiz_attempts(status)',
    );
  }
}
