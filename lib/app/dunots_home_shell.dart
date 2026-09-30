import 'package:flutter/material.dart';

import '../features/flashcards/flashcards_preview_page.dart';
import '../features/more/more_page.dart';
import '../features/roadmaps/roadmaps_preview_page.dart';
import '../features/today/today_page.dart';

class DunotsHomeShell extends StatefulWidget {
  const DunotsHomeShell({super.key});

  @override
  State<DunotsHomeShell> createState() => _DunotsHomeShellState();
}

class _DunotsHomeShellState extends State<DunotsHomeShell> {
  int selectedIndex = 0;

  static const pages = <Widget>[
    TodayPage(),
    FlashcardsPreviewPage(),
    RoadmapsPreviewPage(),
    MorePage(),
  ];

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
