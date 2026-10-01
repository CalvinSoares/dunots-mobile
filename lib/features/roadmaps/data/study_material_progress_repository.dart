import '../domain/study_material.dart';
import '../domain/study_material_completion.dart';

abstract interface class StudyMaterialProgressRepository {
  Future<List<StudyMaterialCompletion>> getForNode(String nodeId);
  Future<bool> isCompleted(StudyMaterialLink link);
  Future<void> markCompleted(StudyMaterialLink link, {DateTime? completedAt});
  Future<void> deleteForNode(String nodeId);
}

class InMemoryStudyMaterialProgressRepository
    implements StudyMaterialProgressRepository {
  final List<StudyMaterialCompletion> _items;

  InMemoryStudyMaterialProgressRepository({
    List<StudyMaterialCompletion>? items,
  }) : _items = List.of(items ?? const []);

  @override
  Future<List<StudyMaterialCompletion>> getForNode(String nodeId) async =>
      List.unmodifiable(_items.where((item) => item.nodeId == nodeId));

  @override
  Future<bool> isCompleted(StudyMaterialLink link) async => _items.any(
    (item) =>
        item.nodeId == link.nodeId &&
        item.materialId == link.materialId &&
        item.materialType == link.materialType,
  );

  @override
  Future<void> markCompleted(
    StudyMaterialLink link, {
    DateTime? completedAt,
  }) async {
    final now = completedAt ?? DateTime.now().toUtc();
    final index = _items.indexWhere(
      (item) =>
          item.nodeId == link.nodeId &&
          item.materialId == link.materialId &&
          item.materialType == link.materialType,
    );
    final completion = StudyMaterialCompletion(
      nodeId: link.nodeId,
      materialId: link.materialId,
      materialType: link.materialType,
      completedAt: now,
      updatedAt: now,
    );
    if (index < 0) {
      _items.add(completion);
    } else {
      _items[index] = completion;
    }
  }

  @override
  Future<void> deleteForNode(String nodeId) async {
    _items.removeWhere((item) => item.nodeId == nodeId);
  }
}
