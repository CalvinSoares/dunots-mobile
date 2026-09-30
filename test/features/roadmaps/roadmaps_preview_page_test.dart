import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/roadmaps_preview_page.dart';

void main() {
  testWidgets('cria uma trilha pelo modal e atualiza a tela', (tester) async {
    final repository = InMemoryStudyTrackRepository(tracks: const []);

    await tester.pumpWidget(
      MaterialApp(home: RoadmapsPreviewPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma trilha cadastrada ainda.'), findsOneWidget);

    await tester.tap(find.text('Nova trilha'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Redes de Computadores');
    await tester.enterText(textFields.at(1), 'Trilha de fundamentos de redes.');

    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Redes de Computadores'), findsOneWidget);
    expect(find.text('0/0 itens concluídos'), findsOneWidget);
  });

  testWidgets('edita uma trilha pelo modal', (tester) async {
    final repository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-001',
          title: 'Trilha original',
          description: 'Descrição original.',
          completedItems: 1,
          totalItems: 4,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: RoadmapsPreviewPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar trilha'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.at(0), 'Trilha atualizada');
    await tester.enterText(textFields.at(1), 'Descrição atualizada.');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Trilha atualizada'), findsOneWidget);
    expect(find.text('Descrição atualizada.'), findsOneWidget);
    expect(find.text('1/4 itens concluídos'), findsOneWidget);
  });

  testWidgets('exclui uma trilha após confirmação', (tester) async {
    final repository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-001',
          title: 'Trilha removível',
          description: '',
          completedItems: 0,
          totalItems: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: RoadmapsPreviewPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Excluir trilha'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir trilha?'), findsOneWidget);
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Trilha removível'), findsNothing);
    expect(find.text('Nenhuma trilha cadastrada ainda.'), findsOneWidget);
  });
}
