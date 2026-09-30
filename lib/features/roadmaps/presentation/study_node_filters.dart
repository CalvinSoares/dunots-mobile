import '../domain/study_node.dart';

enum StudyNodeCompletionFilter { all, pending, completed }

class StudyNodeFilters {
  const StudyNodeFilters._();

  static List<StudyNode> apply({
    required List<StudyNode> nodes,
    String query = '',
    StudyPriority? priority,
    StudyNodeCompletionFilter completion = StudyNodeCompletionFilter.all,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final matchingIds = <String>{};

    for (final node in nodes) {
      final textMatches =
          normalizedQuery.isEmpty ||
          '${node.title} ${node.description} ${node.notes}'
              .toLowerCase()
              .contains(normalizedQuery);
      final priorityMatches = priority == null || node.priority == priority;
      final completionMatches = switch (completion) {
        StudyNodeCompletionFilter.all => true,
        StudyNodeCompletionFilter.pending => !node.isCompleted,
        StudyNodeCompletionFilter.completed => node.isCompleted,
      };

      if (textMatches && priorityMatches && completionMatches) {
        matchingIds.add(node.id);
      }
    }

    var addedAncestor = true;
    while (addedAncestor) {
      addedAncestor = false;

      for (final node in nodes) {
        if (matchingIds.contains(node.id) &&
            node.parentId != null &&
            matchingIds.add(node.parentId!)) {
          addedAncestor = true;
        }
      }
    }

    return nodes.where((node) => matchingIds.contains(node.id)).toList();
  }
}
