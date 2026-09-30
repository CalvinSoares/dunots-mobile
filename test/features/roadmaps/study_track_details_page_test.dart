import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/roadmaps_preview_page.dart';

void main() {
  testWidgets('abre a trilha e cria tópico e subtópico', (tester) async {
    final trackRepository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-001',
          title: 'Redes de Computadores',
          description: 'Fundamentos.',
          completedItems: 0,
          totalItems: 0,
        ),
      ],
    );
    final nodeRepository = InMemoryStudyNodeRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RoadmapsPreviewPage(
          repository: trackRepository,
          nodeRepository: nodeRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir trilha'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum tópico cadastrado ainda.'), findsOneWidget);

    await tester.tap(find.text('Novo tópico'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'Arquiteturas de rede',
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      'Topologias e modelos.',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Arquiteturas de rede'), findsOneWidget);
    expect(find.byTooltip('Adicionar subtópico'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar subtópico'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).at(0),
      'Topologia em estrela',
    );
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Topologia em estrela'), findsOneWidget);
    final nodes = await nodeRepository.getForTrack('track-001');
    expect(nodes, hasLength(2));
    expect(nodes.last.parentId, nodes.first.id);
  });
}
