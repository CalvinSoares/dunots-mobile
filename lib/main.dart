import 'core/database/app_database.dart';

import 'package:dunots_mobile/app/dunots_app.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_session_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_demo_data.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_track_repository.dart';
import 'package:dunots_mobile/features/questions/data/sqlite_question_repository.dart';
import 'package:dunots_mobile/features/questions/question_demo_data.dart';
import 'package:dunots_mobile/features/quizzes/data/sqlite_quiz_attempt_repository.dart';
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
  final questionRepository = SqliteQuestionRepository(database);
  if ((await questionRepository.getAll()).isEmpty) {
    for (final question in demoQuestions) {
      await questionRepository.create(question);
    }
  }
  final attemptRepository = SqliteQuizAttemptRepository(database);
  final sessionRepository = SqliteFlashcardSessionRepository(database);

  runApp(
    DunotsMobileApp(
      trackRepository: SqliteStudyTrackRepository(database),
      nodeRepository: SqliteStudyNodeRepository(database),
      materialLinkRepository: SqliteStudyNodeMaterialRepository(database),
      flashcardRepository: flashcardRepository,
      flashcardSessionRepository: sessionRepository,
      questionRepository: questionRepository,
      attemptRepository: attemptRepository,
    ),
  );
}
