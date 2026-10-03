import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/roadmaps_preview_page.dart';
import 'package:dunots_mobile/shared/widgets/dunots_modal.dart';

void main() {
  testWidgets('cria uma trilha e sua hierarquia pela prévia em massa', (
    tester,
  ) async {
    final trackRepository = InMemoryStudyTrackRepository(tracks: const []);
    final nodeRepository = InMemoryStudyNodeRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoadmapsPreviewPage(
            repository: trackRepository,
            nodeRepository: nodeRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nova trilha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Em massa'));
    await tester.pumpAndSettle();

    final fields = find.descendant(
      of: find.byType(DunotsModal),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), 'Redes de computadores');
    await tester.enterText(
      fields.at(2),
      '- Modelo OSI | Sete camadas\n  - Camada de rede | Roteamento\n- TCP/IP | Internet',
    );
    await tester.pumpAndSettle();

    expect(find.text('Prévia reconhecida: 3 item(ns)'), findsOneWidget);
    await tester.tap(find.text('Criar trilha'));
    await tester.pumpAndSettle();

    final tracks = await trackRepository.getAll();
    final nodes = await nodeRepository.getForTrack(tracks.single.id);
    expect(tracks, hasLength(1));
    expect(tracks.single.totalItems, 3);
    expect(nodes, hasLength(3));
    expect(nodes[1].parentId, nodes[0].id);
    expect(nodes[2].parentId, isNull);
  });
}
