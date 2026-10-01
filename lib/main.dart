import 'core/database/app_database.dart';

import 'package:dunots_mobile/core/notifications/local_notification_service.dart';

import 'package:dunots_mobile/app/dunots_app.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_review_preferences_repository.dart';
import 'package:dunots_mobile/features/flashcards/data/sqlite_flashcard_session_repository.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_demo_data.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_document_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_material_progress_repository.dart';
import 'package:dunots_mobile/features/questions/data/sqlite_question_repository.dart';
import 'package:dunots_mobile/features/questions/data/sqlite_quiz_exam_repository.dart';
import 'package:dunots_mobile/features/questions/question_demo_data.dart';
import 'package:dunots_mobile/features/quizzes/data/sqlite_quiz_attempt_repository.dart';
import 'package:flutter/material.dart';

import 'core/sync/sync_database_repository.dart';
import 'features/challenges/data/sqlite_challenge_repository.dart';
import 'features/diagrams/data/sqlite_diagram_repository.dart';
import 'features/study/data/sqlite_study_phase_repository.dart';

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
  final examRepository = SqliteQuizExamRepository(database);
  if ((await questionRepository.getAll()).isEmpty) {
    for (final question in demoQuestions) {
      await questionRepository.create(question);
    }
  }
  final attemptRepository = SqliteQuizAttemptRepository(database);
  final sessionRepository = SqliteFlashcardSessionRepository(database);
  final reviewPreferencesRepository =
      SqliteFlashcardReviewPreferencesRepository(database);
  final notificationService = FlutterLocalNotificationService();
  try {
    await notificationService.initialize();
    await notificationService.requestPermission();
  } catch (_) {
    // O app continua utilizável se o sistema bloquear notificações ou timezone.
  }

  runApp(
    DunotsMobileApp(
      trackRepository: SqliteStudyTrackRepository(database),
      nodeRepository: SqliteStudyNodeRepository(database),
      materialLinkRepository: SqliteStudyNodeMaterialRepository(database),
      flashcardRepository: flashcardRepository,
      flashcardSessionRepository: sessionRepository,
      flashcardReviewPreferencesRepository: reviewPreferencesRepository,
      questionRepository: questionRepository,
      examRepository: examRepository,
      attemptRepository: attemptRepository,
      syncRepository: SyncDatabaseRepository(database.database),
      challengeRepository: SqliteChallengeRepository(database),
      diagramRepository: SqliteDiagramRepository(database),
      phaseRepository: SqliteStudyPhaseRepository(database),
      documentRepository: SqliteStudyDocumentRepository(database),
      materialProgressRepository: SqliteStudyMaterialProgressRepository(
        database,
      ),
      localNotificationService: notificationService,
    ),
  );
}
