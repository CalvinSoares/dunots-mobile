import 'package:flutter/material.dart';

import '../features/flashcards/data/flashcard_repository.dart';
import '../features/flashcards/data/flashcard_review_preferences_repository.dart';
import '../features/flashcards/data/flashcard_session_repository.dart';
import '../features/questions/data/question_repository.dart';
import '../features/questions/questions_preview_page.dart';
import '../features/quizzes/data/quiz_attempt_repository.dart';
import '../features/flashcards/flashcards_preview_page.dart';
import '../features/more/more_page.dart';
import '../features/roadmaps/data/study_node_repository.dart';
import '../features/roadmaps/data/study_material_repository.dart';
import '../features/roadmaps/data/study_track_repository.dart';
import '../features/roadmaps/roadmaps_preview_page.dart';
import '../features/today/today_page.dart';

class DunotsHomeShell extends StatefulWidget {
  final StudyTrackRepository? trackRepository;
  final StudyNodeRepository? nodeRepository;
  final StudyNodeMaterialRepository? materialLinkRepository;
  final FlashcardRepository? flashcardRepository;
  final FlashcardSessionRepository? flashcardSessionRepository;
  final FlashcardReviewPreferencesRepository?
  flashcardReviewPreferencesRepository;
  final QuestionRepository? questionRepository;
  final QuizAttemptRepository? attemptRepository;

  const DunotsHomeShell({
    super.key,
    this.trackRepository,
    this.nodeRepository,
    this.materialLinkRepository,
    this.flashcardRepository,
    this.flashcardSessionRepository,
    this.flashcardReviewPreferencesRepository,
    this.questionRepository,
    this.attemptRepository,
  });

  @override
  State<DunotsHomeShell> createState() => _DunotsHomeShellState();
}

class _DunotsHomeShellState extends State<DunotsHomeShell> {
  static const wideLayoutBreakpoint = 840.0;
  int selectedIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      TodayPage(
        flashcardRepository: widget.flashcardRepository,
        flashcardSessionRepository: widget.flashcardSessionRepository,
        flashcardReviewPreferencesRepository:
            widget.flashcardReviewPreferencesRepository,
        trackRepository: widget.trackRepository,
        questionRepository: widget.questionRepository,
        attemptRepository: widget.attemptRepository,
        onOpenFlashcards: () => _selectTab(1),
        onOpenQuestions: () => _selectTab(2),
      ),
      FlashcardsPreviewPage(
        repository: widget.flashcardRepository,
        questionRepository: widget.questionRepository,
        sessionRepository: widget.flashcardSessionRepository,
        preferencesRepository: widget.flashcardReviewPreferencesRepository,
      ),
      QuestionsPreviewPage(
        repository: widget.questionRepository,
        attemptRepository: widget.attemptRepository,
      ),
      RoadmapsPreviewPage(
        repository: widget.trackRepository,
        nodeRepository: widget.nodeRepository,
        materialLinkRepository: widget.materialLinkRepository,
        flashcardRepository: widget.flashcardRepository,
        questionRepository: widget.questionRepository,
        attemptRepository: widget.attemptRepository,
      ),
      const MorePage(),
    ];
  }

  void _selectTab(int index) {
    if (!mounted) return;
    setState(() => selectedIndex = index);
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
              child: IndexedStack(index: selectedIndex, children: pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWideLayout ? null : _buildNavigationBar(),
    );
  }

  NavigationBar _buildNavigationBar() {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: _selectTab,
      destinations: _navigationDestinations,
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

  static const _navigationDestinations = [
    NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Hoje',
    ),
    NavigationDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style),
      label: 'Cards',
    ),
    NavigationDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: 'Questões',
    ),
    NavigationDestination(
      icon: Icon(Icons.route_outlined),
      selectedIcon: Icon(Icons.route),
      label: 'Trilhas',
    ),
    NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
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
      label: Text('Cards'),
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
    NavigationRailDestination(
      icon: Icon(Icons.more_horiz),
      label: Text('Mais'),
    ),
  ];
}
