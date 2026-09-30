class StudyNode {
  final String id;
  final String trackId;
  final String? parentId;
  final String title;
  final String description;
  final int sortOrder;

  const StudyNode({
    required this.id,
    required this.trackId,
    required this.parentId,
    required this.title,
    required this.description,
    required this.sortOrder,
  });

  StudyNode copyWith({String? title, String? description, int? sortOrder}) {
    return StudyNode(
      id: id,
      trackId: trackId,
      parentId: parentId,
      title: title ?? this.title,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
