import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/diagrams/data/diagram_repository.dart';
import 'package:dunots_mobile/features/diagrams/diagrams_preview_page.dart';
import 'package:dunots_mobile/features/diagrams/domain/study_diagram.dart';

void main() {
  testWidgets('organiza ações sem overflow em tela compacta', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 800,
            child: DiagramsPreviewPage(
              repository: InMemoryDiagramRepository(
                items: [
                  StudyDiagram(
                    id: 'diagram-mobile',
                    title: 'Rede local',
                    createdAt: DateTime(2026, 9, 30),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Novo fluxograma'), findsOneWidget);
    expect(find.text('Editar fluxograma'), findsOneWidget);

    await tester.tap(find.text('Novo fluxograma'));
    await tester.pumpAndSettle();
    expect(
      find.text('Dê um nome ao mapa antes de adicionar os blocos.'),
      findsOneWidget,
    );
    expect(find.text('Título *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
