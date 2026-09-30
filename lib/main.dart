import 'core/database/app_database.dart';

import 'package:dunots_mobile/app/dunots_app.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_demo_data.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_track_repository.dart';
import 'package:flutter/material.dart';

export 'app/dunots_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await AppDatabase.open();
  final flashcardRepository = SqliteFlashcardRepository(database);
  if ((await flashcardRepository.getAll()).isEmpty) {
    for (final card in demoFlashcards) {
      await flashcardRepository.create(card);
    }
  }

  runApp(
    DunotsMobileApp(
      trackRepository: SqliteStudyTrackRepository(database),
      nodeRepository: SqliteStudyNodeRepository(database),
      materialLinkRepository: SqliteStudyNodeMaterialRepository(database),
      flashcardRepository: flashcardRepository,
    ),
  );
}
