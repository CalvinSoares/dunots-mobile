import 'study_material.dart';

class StudyMaterialCompletion {
  final String nodeId;
  final String materialId;
  final StudyMaterialType materialType;
  final DateTime completedAt;
  final DateTime updatedAt;

  const StudyMaterialCompletion({
    required this.nodeId,
    required this.materialId,
    required this.materialType,
    required this.completedAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? completedAt;
}
