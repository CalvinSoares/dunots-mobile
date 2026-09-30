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
}
