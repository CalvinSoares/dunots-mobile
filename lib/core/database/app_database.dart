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
      version: 28,
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
            total_items INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT '',
            updated_at TEXT NOT NULL DEFAULT ''
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
            created_at TEXT NOT NULL DEFAULT '',
            updated_at TEXT NOT NULL DEFAULT '',
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
        await _createStudyDocumentsTable(database);
        await _createStudyMaterialProgressTable(database);
        await _createFlashcardsTable(database);
        await _createFlashcardSessionsTable(database);
        await _createFlashcardReviewPreferencesTable(database);
        await _createQuestionsTable(database);
        await _createQuizExamsTable(database);
        await _createQuizAttemptsTable(database);
        await _createChallengeTable(database);
        await _createChallengeReviewsTable(database);
        await _createChallengeReviewsTombstoneTrigger(database);
        await _createDiagramTable(database);
        await _createStudyPhasesTable(database);
        await _createSyncBackupsTable(database);
        await _createSyncTables(database);
        await _createStudyPhaseTombstoneTrigger(database);
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
        if (oldVersion < 19) {
          await database.execute(
            'ALTER TABLE flashcard_review_preferences '
            'ADD COLUMN weekly_goal INTEGER NOT NULL DEFAULT 100',
          );
        }
        if (oldVersion < 20) {
          await _createQuizExamsTable(database);
          await database.execute(
            'ALTER TABLE questions ADD COLUMN exam_id TEXT',
          );
          await database.execute(
            "ALTER TABLE questions ADD COLUMN subject TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            "ALTER TABLE questions ADD COLUMN notes TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            'ALTER TABLE questions ADD COLUMN source_name TEXT',
          );
          await database.execute(
            'ALTER TABLE questions ADD COLUMN source_page INTEGER',
          );
          await database.execute(
            'ALTER TABLE questions ADD COLUMN visual_image TEXT',
          );
          await database.execute(
            "ALTER TABLE questions ADD COLUMN visual_images TEXT NOT NULL DEFAULT '[]'",
          );
          await database.execute(
            "ALTER TABLE questions ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            'UPDATE questions SET updated_at = created_at WHERE updated_at = \'\'',
          );
          await database.execute(
            'CREATE INDEX IF NOT EXISTS questions_exam_index ON questions(exam_id)',
          );
        }
        if (oldVersion < 21) {
          await _createSyncTables(database);
        }
        if (oldVersion < 22) {
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN diagram_ids TEXT NOT NULL DEFAULT '[]'",
          );
          await database.execute(
            'ALTER TABLE flashcards ADD COLUMN interval INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute(
            'ALTER TABLE flashcards ADD COLUMN ease_factor REAL NOT NULL DEFAULT 2.5',
          );
          await database.execute(
            'ALTER TABLE flashcards ADD COLUMN repetitions INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute(
            "ALTER TABLE flashcards ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
          );
          await database.execute(
            "UPDATE flashcards SET updated_at = COALESCE(last_reviewed_at, created_at) WHERE updated_at = ''",
          );
          await _createChallengeTable(database);
          await _createDiagramTable(database);
          await _createSyncTables(database);
        }
        if (oldVersion < 23) {
          await _createChallengeReviewsTable(database);
          await _createChallengeReviewsTombstoneTrigger(database);
        }
        if (oldVersion < 24) {
          await _addColumnIfMissing(
            database,
            'flashcards',
            'language TEXT NOT NULL DEFAULT \'\'',
          );
          await _addColumnIfMissing(
            database,
            'flashcards',
            'quiz_question_id TEXT',
          );
          await _createStudyPhasesTable(database);
          await _createSyncBackupsTable(database);
          await _createSyncTables(database);
          await _createStudyPhaseTombstoneTrigger(database);
        }
        if (oldVersion < 25) {
          await _addColumnIfMissing(
            database,
            'study_phases',
            'sort_order INTEGER NOT NULL DEFAULT 0',
          );
          await database.execute(
            'CREATE INDEX IF NOT EXISTS study_phases_order_index '
            'ON study_phases(sort_order ASC, updated_at DESC)',
          );
        }
        if (oldVersion < 26) {
          await _addColumnIfMissing(
            database,
            'study_tracks',
            "created_at TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            database,
            'study_tracks',
            "updated_at TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            database,
            'study_nodes',
            "created_at TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            database,
            'study_nodes',
            "updated_at TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            database,
            'study_node_materials',
            "updated_at TEXT NOT NULL DEFAULT ''",
          );
          final timestamp = "strftime('%Y-%m-%dT%H:%M:%fZ', 'now')";
          await database.execute(
            "UPDATE study_tracks SET created_at = $timestamp, "
            "updated_at = $timestamp "
            "WHERE created_at = '' OR updated_at = ''",
          );
          await database.execute(
            "UPDATE study_nodes SET created_at = $timestamp, "
            "updated_at = $timestamp "
            "WHERE created_at = '' OR updated_at = ''",
          );
          await database.execute(
            "UPDATE study_node_materials SET updated_at = $timestamp "
            "WHERE updated_at = ''",
          );
        }
        if (oldVersion < 27) {
          await _createStudyDocumentsTable(database);
        }
        if (oldVersion < 28) {
          await _createStudyMaterialProgressTable(database);
        }
      },
    );

    return AppDatabase._(database);
  }

  Future<void> close() => database.close();

  static Future<void> _addColumnIfMissing(
    Database database,
    String table,
    String definition,
  ) async {
    final column = definition.split(' ').first;
    final columns = await database.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await database.execute('ALTER TABLE $table ADD COLUMN $definition');
  }

  static Future<void> _createMaterialLinksTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS study_node_materials (
        node_id TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_type TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT '',
        PRIMARY KEY (node_id, material_id, material_type),
        FOREIGN KEY (node_id) REFERENCES study_nodes(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<void> _createStudyDocumentsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS study_documents (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        mime_type TEXT NOT NULL,
        byte_size INTEGER NOT NULL DEFAULT 0,
        imported_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS study_documents_updated_index '
      'ON study_documents(updated_at DESC)',
    );
  }

  static Future<void> _createStudyMaterialProgressTable(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS study_material_progress (
        node_id TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_type TEXT NOT NULL,
        completed_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (node_id, material_id, material_type),
        FOREIGN KEY (node_id) REFERENCES study_nodes(id) ON DELETE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS study_material_progress_node_index '
      'ON study_material_progress(node_id, updated_at DESC)',
    );
  }

  static Future<void> _createFlashcardsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        code TEXT NOT NULL DEFAULT '',
        language TEXT NOT NULL DEFAULT '',
        quiz_question_id TEXT,
        tags TEXT NOT NULL DEFAULT '[]',
        linked_material_ids TEXT NOT NULL DEFAULT '[]',
        diagram_ids TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        due_at TEXT NOT NULL,
        last_reviewed_at TEXT,
        review_count INTEGER NOT NULL DEFAULT 0,
        last_rating TEXT,
        interval INTEGER NOT NULL DEFAULT 0,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        repetitions INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL DEFAULT ''
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
        weekly_goal INTEGER NOT NULL DEFAULT 100,
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
        exam_id TEXT,
        subject TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        source_name TEXT,
        source_page INTEGER,
        visual_image TEXT,
        visual_images TEXT NOT NULL DEFAULT '[]',
        updated_at TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS questions_number_index '
      'ON questions(question_number)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS questions_exam_index ON questions(exam_id)',
    );
  }

  static Future<void> _createQuizExamsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS quiz_exams (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        contest_name TEXT NOT NULL,
        vacancy TEXT NOT NULL,
        board TEXT,
        year INTEGER,
        proof_version TEXT,
        source_name TEXT,
        answer_key_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS quiz_exams_year_index ON quiz_exams(year)',
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

  static Future<void> _createSyncTables(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS sync_tombstones (
        id TEXT PRIMARY KEY,
        collection TEXT NOT NULL,
        record_id TEXT NOT NULL,
        deleted_at TEXT NOT NULL,
        deleted_by TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS sync_tombstones_collection_index '
      'ON sync_tombstones(collection, record_id)',
    );

    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_flashcards_delete',
      table: 'flashcards',
      collection: 'flashcards',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_quiz_exams_delete',
      table: 'quiz_exams',
      collection: 'quiz_exams',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_quiz_questions_delete',
      table: 'questions',
      collection: 'quiz_questions',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_quiz_attempts_delete',
      table: 'quiz_attempts',
      collection: 'quiz_attempts',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_challenges_delete',
      table: 'challenges',
      collection: 'leetcode_problems',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_diagrams_delete',
      table: 'diagrams',
      collection: 'diagrams',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_study_tracks_delete',
      table: 'study_tracks',
      collection: 'study_roadmaps',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_study_nodes_delete',
      table: 'study_nodes',
      collection: 'roadmap_nodes',
      idExpression: 'OLD.id',
    );
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_study_links_delete',
      table: 'study_node_materials',
      collection: 'roadmap_links',
      idExpression:
          "OLD.node_id || ':' || OLD.material_id || ':' || OLD.material_type",
    );
  }

  static Future<void> _createStudyPhaseTombstoneTrigger(
    Database database,
  ) async {
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_study_phases_delete',
      table: 'study_phases',
      collection: 'study_phases',
      idExpression: 'OLD.id',
    );
  }

  static Future<void> _createStudyPhasesTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS study_phases (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        flashcard_ids TEXT NOT NULL DEFAULT '[]',
        problem_ids TEXT NOT NULL DEFAULT '[]',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS study_phases_updated_index '
      'ON study_phases(updated_at DESC)',
    );
    await database.execute(
      'CREATE INDEX IF NOT EXISTS study_phases_order_index '
      'ON study_phases(sort_order ASC, updated_at DESC)',
    );
  }

  static Future<void> _createSyncBackupsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS sync_backups (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        payload TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS sync_backups_created_index '
      'ON sync_backups(created_at DESC)',
    );
  }

  static Future<void> _createChallengeTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS challenges (
        id TEXT PRIMARY KEY,
        problem_id TEXT NOT NULL,
        title TEXT NOT NULL,
        variant_name TEXT NOT NULL DEFAULT '',
        strategy TEXT NOT NULL DEFAULT '',
        url TEXT NOT NULL DEFAULT '',
        difficulty TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        complexity TEXT NOT NULL DEFAULT '',
        time_complexity TEXT NOT NULL DEFAULT '',
        space_complexity TEXT NOT NULL DEFAULT '',
        tradeoffs TEXT NOT NULL DEFAULT '',
        diagram_ids TEXT NOT NULL DEFAULT '[]',
        solution TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        solved_at TEXT,
        due_at TEXT,
        interval INTEGER NOT NULL DEFAULT 0,
        ease_factor REAL NOT NULL DEFAULT 2.5,
        repetitions INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS challenges_due_index ON challenges(due_at)',
    );
  }

  static Future<void> _createDiagramTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS diagrams (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        nodes TEXT NOT NULL DEFAULT '[]',
        edges TEXT NOT NULL DEFAULT '[]',
        phase_ids TEXT NOT NULL DEFAULT '[]',
        flashcard_ids TEXT NOT NULL DEFAULT '[]',
        problem_ids TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createChallengeReviewsTable(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS challenge_reviews (
        id TEXT PRIMARY KEY,
        challenge_id TEXT NOT NULL,
        rating TEXT NOT NULL,
        reviewed_at TEXT NOT NULL,
        previous_interval INTEGER NOT NULL DEFAULT 0,
        next_interval INTEGER NOT NULL DEFAULT 0,
        due_at TEXT NOT NULL,
        FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE
      )
    ''');
    await database.execute(
      'CREATE INDEX IF NOT EXISTS challenge_reviews_challenge_index '
      'ON challenge_reviews(challenge_id, reviewed_at DESC)',
    );
  }

  static Future<void> _createChallengeReviewsTombstoneTrigger(
    Database database,
  ) async {
    await _createSyncTombstoneTrigger(
      database,
      name: 'sync_challenge_reviews_delete',
      table: 'challenge_reviews',
      collection: 'challenge_reviews',
      idExpression: 'OLD.id',
    );
  }

  static Future<void> _createSyncTombstoneTrigger(
    Database database, {
    required String name,
    required String table,
    required String collection,
    required String idExpression,
  }) async {
    await database.execute('''
      CREATE TRIGGER IF NOT EXISTS $name
      AFTER DELETE ON $table
      BEGIN
        INSERT OR REPLACE INTO sync_tombstones
          (id, collection, record_id, deleted_at, deleted_by)
        VALUES
          ('$collection:' || ($idExpression), '$collection', ($idExpression),
           CURRENT_TIMESTAMP, 'local');
      END
    ''');
  }
}
