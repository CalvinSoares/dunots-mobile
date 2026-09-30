import '../domain/study_material.dart';

abstract interface class StudyMaterialRepository {
  Future<List<StudyMaterial>> getAll();
}

class InMemoryStudyMaterialRepository implements StudyMaterialRepository {
  final List<StudyMaterial> _materials;

  InMemoryStudyMaterialRepository({List<StudyMaterial>? materials})
    : _materials = List.of(materials ?? _defaultMaterials);

  @override
  Future<List<StudyMaterial>> getAll() async {
    return List.unmodifiable(_materials);
  }

  static const _defaultMaterials = [
    StudyMaterial(
      id: 'card-001',
      type: StudyMaterialType.flashcard,
      title: 'O que é independência de dados?',
      subtitle: 'Flashcard',
    ),
    StudyMaterial(
      id: 'card-002',
      type: StudyMaterialType.flashcard,
      title: 'Como funciona o protocolo TCP?',
      subtitle: 'Flashcard',
    ),
    StudyMaterial(
      id: 'question-001',
      type: StudyMaterialType.question,
      title: 'Qual é a função da camada de transporte?',
      subtitle: 'Questão · Redes',
    ),
    StudyMaterial(
      id: 'question-002',
      type: StudyMaterialType.question,
      title: 'Qual topologia usa um concentrador central?',
      subtitle: 'Questão · Infraestrutura',
    ),
    StudyMaterial(
      id: 'document-001',
      type: StudyMaterialType.document,
      title: 'Resumo de arquiteturas de rede',
      subtitle: 'Material de estudo',
    ),
  ];
}

abstract interface class StudyNodeMaterialRepository {
  Future<List<StudyMaterialLink>> getForNode(String nodeId);

  Future<void> replaceForNode(String nodeId, List<StudyMaterialLink> links);

  Future<void> deleteForNode(String nodeId);
}

class InMemoryStudyNodeMaterialRepository
    implements StudyNodeMaterialRepository {
  final List<StudyMaterialLink> _links;

  InMemoryStudyNodeMaterialRepository({List<StudyMaterialLink>? links})
    : _links = List.of(links ?? const []);

  @override
  Future<List<StudyMaterialLink>> getForNode(String nodeId) async {
    return List.unmodifiable(_links.where((link) => link.nodeId == nodeId));
  }

  @override
  Future<void> replaceForNode(
    String nodeId,
    List<StudyMaterialLink> links,
  ) async {
    _links.removeWhere((link) => link.nodeId == nodeId);
    _links.addAll(links);
  }

  @override
  Future<void> deleteForNode(String nodeId) async {
    _links.removeWhere((link) => link.nodeId == nodeId);
  }
}
