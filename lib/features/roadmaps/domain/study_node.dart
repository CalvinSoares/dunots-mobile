enum StudyPriority { none, low, medium, high, urgent }

enum StudyNodeStatus { todo, inProgress, review, completed }

class StudyNode {
  final String id;
  final String trackId;
  final String? parentId;
  final String title;
  final String description;
  final int sortOrder;
  final bool isCompleted;
  final StudyNodeStatus status;
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
    this.status = StudyNodeStatus.todo,
    this.notes = '',
    this.priority = StudyPriority.none,
    this.createdAt,
    this.updatedAt,
  });

  StudyNode copyWith({
    String? parentId,
    bool replaceParentId = false,
    String? title,
    String? description,
    int? sortOrder,
    bool? isCompleted,
    StudyNodeStatus? status,
    String? notes,
    StudyPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyNode(
      id: id,
      trackId: trackId,
      parentId: replaceParentId ? parentId : this.parentId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
