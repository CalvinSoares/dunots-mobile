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

  Future<void> updateNode({
    required String id,
    required String title,
    required String description,
  }) async {
    final normalizedTitle = title.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError('O título do tópico é obrigatório.');
    }

    final current = state.nodes.firstWhere((node) => node.id == id);
    await repository.update(
      current.copyWith(title: normalizedTitle, description: description.trim()),
    );
    await load();
  }

  Future<void> deleteNode(String id) async {
    await repository.delete(id);
    await load();
  }

  Future<void> moveNode(String id, {required int direction}) async {
    if (direction != -1 && direction != 1) {
      throw ArgumentError('A direção deve ser -1 ou 1.');
    }

    final current = state.nodes.firstWhere((node) => node.id == id);
    final siblings =
        state.nodes.where((node) => node.parentId == current.parentId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final currentIndex = siblings.indexWhere((node) => node.id == id);
    final targetIndex = currentIndex + direction;

    if (currentIndex == -1 ||
        targetIndex < 0 ||
        targetIndex >= siblings.length) {
      return;
    }

    final target = siblings[targetIndex];
    await repository.update(current.copyWith(sortOrder: target.sortOrder));
    await repository.update(target.copyWith(sortOrder: current.sortOrder));
    await load();
  }
}
