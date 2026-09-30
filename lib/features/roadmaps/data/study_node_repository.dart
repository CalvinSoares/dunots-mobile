import '../domain/study_node.dart';

abstract interface class StudyNodeRepository {
  Future<List<StudyNode>> getForTrack(String trackId);

  Future<void> create(StudyNode node);

  Future<void> update(StudyNode node);

  /// Removes the node and all descendants from the hierarchy.
  Future<void> delete(String nodeId);
}

class InMemoryStudyNodeRepository implements StudyNodeRepository {
  final List<StudyNode> _nodes;

  InMemoryStudyNodeRepository({List<StudyNode>? nodes})
    : _nodes = List.of(nodes ?? const []);

  @override
  Future<List<StudyNode>> getForTrack(String trackId) async {
    return List.unmodifiable(_nodes.where((node) => node.trackId == trackId));
  }

  @override
  Future<void> create(StudyNode node) async {
    _nodes.add(node);
  }

  @override
  Future<void> update(StudyNode node) async {
    final index = _nodes.indexWhere((current) => current.id == node.id);

    if (index == -1) {
      throw StateError('Tópico não encontrado.');
    }

    _nodes[index] = node;
  }

  @override
  Future<void> delete(String nodeId) async {
    final idsToDelete = <String>{nodeId};
    var foundDescendant = true;

    while (foundDescendant) {
      foundDescendant = false;

      for (final node in _nodes) {
        if (node.parentId != null && idsToDelete.contains(node.parentId)) {
          foundDescendant = idsToDelete.add(node.id) || foundDescendant;
        }
      }
    }

    _nodes.removeWhere((node) => idsToDelete.contains(node.id));
  }
}
