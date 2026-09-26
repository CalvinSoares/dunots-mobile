import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PreviewPage(
      icon: Icons.more_horiz,
      title: 'Mais',
      subtitle: 'Provas, desafios, sincronização e configurações.',
      child: Column(
        children: [
          ExampleListTile(
            title: 'Provas e simulados',
            detail: 'Questões e resultados',
          ),
          SizedBox(height: 10),
          ExampleListTile(
            title: 'Sincronização',
            detail: 'Conectar ao seu Dunots desktop',
          ),
        ],
      ),
    );
  }
}
