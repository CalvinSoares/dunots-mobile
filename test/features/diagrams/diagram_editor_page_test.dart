import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/diagrams/data/diagram_repository.dart';
import 'package:dunots_mobile/features/diagrams/diagram_editor_page.dart';
import 'package:dunots_mobile/features/diagrams/domain/study_diagram.dart';

void main() {
  testWidgets('move múltiplos blocos e salva as posições', (tester) async {
    final now = DateTime(2026, 9, 30);
    final diagram = StudyDiagram(
      id: 'diagram-1',
      title: 'Rede',
      nodes: [
        {'id': 'a', 'label': 'A', 'x': 100.0, 'y': 100.0},
        {'id': 'b', 'label': 'B', 'x': 320.0, 'y': 100.0},
      ],
      edges: const [
        {'source': 'a', 'target': 'b'},
      ],
      createdAt: now,
    );
    final repository = InMemoryDiagramRepository(items: [diagram]);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagramEditorPage(diagram: diagram, repository: repository),
      ),
    );

    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.select_all))
        .onPressed!();
    await tester.pump();
    await tester.drag(
      find.byKey(const ValueKey('diagram-node-a')),
      const Offset(40, 20),
    );
    tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Salvar'))
        .onPressed!();
    await tester.pumpAndSettle();

    final saved = (await repository.getAll()).single;
    expect(saved.nodes[0]['x'], 140.0);
    expect(saved.nodes[0]['y'], 120.0);
    expect(saved.nodes[1]['x'], 360.0);
    expect(saved.nodes[1]['y'], 120.0);
  });

  testWidgets('copia e cola a seleção mantendo os blocos conectados', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 30);
    final diagram = StudyDiagram(
      id: 'diagram-2',
      title: 'Fluxo',
      nodes: [
        {'id': 'a', 'label': 'A', 'x': 100.0, 'y': 100.0},
        {'id': 'b', 'label': 'B', 'x': 320.0, 'y': 100.0},
      ],
      edges: const [
        {'source': 'a', 'target': 'b'},
      ],
      createdAt: now,
    );
    final repository = InMemoryDiagramRepository(items: [diagram]);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagramEditorPage(diagram: diagram, repository: repository),
      ),
    );

    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.select_all))
        .onPressed!();
    await tester.pump();
    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.copy_outlined),
        )
        .onPressed!();
    await tester.pump();
    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.content_paste),
        )
        .onPressed!();
    await tester.pump();

    expect(find.textContaining('4 blocos'), findsOneWidget);
  });

  testWidgets('recorta e cola a seleção preservando as ligações', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 30);
    final diagram = StudyDiagram(
      id: 'diagram-3',
      title: 'Fluxo recortado',
      nodes: [
        {'id': 'a', 'label': 'A', 'x': 100.0, 'y': 100.0},
        {'id': 'b', 'label': 'B', 'x': 320.0, 'y': 100.0},
      ],
      edges: const [
        {'source': 'a', 'target': 'b'},
      ],
      createdAt: now,
    );
    final repository = InMemoryDiagramRepository(items: [diagram]);

    await tester.pumpWidget(
      MaterialApp(
        home: DiagramEditorPage(diagram: diagram, repository: repository),
      ),
    );

    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.select_all))
        .onPressed!();
    await tester.pump();
    tester
        .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.content_cut))
        .onPressed!();
    await tester.pump();
    tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.content_paste),
        )
        .onPressed!();
    await tester.pump();

    expect(find.textContaining('2 blocos · 1 ligações'), findsOneWidget);
  });
}
