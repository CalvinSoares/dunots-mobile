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
      );

      expect(controller.state.status, StudyNodesStatus.data);
      expect(controller.state.nodes, hasLength(2));
      final child = controller.state.nodes.firstWhere(
        (node) => node.id != root.id,
      );
      expect(child.parentId, root.id);
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
    );
    await controller.moveNode('root-002', direction: -1);

    var roots =
        controller.state.nodes.where((node) => node.parentId == null).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    expect(roots.map((node) => node.title), [
      'Segurança',
      'Redes de computadores',
    ]);

    await controller.deleteNode('root-001');
    expect(controller.state.nodes, hasLength(1));
    expect(controller.state.nodes.single.id, 'root-002');
  });
}
