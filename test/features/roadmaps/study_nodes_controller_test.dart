import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_node_repository.dart';
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
}
