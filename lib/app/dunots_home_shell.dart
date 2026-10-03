import 'package:flutter/material.dart';

import '../features/flashcards/data/flashcard_repository.dart';
import '../features/flashcards/data/flashcard_review_preferences_repository.dart';
import '../features/flashcards/data/flashcard_session_repository.dart';
import '../features/questions/data/question_repository.dart';
import '../features/questions/data/quiz_exam_repository.dart';
import '../features/questions/questions_preview_page.dart';
import '../features/quizzes/data/quiz_attempt_repository.dart';
import '../features/roadmaps/data/study_node_repository.dart';
import '../features/roadmaps/data/study_material_repository.dart';
import '../features/roadmaps/data/study_document_repository.dart';
import '../features/roadmaps/data/study_material_progress_repository.dart';
import '../features/roadmaps/data/study_track_repository.dart';
import '../features/roadmaps/roadmaps_preview_page.dart';
import '../features/today/today_page.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/sync/sync_database_repository.dart';
import '../core/sync/sync_dialog.dart';
import '../features/study/data/study_phase_repository.dart';
import '../features/study/study_hub_page.dart';
import '../shared/widgets/dunots_app_header.dart';
import '../shared/widgets/dunots_bottom_navigation.dart';
import '../shared/widgets/dunots_modal.dart';

class DunotsHomeShell extends StatefulWidget {
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
  final StudyPhaseRepository? phaseRepository;
  final StudyDocumentRepository? documentRepository;
  final StudyMaterialProgressRepository? materialProgressRepository;

  const DunotsHomeShell({
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
    this.phaseRepository,
    this.documentRepository,
    this.materialProgressRepository,
  });

  @override
  State<DunotsHomeShell> createState() => _DunotsHomeShellState();
}

class _DunotsHomeShellState extends State<DunotsHomeShell> {
  static const wideLayoutBreakpoint = 840.0;
  int selectedIndex = 0;
  late final List<Widget> pages;
  final _appHeaderKey = GlobalKey<DunotsAppHeaderState>();

  @override
  void initState() {
    super.initState();
    pages = [
      TodayPage(
        showHeader: false,
        flashcardRepository: widget.flashcardRepository,
        flashcardSessionRepository: widget.flashcardSessionRepository,
        flashcardReviewPreferencesRepository:
            widget.flashcardReviewPreferencesRepository,
        trackRepository: widget.trackRepository,
        attemptRepository: widget.attemptRepository,
        phaseRepository: widget.phaseRepository,
        localNotificationService: widget.localNotificationService,
        onOpenFlashcards: () => _openStudyTab(0),
        onOpenTracks: () => _selectTab(3),
      ),
      StudyHubPage(
        showHeader: false,
        flashcardRepository: widget.flashcardRepository,
        flashcardSessionRepository: widget.flashcardSessionRepository,
        flashcardReviewPreferencesRepository:
            widget.flashcardReviewPreferencesRepository,
        questionRepository: widget.questionRepository,
      ),
      QuestionsPreviewPage(
        showHeader: false,
        repository: widget.questionRepository,
        examRepository: widget.examRepository,
        attemptRepository: widget.attemptRepository,
      ),
      RoadmapsPreviewPage(
        showHeader: false,
        repository: widget.trackRepository,
        nodeRepository: widget.nodeRepository,
        materialLinkRepository: widget.materialLinkRepository,
        flashcardRepository: widget.flashcardRepository,
        questionRepository: widget.questionRepository,
        attemptRepository: widget.attemptRepository,
        documentRepository: widget.documentRepository,
        materialProgressRepository: widget.materialProgressRepository,
      ),
    ];
  }

  void _selectTab(int index) {
    if (!mounted) return;
    setState(() => selectedIndex = index);
  }

  void _openStudyTab(int tabIndex) {
    if (tabIndex == 0) {
      _selectTab(1);
      _appHeaderKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideLayout =
        MediaQuery.sizeOf(context).width >= wideLayoutBreakpoint;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (isWideLayout) _buildNavigationRail(),
            Expanded(
              child: Column(
                children: [
                  DunotsAppHeader(
                    key: _appHeaderKey,
                    icon: _pageHeaders[selectedIndex].$1,
                    title: _pageHeaders[selectedIndex].$2,
                    flashcardRepository: widget.flashcardRepository,
                    flashcardSessionRepository:
                        widget.flashcardSessionRepository,
                    flashcardReviewPreferencesRepository:
                        widget.flashcardReviewPreferencesRepository,
                    localNotificationService: widget.localNotificationService,
                    onOpenFlashcards: () => _openStudyTab(0),
                    onOpenSync: widget.syncRepository == null
                        ? null
                        : _openSync,
                  ),
                  Expanded(
                    child: IndexedStack(index: selectedIndex, children: pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWideLayout
          ? null
          : DunotsBottomNavigation(
              selectedIndex: selectedIndex,
              onSelected: _selectTab,
            ),
    );
  }

  Future<void> _openSync() async {
    final repository = widget.syncRepository;
    if (!mounted) return;
    if (repository == null) {
      await showDunotsDrawer<void>(
        context: context,
        builder: (dialogContext) => DunotsModal(
          title: 'Sincronização indisponível',
          icon: Icons.sync_problem_outlined,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
          child: const Text(
            'A sincronização ainda não foi configurada neste ambiente.',
          ),
        ),
      );
      return;
    }
    await showDunotsDrawer<void>(
      context: context,
      builder: (_) => SyncDialog(repository: repository),
    );
  }

  NavigationRail _buildNavigationRail() {
    final isExtended = MediaQuery.sizeOf(context).width >= 1080;
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: _selectTab,
      extended: isExtended,
      groupAlignment: -0.85,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 28),
        child: Icon(
          Icons.edit_note_rounded,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
      ),
      destinations: _railDestinations,
    );
  }

  static const _pageHeaders = [
    (Icons.today_outlined, 'Hoje'),
    (Icons.style_outlined, 'Flashcards'),
    (Icons.quiz_outlined, 'Questões'),
    (Icons.route_outlined, 'Minhas trilhas'),
  ];

  static const _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: Text('Hoje'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style),
      label: Text('Estudar'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: Text('Questões'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: Text('Trilhas'),
    ),
  ];
}
