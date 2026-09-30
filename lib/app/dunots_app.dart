import 'package:flutter/material.dart';

import '../features/flashcards/data/flashcard_repository.dart';
import '../features/flashcards/data/flashcard_review_preferences_repository.dart';
import '../features/flashcards/data/flashcard_session_repository.dart';
import '../features/questions/data/question_repository.dart';
import '../features/questions/data/quiz_exam_repository.dart';
import '../features/quizzes/data/quiz_attempt_repository.dart';
import '../features/roadmaps/data/study_node_repository.dart';
import '../features/roadmaps/data/study_material_repository.dart';
import '../features/roadmaps/data/study_track_repository.dart';
import '../features/challenges/data/challenge_repository.dart';
import '../features/diagrams/data/diagram_repository.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/sync/sync_database_repository.dart';
import 'dunots_theme.dart';
import 'dunots_home_shell.dart';

class DunotsMobileApp extends StatelessWidget {
  final StudyTrackRepository? trackRepository;
  final StudyNodeRepository? nodeRepository;
  final StudyNodeMaterialRepository? materialLinkRepository;
  final FlashcardRepository? flashcardRepository;
  final FlashcardSessionRepository? flashcardSessionRepository;
  final FlashcardReviewPreferencesRepository?
  flashcardReviewPreferencesRepository;
  final QuestionRepository? questionRepository;
  final QuizExamRepository? examRepository;
  final QuizAttemptRepository? attemptRepository;
  final LocalNotificationService? localNotificationService;
  final SyncDatabaseRepository? syncRepository;
  final ChallengeRepository? challengeRepository;
  final DiagramRepository? diagramRepository;

  const DunotsMobileApp({
    super.key,
    this.trackRepository,
    this.nodeRepository,
    this.materialLinkRepository,
    this.flashcardRepository,
    this.flashcardSessionRepository,
    this.flashcardReviewPreferencesRepository,
    this.questionRepository,
    this.examRepository,
    this.attemptRepository,
    this.localNotificationService,
    this.syncRepository,
    this.challengeRepository,
    this.diagramRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dunots',
      debugShowCheckedModeBanner: false,
      theme: buildDunotsTheme(),
      home: DunotsHomeShell(
        trackRepository: trackRepository,
        nodeRepository: nodeRepository,
        materialLinkRepository: materialLinkRepository,
        flashcardRepository: flashcardRepository,
        flashcardSessionRepository: flashcardSessionRepository,
        flashcardReviewPreferencesRepository:
            flashcardReviewPreferencesRepository,
        questionRepository: questionRepository,
        examRepository: examRepository,
        attemptRepository: attemptRepository,
        localNotificationService: localNotificationService,
        syncRepository: syncRepository,
        challengeRepository: challengeRepository,
        diagramRepository: diagramRepository,
      ),
    );
  }
}
