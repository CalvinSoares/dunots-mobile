import '../domain/study_node.dart';

/// Regras padrão de ordenação dos tópicos de uma trilha.
///
/// A prioridade é o critério principal. A ordem manual continua sendo
/// respeitada quando dois tópicos possuem a mesma prioridade, e os últimos
/// critérios tornam o resultado estável mesmo quando os dados chegam em outra
/// ordem do banco ou de um pacote de sincronização.
class StudyNodeOrdering {
  const StudyNodeOrdering._();

  static int compare(StudyNode first, StudyNode second) {
    final priority = priorityRank(second.priority)
        .compareTo(priorityRank(first.priority));
    if (priority != 0) return priority;

    final sortOrder = first.sortOrder.compareTo(second.sortOrder);
    if (sortOrder != 0) return sortOrder;

    final title = first.title.toLowerCase().compareTo(
      second.title.toLowerCase(),
    );
    if (title != 0) return title;

    return first.id.compareTo(second.id);
  }

  static int priorityRank(StudyPriority priority) {
    switch (priority) {
      case StudyPriority.none:
        return 0;
      case StudyPriority.low:
        return 1;
      case StudyPriority.medium:
        return 2;
      case StudyPriority.high:
        return 3;
      case StudyPriority.urgent:
        return 4;
    }
  }
}
