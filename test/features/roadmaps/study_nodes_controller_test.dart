import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_nodes_controller.dart';

void main() {
  test(
    'cria tópico raiz e subtópico preservando a relação pai-filho',
    () async {
      final repository = InMemoryStudyNodeRepository();
      final controller = StudyNodesController(
        trackId: 'track-001',
        repository: repository,
      );

      await controller.load();
      expect(controller.state.status, StudyNodesStatus.empty);

      await controller.createNode(
        title: 'Redes de computadores',
        description: 'Fundamentos de redes.',
      );
      final root = controller.state.nodes.single;

      await controller.createNode(
        title: 'Arquiteturas de rede',
        description: '',
        parentId: root.id,
        notes: 'Revisar topologias.',
        priority: StudyPriority.high,
      );

      expect(controller.state.status, StudyNodesStatus.data);
      expect(controller.state.nodes, hasLength(2));
      final child = controller.state.nodes.firstWhere(
        (node) => node.id != root.id,
      );
      expect(child.parentId, root.id);
      expect(child.notes, 'Revisar topologias.');
      expect(child.priority, StudyPriority.high);
    },
  );

  test('não cria tópico sem título', () async {
    final controller = StudyNodesController(
      trackId: 'track-001',
      repository: InMemoryStudyNodeRepository(),
    );

    expect(
      () => controller.createNode(title: '  ', description: ''),
      throwsArgumentError,
    );
  });

  test('alterna a conclusão de um tópico', () async {
    final controller = StudyNodesController(
      trackId: 'track-001',
      repository: InMemoryStudyNodeRepository(
        nodes: const [
          StudyNode(
            id: 'node-001',
            trackId: 'track-001',
            parentId: null,
            title: 'Redes',
            description: '',
            sortOrder: 0,
          ),
        ],
      ),
    );

    await controller.load();
    expect(controller.state.nodes.single.isCompleted, isFalse);

    await controller.toggleCompletion('node-001');

    expect(controller.state.nodes.single.isCompleted, isTrue);
    expect(controller.state.nodes.single.status, StudyNodeStatus.completed);
  });

  test(
    'atualiza conclusão sem emitir um estado intermediário de loading',
    () async {
      final controller = StudyNodesController(
        trackId: 'track-001',
        repository: InMemoryStudyNodeRepository(
          nodes: const [
            StudyNode(
              id: 'node-no-flicker',
              trackId: 'track-001',
              parentId: null,
              title: 'Redes',
              description: '',
              sortOrder: 0,
            ),
          ],
        ),
      );
      await controller.load();

      final emittedStatuses = <StudyNodesStatus>[];
      controller.addListener(
        () => emittedStatuses.add(controller.state.status),
      );

      await controller.toggleCompletion('node-no-flicker');

      expect(emittedStatuses, [StudyNodesStatus.data]);
      expect(controller.state.nodes.single.isCompleted, isTrue);
    },
  );

  test(
    'altera o status explícito sem transformar revisão em conclusão',
    () async {
      final controller = StudyNodesController(
        trackId: 'track-001',
        repository: InMemoryStudyNodeRepository(
          nodes: const [
            StudyNode(
              id: 'node-status',
              trackId: 'track-001',
              parentId: null,
              title: 'Revisar redes',
              description: '',
              sortOrder: 0,
            ),
          ],
        ),
      );

      await controller.load();
      await controller.setStatus('node-status', StudyNodeStatus.review);

      final node = controller.state.nodes.single;
      expect(node.status, StudyNodeStatus.review);
      expect(node.isCompleted, isFalse);
    },
  );

  test('edita, move entre irmãos e exclui uma árvore de tópicos', () async {
    final repository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'root-001',
          trackId: 'track-001',
          parentId: null,
          title: 'Redes',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'child-001',
          trackId: 'track-001',
          parentId: 'root-001',
          title: 'Topologias',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'root-002',
          trackId: 'track-001',
          parentId: null,
          title: 'Segurança',
          description: '',
          sortOrder: 1,
        ),
      ],
    );
    final controller = StudyNodesController(
      trackId: 'track-001',
      repository: repository,
    );

    await controller.load();
    await controller.updateNode(
      id: 'root-001',
      title: 'Redes de computadores',
      description: 'Fundamentos.',
      notes: 'Priorizar revisão.',
      priority: StudyPriority.urgent,
    );
    await controller.moveNode('root-002', direction: -1);

    var roots =
        controller.state.nodes.where((node) => node.parentId == null).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(roots.map((node) => node.title), [
      'Segurança',
      'Redes de computadores',
    ]);
    final updatedRoot = controller.state.nodes.firstWhere(
      (node) => node.id == 'root-001',
    );
    expect(updatedRoot.notes, 'Priorizar revisão.');
    expect(updatedRoot.priority, StudyPriority.urgent);

    await controller.deleteNode('root-001');
    expect(controller.state.nodes, hasLength(1));
    expect(controller.state.nodes.single.id, 'root-002');
  });

  test('exclui o tópico e promove os subtópicos quando solicitado', () async {
    final repository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'root-001',
          trackId: 'track-001',
          parentId: null,
          title: 'Redes',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'node-001',
          trackId: 'track-001',
          parentId: 'root-001',
          title: 'Camada de transporte',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'node-002',
          trackId: 'track-001',
          parentId: 'node-001',
          title: 'TCP',
          description: '',
          sortOrder: 0,
        ),
      ],
    );
    final controller = StudyNodesController(
      trackId: 'track-001',
      repository: repository,
    );

    await controller.load();
    await controller.deleteNode('node-001', preserveChildren: true);

    expect(
      controller.state.nodes.map((node) => node.id),
      containsAll(<String>['root-001', 'node-002']),
    );
    expect(
      controller.state.nodes.any((node) => node.id == 'node-001'),
      isFalse,
    );
    expect(
      controller.state.nodes
          .firstWhere((node) => node.id == 'node-002')
          .parentId,
      'root-001',
    );
  });

  test('promove filhos para a raiz quando o tópico raiz é removido', () async {
    final repository = InMemoryStudyNodeRepository(
      nodes: const [
        StudyNode(
          id: 'root-001',
          trackId: 'track-001',
          parentId: null,
          title: 'Redes',
          description: '',
          sortOrder: 0,
        ),
        StudyNode(
          id: 'node-001',
          trackId: 'track-001',
          parentId: 'root-001',
          title: 'TCP',
          description: '',
          sortOrder: 0,
        ),
      ],
    );
    final controller = StudyNodesController(
      trackId: 'track-001',
      repository: repository,
    );

    await controller.load();
    await controller.deleteNode('root-001', preserveChildren: true);

    expect(controller.state.nodes.single.id, 'node-001');
    expect(controller.state.nodes.single.parentId, isNull);
  });
}
