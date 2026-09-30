import '../domain/study_node.dart';

abstract interface class StudyNodeRepository {
  Future<List<StudyNode>> getForTrack(String trackId);

  Future<void> create(StudyNode node);
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
}
