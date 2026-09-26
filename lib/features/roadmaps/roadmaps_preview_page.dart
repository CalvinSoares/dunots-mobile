import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';

class RoadmapsPreviewPage extends StatelessWidget {
  const RoadmapsPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PreviewPage(
      icon: Icons.route_outlined,
      title: 'Trilhas de estudo',
      subtitle: 'Organize tópicos, subtópicos e materiais.',
      child: Column(
        children: [
          ExampleListTile(
            title: 'Análise de Sistemas',
            detail: '12 de 38 itens concluídos',
          ),
          SizedBox(height: 10),
          ExampleListTile(
            title: 'Infraestrutura de Redes',
            detail: '5 de 24 itens concluídos',
          ),
        ],
      ),
    );
  }
}
