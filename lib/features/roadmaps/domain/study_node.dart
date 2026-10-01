enum StudyPriority { none, low, medium, high, urgent }

class StudyNode {
  final String id;
  final String trackId;
  final String? parentId;
  final String title;
  final String description;
  final int sortOrder;
  final bool isCompleted;
  final String notes;
  final StudyPriority priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudyNode({
    required this.id,
    required this.trackId,
    required this.parentId,
    required this.title,
    required this.description,
    required this.sortOrder,
    this.isCompleted = false,
    this.notes = '',
    this.priority = StudyPriority.none,
    this.createdAt,
    this.updatedAt,
  });

  StudyNode copyWith({
    String? title,
    String? description,
    int? sortOrder,
    bool? isCompleted,
    String? notes,
    StudyPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyNode(
      id: id,
      trackId: trackId,
      parentId: parentId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
