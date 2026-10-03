import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/data/study_material_progress_repository.dart';
import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/flashcards/data/flashcard_repository.dart';
import 'package:dunots_mobile/features/roadmaps/roadmaps_preview_page.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_track_details_page.dart';
import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/quizzes/data/quiz_attempt_repository.dart';
import 'package:dunots_mobile/shared/widgets/dunots_modal.dart';

Future<void> openNodeActions(WidgetTester tester) async {
  if (find.byTooltip('Ações do tópico').evaluate().isEmpty) {
    final nodeCard = find.bySemanticsLabel(RegExp(r'^Tópico ')).first;
    await tester.tap(nodeCard);
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byTooltip('Ações do tópico'));
  await tester.pumpAndSettle();
}

Future<void> openTrackActions(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Ações da trilha'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('compacta o card e abre os detalhes do tópico ao tocar', (
    tester,
  ) async {
    const title =
        'Topologias de rede e arquiteturas distribuídas em ambientes corporativos';
    const description =
        'Descrição extensa do tópico que deve ficar resumida no card e completa na tela de detalhes.';
    const notes = 'Anotação privada para revisar este conteúdo depois.';

    final repository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'node-details',
          trackId: 'track-details',
          parentId: null,
          title: title,
          description: description,
          notes: notes,
          sortOrder: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudyTrackDetailsPage(
          track: const StudyTrack(
            id: 'track-details',
            title: 'Redes',
            description: '',
            completedItems: 0,
            totalItems: 1,
          ),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(title));
    await tester.pumpAndSettle();

    expect(find.text('Detalhes do tópico'), findsOneWidget);
    expect(find.byTooltip('Ações do tópico'), findsOneWidget);
    expect(find.text(description), findsOneWidget);
    expect(find.text(notes), findsOneWidget);

    await tester.tap(find.byTooltip('Marcar como concluído'));
    await tester.pumpAndSettle();

    expect(
      (await repository.getForTrack('track-details')).single.isCompleted,
      isTrue,
    );
  });

  testWidgets(
    'edita tópico no detalhe sem fechar a tela e preserva a rolagem da trilha',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final nodes = List.generate(
        24,
        (index) => StudyNode(
          id: 'node-scroll-$index',
          trackId: 'track-scroll',
          parentId: null,
          title: 'Tópico ${index + 1}',
          description: 'Descrição do tópico ${index + 1}',
          sortOrder: index,
        ),
      );
      final repository = InMemoryStudyNodeRepository(nodes: nodes);

      await tester.pumpWidget(
        MaterialApp(
          home: StudyTrackDetailsPage(
            track: const StudyTrack(
              id: 'track-scroll',
              title: 'Trilha longa',
              description: '',
              completedItems: 0,
              totalItems: 24,
            ),
            repository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final nodeList = find.byKey(
        const PageStorageKey('study-track-node-list'),
      );
      final nodeScrollable = find.descendant(
        of: nodeList,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('Tópico 18'),
        240,
        scrollable: nodeScrollable,
      );
      final offsetBeforeOpening = tester
          .state<ScrollableState>(nodeScrollable)
          .position
          .pixels;
      expect(offsetBeforeOpening, greaterThan(0));

      await tester.tap(find.text('Tópico 18'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Ações do tópico'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      final fields = find.descendant(
        of: find.byType(DunotsModal),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.first, 'Tópico 18 revisado');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do tópico'), findsOneWidget);
      expect(find.text('Tópico 18 revisado'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      final restoredOffset = tester
          .state<ScrollableState>(nodeScrollable)
          .position
          .pixels;
      expect(restoredOffset, closeTo(offsetBeforeOpening, 0.01));
      expect(find.text('Tópico 18 revisado'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('recolhe e reabre grupos da árvore', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudyTrackDetailsPage(
          track: const StudyTrack(
            id: 'track-collapse',
            title: 'Redes',
            description: '',
            completedItems: 0,
            totalItems: 2,
          ),
          repository: InMemoryStudyNodeRepository(
            nodes: const [
              StudyNode(
                id: 'node-parent-collapse',
                trackId: 'track-collapse',
                parentId: null,
                title: 'Redes de computadores',
                description: '',
                sortOrder: 0,
              ),
              StudyNode(
                id: 'node-child-collapse',
                trackId: 'track-collapse',
                parentId: 'node-parent-collapse',
                title: 'Topologias de rede',
                description: '',
                sortOrder: 0,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Topologias de rede'), findsOneWidget);
    await tester.tap(find.byTooltip('Recolher grupo'));
    await tester.pumpAndSettle();
    expect(find.text('Topologias de rede'), findsNothing);

    await tester.tap(find.byTooltip('Expandir grupo'));
    await tester.pumpAndSettle();
    expect(find.text('Topologias de rede'), findsOneWidget);
  });

  testWidgets('permite excluir um tópico preservando seus subtópicos', (
    tester,
  ) async {
    final repository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'node-delete-parent',
          trackId: 'track-delete',
          parentId: null,
          title: 'Grupo de redes',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'node-delete-child',
          trackId: 'track-delete',
          parentId: 'node-delete-parent',
          title: 'Subtópico preservado',
          description: '',
          sortOrder: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: StudyTrackDetailsPage(
          track: const StudyTrack(
            id: 'track-delete',
            title: 'Redes',
            description: '',
            completedItems: 0,
            totalItems: 2,
          ),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grupo de redes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ações do tópico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir tópico'));
    await tester.pumpAndSettle();

    expect(find.text('Excluir também 1 subtópico'), findsOneWidget);
    expect(
      find.text('Desmarcado: eles sobem para o mesmo nível deste tópico.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Grupo de redes'), findsNothing);
    expect(
      (await repository.getForTrack('track-delete')).single.parentId,
      isNull,
    );
  });

  testWidgets('destaca uma folha acionável em vez do grupo pai', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudyTrackDetailsPage(
          track: const StudyTrack(
            id: 'track-next',
            title: 'Redes',
            description: '',
            completedItems: 0,
            totalItems: 2,
          ),
          repository: InMemoryStudyNodeRepository(
            nodes: const [
              StudyNode(
                id: 'node-group',
                trackId: 'track-next',
                parentId: null,
                title: 'Grupo de redes',
                description: '',
                sortOrder: 0,
                priority: StudyPriority.urgent,
              ),
              StudyNode(
                id: 'node-actionable',
                trackId: 'track-next',
                parentId: 'node-group',
                title: 'Subtópico acionável',
                description: '',
                sortOrder: 0,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('→ Subtópico acionável'), findsOneWidget);
    expect(find.text('→ Grupo de redes'), findsNothing);
  });

  testWidgets('ordena os tópicos e o próximo pela prioridade', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: StudyTrackDetailsPage(
          track: const StudyTrack(
            id: 'track-priority-order',
            title: 'Redes',
            description: '',
            completedItems: 0,
            totalItems: 3,
          ),
          repository: InMemoryStudyNodeRepository(
            nodes: const [
              StudyNode(
                id: 'node-low',
                trackId: 'track-priority-order',
                parentId: null,
                title: 'Baixa prioridade',
                description: '',
                sortOrder: 0,
                priority: StudyPriority.low,
              ),
              StudyNode(
                id: 'node-urgent',
                trackId: 'track-priority-order',
                parentId: null,
                title: 'Urgente',
                description: '',
                sortOrder: 99,
                priority: StudyPriority.urgent,
              ),
              StudyNode(
                id: 'node-high',
                trackId: 'track-priority-order',
                parentId: null,
                title: 'Alta prioridade',
                description: '',
                sortOrder: 1,
                priority: StudyPriority.high,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('→ Urgente'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Urgente')).dy,
      lessThan(tester.getTopLeft(find.text('Alta prioridade')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Alta prioridade')).dy,
      lessThan(tester.getTopLeft(find.text('Baixa prioridade')).dy),
    );
  });

  testWidgets('agrupa a movimentação do tópico no menu em tela compacta', (
    tester,
  ) async {
    final trackRepository = InMemoryStudyTrackRepository(
      tracks: const [
        StudyTrack(
          id: 'track-compact',
          title: 'Trilha compacta',
          description: '',
          completedItems: 0,
          totalItems: 0,
        ),
      ],
    );
    final nodeRepository = InMemoryStudyNodeRepository(
      nodes: [
        const StudyNode(
          id: 'node-1',
          trackId: 'track-compact',
          parentId: null,
          title: 'Primeiro tópico',
          description: '',
          sortOrder: 0,
        ),
        const StudyNode(
          id: 'node-2',
          trackId: 'track-compact',
          parentId: null,
          title: 'Segundo tópico',
          description: '',
          sortOrder: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: const MediaQueryData(size: Size(360, 800)),
          child: child!,
        ),
        home: SizedBox(
          width: 360,
          height: 800,
          child: RoadmapsPreviewPage(
            repository: trackRepository,
            nodeRepository: nodeRepository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir trilha'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mover para cima'), findsNothing);
    expect(find.byTooltip('Mover para baixo'), findsNothing);
    await tester.tap(find.text('Primeiro tópico'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ações do tópico'));
    await tester.pumpAndSettle();
    expect(find.text('Mover para cima'), findsOneWidget);
    expect(find.text('Mover para baixo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

    await tester.tap(find.byTooltip('Novo tópico'));
    await tester.pumpAndSettle();
    final firstDialogFields = find.descendant(
      of: find.byType(DunotsModal),
      matching: find.byType(TextField),
    );
    await tester.enterText(firstDialogFields.at(0), 'Arquiteturas de rede');
    await tester.enterText(firstDialogFields.at(1), 'Topologias e modelos.');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Arquiteturas de rede'), findsOneWidget);
    await tester.tap(find.text('Arquiteturas de rede'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ações do tópico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar subtópico'));
    await tester.pumpAndSettle();
    final childDialogFields = find.descendant(
      of: find.byType(DunotsModal),
      matching: find.byType(TextField),
    );
    await tester.enterText(childDialogFields.at(0), 'Topologia em estrela');
    await tester.tap(find.text('Criar'));
    await tester.pumpAndSettle();

    final nodes = await nodeRepository.getForTrack('track-001');
    expect(nodes, hasLength(2));
    expect(nodes.last.parentId, nodes.first.id);
    await tester.scrollUntilVisible(
      find.text('Topologia em estrela'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Topologia em estrela'), findsOneWidget);
    expect(find.text('0 de 2 itens'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('A fazer'), findsNWidgets(2));
    expect(find.text('Próximo tópico'), findsOneWidget);

    final completionToggle = find.bySemanticsLabel(
      'Concluir tópico Arquiteturas de rede',
    );
    await tester.ensureVisible(completionToggle);
    await tester.tap(completionToggle);
    await tester.pumpAndSettle();

    expect(find.text('1 de 2 itens'), findsOneWidget);
    final updatedTrack = (await trackRepository.getAll()).single;
    expect(updatedTrack.completedItems, 1);
    expect(updatedTrack.totalItems, 2);

    await openNodeActions(tester);
    await tester.tap(find.text('Vincular material'));
    await tester.pumpAndSettle();

    final materialDialogSearch = find.descendant(
      of: find.byType(DunotsModal),
      matching: find.byType(TextField),
    );
    await tester.enterText(materialDialogSearch, 'independência');
    expect(find.text('O que é independência de dados?'), findsOneWidget);
    await tester.tap(find.text('O que é independência de dados?'));
    await tester.tap(find.text('Salvar vínculos'));
    await tester.pumpAndSettle();

    final linkedMaterials = [
      for (final node in nodes) ...await linkRepository.getForNode(node.id),
    ];
    expect(linkedMaterials, hasLength(1));
    expect(linkedMaterials.single.materialType, StudyMaterialType.flashcard);

    await tester.dragFrom(const Offset(300, 520), const Offset(0, -260));
    await tester.pumpAndSettle();
    await openNodeActions(tester);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    final editDialogFields = find.descendant(
      of: find.byType(DunotsModal),
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
    await openNodeActions(tester);
    await tester.tap(find.textContaining('Montar simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Revisar seleção'), findsOneWidget);
    await tester.tap(find.text('Continuar (1)'));
    await tester.pumpAndSettle();
    final quizDialogField = find.descendant(
      of: find.byType(DunotsModal),
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
    await openTrackActions(tester);
    await tester.tap(find.text('Selecionar questões'));
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
      of: find.byType(DunotsModal),
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
    await openTrackActions(tester);
    await tester.tap(find.text('Montar simulado'));
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
      of: find.byType(DunotsModal),
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

  testWidgets(
    'abre um flashcard vinculado e atualiza o progresso ao confirmar',
    (tester) async {
      final trackRepository = InMemoryStudyTrackRepository(
        tracks: const [
          StudyTrack(
            id: 'track-material-progress',
            title: 'Trilha de redes',
            description: '',
            completedItems: 0,
            totalItems: 1,
          ),
        ],
      );
      final nodeRepository = InMemoryStudyNodeRepository(
        nodes: const [
          StudyNode(
            id: 'node-material-progress',
            trackId: 'track-material-progress',
            parentId: null,
            title: 'TCP',
            description: '',
            sortOrder: 0,
          ),
        ],
      );
      final linkRepository = InMemoryStudyNodeMaterialRepository(
        links: const [
          StudyMaterialLink(
            nodeId: 'node-material-progress',
            materialId: 'card-material-progress',
            materialType: StudyMaterialType.flashcard,
          ),
        ],
      );
      final progressRepository = InMemoryStudyMaterialProgressRepository();
      final flashcardRepository = InMemoryFlashcardRepository(
        cards: [
          Flashcard(
            id: 'card-material-progress',
            front: 'O que é TCP?',
            back: 'Protocolo orientado a conexão.',
            createdAt: DateTime(2026, 10, 1),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RoadmapsPreviewPage(
            repository: trackRepository,
            nodeRepository: nodeRepository,
            materialLinkRepository: linkRepository,
            flashcardRepository: flashcardRepository,
            materialProgressRepository: progressRepository,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Abrir trilha'));
      await tester.pumpAndSettle();

      await openNodeActions(tester);
      await tester.tap(find.textContaining('Abrir materiais'));
      await tester.pumpAndSettle();
      expect(find.text('Detalhes do flashcard'), findsOneWidget);
      await tester.tap(find.text('Marcar como estudado'));
      await tester.pumpAndSettle();

      expect(find.text('1/1'), findsOneWidget);
      expect(find.text('1 de 1 item'), findsOneWidget);
      expect(
        await progressRepository.isCompleted(
          const StudyMaterialLink(
            nodeId: 'node-material-progress',
            materialId: 'card-material-progress',
            materialType: StudyMaterialType.flashcard,
          ),
        ),
        isTrue,
      );
    },
  );
}
