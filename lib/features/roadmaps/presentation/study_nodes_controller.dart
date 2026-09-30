import 'package:flutter/foundation.dart';

import '../data/study_node_repository.dart';
import '../domain/study_node.dart';

enum StudyNodesStatus { initial, loading, data, empty, error }

class StudyNodesState {
  final StudyNodesStatus status;
  final List<StudyNode> nodes;
  final String? errorMessage;

  const StudyNodesState({
    this.status = StudyNodesStatus.initial,
    this.nodes = const [],
    this.errorMessage,
  });

  StudyNodesState copyWith({
    StudyNodesStatus? status,
    List<StudyNode>? nodes,
    String? errorMessage,
  }) {
    return StudyNodesState(
      status: status ?? this.status,
      nodes: nodes ?? this.nodes,
      errorMessage: errorMessage,
    );
  }
}

class StudyNodesController extends ChangeNotifier {
  final String trackId;
  final StudyNodeRepository repository;

  StudyNodesState _state = const StudyNodesState();

  StudyNodesController({required this.trackId, required this.repository});

  StudyNodesState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(
      status: StudyNodesStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final nodes = await repository.getForTrack(trackId);

      _state = _state.copyWith(
        status: nodes.isEmpty ? StudyNodesStatus.empty : StudyNodesStatus.data,
        nodes: nodes,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        status: StudyNodesStatus.error,
        errorMessage: 'Não foi possível carregar os tópicos.',
      );
    }

    notifyListeners();
  }

  Future<void> createNode({
    required String title,
    required String description,
    String? parentId,
  }) async {
    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError('O título do tópico é obrigatório.');
    }

    final node = StudyNode(
      id: 'node-${DateTime.now().microsecondsSinceEpoch}-${state.nodes.length}',
      trackId: trackId,
      parentId: parentId,
      title: normalizedTitle,
      description: description.trim(),
      sortOrder: state.nodes.length,
    );

    await repository.create(node);
    await load();
  }
}
