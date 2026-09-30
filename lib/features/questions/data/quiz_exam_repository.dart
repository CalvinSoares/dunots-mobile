import '../domain/quiz_exam.dart';

abstract interface class QuizExamRepository {
  Future<List<QuizExam>> getAll();

  Future<void> create(QuizExam exam);

  Future<void> update(QuizExam exam);

  Future<void> delete(String id);
}

class InMemoryQuizExamRepository implements QuizExamRepository {
  final List<QuizExam> _exams;

  InMemoryQuizExamRepository({List<QuizExam>? exams})
    : _exams = List.of(exams ?? const <QuizExam>[]);

  @override
  Future<List<QuizExam>> getAll() async => List.unmodifiable(_exams);

  @override
  Future<void> create(QuizExam exam) async {
    _exams.add(exam);
  }

  @override
  Future<void> update(QuizExam exam) async {
    final index = _exams.indexWhere((item) => item.id == exam.id);
    if (index == -1) {
      throw StateError('Prova não encontrada: ${exam.id}');
    }
    _exams[index] = exam;
  }

  @override
  Future<void> delete(String id) async {
    _exams.removeWhere((exam) => exam.id == id);
  }
}
