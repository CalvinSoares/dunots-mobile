import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';
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
    final linkRepository = InMemoryStudyNodeMaterialRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RoadmapsPreviewPage(
          repository: trackRepository,
          nodeRepository: nodeRepository,
          materialLinkRepository: linkRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir trilha'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum tópico cadastrado ainda.'), findsOneWidget);

    await tester.tap(find.text('Novo tópico'));
    await tester.pumpAndSettle();
    final firstDialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(firstDialogFields.at(0), 'Arquiteturas de rede');
    await tester.enterText(firstDialogFields.at(1), 'Topologias e modelos.');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Arquiteturas de rede'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Adicionar subtópico'));
    expect(find.byTooltip('Adicionar subtópico'), findsOneWidget);

    await tester.tap(find.byTooltip('Adicionar subtópico'));
    await tester.pumpAndSettle();
    final childDialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(childDialogFields.at(0), 'Topologia em estrela');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Topologia em estrela'), findsOneWidget);
    final nodes = await nodeRepository.getForTrack('track-001');
    expect(nodes, hasLength(2));
    expect(nodes.last.parentId, nodes.first.id);
    expect(find.text('0/2 itens concluídos'), findsOneWidget);

    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text('1/2 itens concluídos'), findsOneWidget);
    final updatedTrack = (await trackRepository.getAll()).single;
    expect(updatedTrack.completedItems, 1);
    expect(updatedTrack.totalItems, 2);

    await tester.ensureVisible(find.byTooltip('Vincular material').first);
    await tester.tap(find.byTooltip('Vincular material').first);
    await tester.pumpAndSettle();

    final materialDialogSearch = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(materialDialogSearch, 'independência');
    expect(find.text('O que é independência de dados?'), findsOneWidget);
    await tester.tap(find.text('O que é independência de dados?'));
    await tester.tap(find.text('Salvar vínculos'));
    await tester.pumpAndSettle();

    final linkedMaterials = await linkRepository.getForNode(nodes.first.id);
    expect(linkedMaterials, hasLength(1));
    expect(linkedMaterials.single.materialType, StudyMaterialType.flashcard);

    await tester.tap(find.byTooltip('Editar tópico').last);
    await tester.pumpAndSettle();
    final editDialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(
      editDialogFields.at(0),
      'Topologia em estrela editada',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Topologia em estrela editada'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir tópico').first);
    await tester.pumpAndSettle();
    expect(find.text('Excluir tópico?'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Arquiteturas de rede'), findsNothing);
    expect(find.text('Topologia em estrela editada'), findsNothing);
  });
}
