enum StudyMaterialType { flashcard, question, challenge, document, diagram }

class StudyMaterial {
  final String id;
  final StudyMaterialType type;
  final String title;
  final String subtitle;

  const StudyMaterial({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });
}

class StudyMaterialLink {
  final String nodeId;
  final String materialId;
  final StudyMaterialType materialType;

  const StudyMaterialLink({
    required this.nodeId,
    required this.materialId,
    required this.materialType,
  });

  @override
  bool operator ==(Object other) {
    return other is StudyMaterialLink &&
        other.nodeId == nodeId &&
        other.materialId == materialId &&
        other.materialType == materialType;
  }

  @override
  int get hashCode => Object.hash(nodeId, materialId, materialType);
}
