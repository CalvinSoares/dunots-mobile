import 'domain/question.dart';

class QuestionFilters {
  const QuestionFilters({this.search = '', this.contest, this.role});

  final String search;
  final String? contest;
  final String? role;

  List<Question> apply(Iterable<Question> questions) {
    final normalizedSearch = search.trim().toLowerCase();
    return questions
        .where((question) {
          final matchesSearch =
              normalizedSearch.isEmpty ||
              '${question.number ?? ''} ${question.statement} '
                      '${question.contest} ${question.role} ${question.topic} '
                      '${question.exam} '
                      '${question.alternatives.join(' ')}'
                  .toLowerCase()
                  .contains(normalizedSearch);
          final matchesContest = contest == null || question.contest == contest;
          final matchesRole = role == null || question.role == role;
          return matchesSearch && matchesContest && matchesRole;
        })
        .toList(growable: false);
  }
}
