import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';

import '../../shared/widgets/study_widgets.dart';

class FlashcardListItem extends StatelessWidget {
  final Flashcard card;

  const FlashcardListItem({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return ExampleListTile(title: card.front, detail: card.back);
  }
}
