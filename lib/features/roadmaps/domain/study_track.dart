class StudyTrack {
  final String id;
  final String title;
  final String description;
  final int completedItems;
  final int totalItems;

  const StudyTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.completedItems,
    required this.totalItems,
  });

  double get progress {
    if (totalItems == 0) {
      return 0;
    }

    return completedItems / totalItems;
  }

  String get progressLabel => '$completedItems/$totalItems itens concluídos';
}
