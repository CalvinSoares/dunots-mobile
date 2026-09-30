import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';

import '../../shared/widgets/study_widgets.dart';
import 'flashcard_details_page.dart';

class FlashcardListItem extends StatelessWidget {
  final Flashcard card;

  const FlashcardListItem({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => FlashcardDetailsPage(card: card)),
        );
      },
      child: ExampleListTile(title: card.front, detail: card.back),
    );
  }
}
