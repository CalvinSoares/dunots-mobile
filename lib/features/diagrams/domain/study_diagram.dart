class StudyDiagram {
  final String id;
  final String title;
  final String description;
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;
  final List<String> phaseIds;
  final List<String> flashcardIds;
  final List<String> problemIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyDiagram({
    required this.id,
    required this.title,
    this.description = '',
    this.nodes = const [],
    this.edges = const [],
    this.phaseIds = const [],
    this.flashcardIds = const [],
    this.problemIds = const [],
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  StudyDiagram copyWith({
    String? title,
    String? description,
    List<Map<String, dynamic>>? nodes,
    List<Map<String, dynamic>>? edges,
    List<String>? phaseIds,
    List<String>? flashcardIds,
    List<String>? problemIds,
    DateTime? updatedAt,
  }) => StudyDiagram(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    nodes: nodes ?? this.nodes,
    edges: edges ?? this.edges,
    phaseIds: phaseIds ?? this.phaseIds,
    flashcardIds: flashcardIds ?? this.flashcardIds,
    problemIds: problemIds ?? this.problemIds,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
