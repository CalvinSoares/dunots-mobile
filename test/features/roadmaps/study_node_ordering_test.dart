import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_node_ordering.dart';

StudyNode node({
  required String id,
  required String title,
  required int sortOrder,
  StudyPriority priority = StudyPriority.none,
}) {
  return StudyNode(
    id: id,
    trackId: 'track-ordering',
    parentId: null,
    title: title,
    description: '',
    sortOrder: sortOrder,
    priority: priority,
  );
}

void main() {
  test('ordena por prioridade descendente antes da ordem manual', () {
    final nodes = [
      node(
        id: 'low',
        title: 'Baixa',
        sortOrder: 0,
        priority: StudyPriority.low,
      ),
      node(
        id: 'urgent',
        title: 'Urgente',
        sortOrder: 99,
        priority: StudyPriority.urgent,
      ),
      node(
        id: 'high',
        title: 'Alta',
        sortOrder: 1,
        priority: StudyPriority.high,
      ),
    ]..sort(StudyNodeOrdering.compare);

    expect(nodes.map((item) => item.id), ['urgent', 'high', 'low']);
  });

  test('mantém ordem manual e desempate estável na mesma prioridade', () {
    final nodes = [
      node(id: 'second', title: 'Segundo', sortOrder: 1),
      node(id: 'first', title: 'Primeiro', sortOrder: 0),
      node(id: 'same-b', title: 'Mesmo', sortOrder: 2),
      node(id: 'same-a', title: 'Mesmo', sortOrder: 2),
    ]..sort(StudyNodeOrdering.compare);

    expect(nodes.map((item) => item.id), [
      'first',
      'second',
      'same-a',
      'same-b',
    ]);
  });
}
