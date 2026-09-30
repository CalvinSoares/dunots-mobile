import 'package:flutter/material.dart';

import '../features/flashcards/data/flashcard_repository.dart';
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

  const DunotsHomeShell({
    super.key,
    this.trackRepository,
    this.nodeRepository,
    this.materialLinkRepository,
    this.flashcardRepository,
  });

  @override
  State<DunotsHomeShell> createState() => _DunotsHomeShellState();
}

class _DunotsHomeShellState extends State<DunotsHomeShell> {
  int selectedIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const TodayPage(),
      FlashcardsPreviewPage(repository: widget.flashcardRepository),
      RoadmapsPreviewPage(
        repository: widget.trackRepository,
        nodeRepository: widget.nodeRepository,
        materialLinkRepository: widget.materialLinkRepository,
        flashcardRepository: widget.flashcardRepository,
      ),
      const MorePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
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
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trilhas',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}
