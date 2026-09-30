import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import 'flashcard_demo_data.dart';
import 'flashcard_list_item.dart';

class FlashcardsPreviewPage extends StatelessWidget {
  const FlashcardsPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = demoFlashcards;

    return PreviewPage(
      icon: Icons.style_outlined,
      title: 'Flashcards',
      subtitle: 'A revisão espaçada vai morar aqui.',
      child: Column(
        children: cards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FlashcardListItem(card: card),
          );
        }).toList(),
      ),
    );
  }
}
