import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_track_details_page.dart';

void main() {
  Future<void> pumpPage(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: StudyTrackDetailsPage(
          track: const StudyTrack(
            id: 'track-responsive',
            title: 'Redes',
            description: 'Fundamentos',
            completedItems: 0,
            totalItems: 1,
          ),
          repository: InMemoryStudyNodeRepository(
            nodes: const [
              StudyNode(
                id: 'node-responsive',
                trackId: 'track-responsive',
                parentId: null,
                title: 'Arquiteturas de rede',
                description: 'Modelos e topologias para infraestrutura.',
                sortOrder: 0,
              ),
            ],
          ),
          trackRepository: InMemoryStudyTrackRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mantém a árvore utilizável em tela pequena', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpPage(tester, const Size(360, 800));

    expect(find.text('Arquiteturas de rede'), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('mantém a árvore utilizável em landscape', (tester) async {
    await pumpPage(tester, const Size(800, 400));

    expect(find.text('Arquiteturas de rede'), findsOneWidget);
    expect(find.byTooltip('Vincular material'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
