import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/roadmaps_preview_page.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';

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

    await tester.dragFrom(const Offset(300, 520), const Offset(0, -260));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined).last);
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

    expect(find.text('Topologia em estrela editada'), findsOneWidget);
  });

  testWidgets('inicia simulado com questões vinculadas ao tópico', (
    tester,
  ) async {
    final trackRepository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-quiz',
          title: 'Redes',
          description: '',
          completedItems: 0,
          totalItems: 1,
        ),
      ],
    );
    final nodeRepository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'node-quiz',
          trackId: 'track-quiz',
          parentId: null,
          title: 'Arquiteturas de rede',
          description: '',
          sortOrder: 0,
        ),
      ],
    );
    final linkRepository = InMemoryStudyNodeMaterialRepository(
      links: const [
        StudyMaterialLink(
          nodeId: 'node-quiz',
          materialId: 'question-001',
          materialType: StudyMaterialType.question,
        ),
      ],
    );
    final questionRepository = InMemoryQuestionRepository();
    final attemptRepository = InMemoryQuizAttemptRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RoadmapsPreviewPage(
          repository: trackRepository,
          nodeRepository: nodeRepository,
          materialLinkRepository: linkRepository,
          questionRepository: questionRepository,
          attemptRepository: attemptRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir trilha'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Montar simulado com questões vinculadas'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar seleção'), findsOneWidget);
    await tester.tap(find.text('Continuar (1)'));
    await tester.pumpAndSettle();
    final quizDialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(quizDialogField, 'Simulado da trilha');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Questão 1 de 1'), findsOneWidget);
    expect((await attemptRepository.getAll()).single.questionIds, [
      'question-001',
    ]);
  });

  testWidgets('seleciona questões manualmente em vários tópicos', (
    tester,
  ) async {
    final trackRepository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-manual-quiz',
          title: 'Infraestrutura',
          description: '',
          completedItems: 0,
          totalItems: 2,
        ),
      ],
    );
    final nodeRepository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'node-manual-a',
          trackId: 'track-manual-quiz',
          parentId: null,
          title: 'Redes',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'node-manual-b',
          trackId: 'track-manual-quiz',
          parentId: null,
          title: 'Sistemas distribuídos',
          description: '',
          sortOrder: 1,
        ),
      ],
    );
    final linkRepository = InMemoryStudyNodeMaterialRepository(
      links: const [
        StudyMaterialLink(
          nodeId: 'node-manual-a',
          materialId: 'question-001',
          materialType: StudyMaterialType.question,
        ),
        StudyMaterialLink(
          nodeId: 'node-manual-b',
          materialId: 'question-002',
          materialType: StudyMaterialType.question,
        ),
      ],
    );
    final questionRepository = InMemoryQuestionRepository();
    final attemptRepository = InMemoryQuizAttemptRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RoadmapsPreviewPage(
          repository: trackRepository,
          nodeRepository: nodeRepository,
          materialLinkRepository: linkRepository,
          questionRepository: questionRepository,
          attemptRepository: attemptRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir trilha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selecionar questões da trilha'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar questões'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    await tester.tap(find.textContaining('Qual é a função principal'));
    await tester.tap(find.textContaining('Qual topologia conecta'));
    await tester.pumpAndSettle();
    expect(find.text('2 selecionada(s) de 2'), findsOneWidget);
    await tester.tap(find.text('Criar simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar seleção'), findsOneWidget);
    expect(find.text('2 questão(ões) no simulado'), findsOneWidget);
    await tester.tap(find.byTooltip('Remover questão').last);
    await tester.pumpAndSettle();
    expect(find.text('1 questão(ões) no simulado'), findsOneWidget);
    await tester.tap(find.text('Continuar (1)'));
    await tester.pumpAndSettle();

    final quizDialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(quizDialogField, 'Revisão manual da trilha');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Questão 1 de 1'), findsOneWidget);
    expect((await attemptRepository.getAll()).single.questionIds, [
      'question-001',
    ]);
  });

  testWidgets('monta simulado escolhendo primeiro o tópico', (tester) async {
    final trackRepository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-topic-builder',
          title: 'Redes',
          description: '',
          completedItems: 0,
          totalItems: 1,
        ),
      ],
    );
    final nodeRepository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'node-topic-builder',
          trackId: 'track-topic-builder',
          parentId: null,
          title: 'Redes',
          description: 'Fundamentos de redes.',
          sortOrder: 0,
        ),
      ],
    );
    final linkRepository = InMemoryStudyNodeMaterialRepository(
      links: const [
        StudyMaterialLink(
          nodeId: 'node-topic-builder',
          materialId: 'question-001',
          materialType: StudyMaterialType.question,
        ),
      ],
    );
    final attemptRepository = InMemoryQuizAttemptRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: RoadmapsPreviewPage(
          repository: trackRepository,
          nodeRepository: nodeRepository,
          materialLinkRepository: linkRepository,
          questionRepository: InMemoryQuestionRepository(),
          attemptRepository: attemptRepository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir trilha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Montar simulado por tópicos'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar tópicos'), findsOneWidget);
    await tester.tap(find.text('Redes').last);
    await tester.pumpAndSettle();
    expect(find.text('1 selecionado(s) de 1'), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Selecionar questões'), findsOneWidget);
    await tester.tap(find.textContaining('Qual é a função principal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar seleção'), findsOneWidget);
    await tester.tap(find.text('Continuar (1)'));
    await tester.pumpAndSettle();

    final quizDialogField = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(quizDialogField, 'Simulado por tópico');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Questão 1 de 1'), findsOneWidget);
    expect((await attemptRepository.getAll()).single.questionIds, [
      'question-001',
    ]);
  });
}
