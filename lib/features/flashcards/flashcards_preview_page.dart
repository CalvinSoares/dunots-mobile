import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';

class FlashcardsPreviewPage extends StatelessWidget {
  const FlashcardsPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PreviewPage(
      icon: Icons.style_outlined,
      title: 'Flashcards',
      subtitle: 'A revisão espaçada vai morar aqui.',
      child: Column(
        children: [
          ExampleListTile(
            title: 'O que é independência de dados?',
            detail: 'Banco de dados · 2 revisões',
          ),
          SizedBox(height: 10),
          ExampleListTile(
            title: 'Como funciona o protocolo TCP?',
            detail: 'Redes · revisão amanhã',
          ),
        ],
      ),
    );
  }
}
