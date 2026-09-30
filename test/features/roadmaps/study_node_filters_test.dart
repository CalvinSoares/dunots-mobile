import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_node_filters.dart';

void main() {
  const nodes = [
    StudyNode(
      id: 'root',
      trackId: 'track-001',
      parentId: null,
      title: 'Redes',
      description: 'Fundamentos.',
      sortOrder: 0,
    ),
    StudyNode(
      id: 'child',
      trackId: 'track-001',
      parentId: 'root',
      title: 'Topologias',
      description: 'Estrela e anel.',
      sortOrder: 0,
      priority: StudyPriority.high,
      notes: 'Revisar exemplos.',
    ),
    StudyNode(
      id: 'other',
      trackId: 'track-001',
      parentId: null,
      title: 'Segurança',
      description: '',
      sortOrder: 1,
      isCompleted: true,
    ),
  ];

  test('busca texto e preserva o pai do resultado', () {
    final result = StudyNodeFilters.apply(nodes: nodes, query: 'exemplos');

    expect(result.map((node) => node.id), ['root', 'child']);
  });

  test('filtra por prioridade e conclusão', () {
    final highPriority = StudyNodeFilters.apply(
      nodes: nodes,
      priority: StudyPriority.high,
    );
    final completed = StudyNodeFilters.apply(
      nodes: nodes,
      completion: StudyNodeCompletionFilter.completed,
    );

    expect(highPriority.map((node) => node.id), ['root', 'child']);
    expect(completed.map((node) => node.id), ['other']);
  });
}
