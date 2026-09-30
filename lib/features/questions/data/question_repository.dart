import '../domain/question.dart';
import '../question_demo_data.dart';

abstract interface class QuestionRepository {
  Future<List<Question>> getAll();

  Future<void> create(Question question);

  Future<void> createMany(List<Question> questions);

  Future<void> update(Question question);

  Future<void> delete(String id);
}

class InMemoryQuestionRepository implements QuestionRepository {
  final List<Question> _questions;

  InMemoryQuestionRepository({List<Question>? questions})
    : _questions = List.of(questions ?? demoQuestions);

  @override
  Future<List<Question>> getAll() async => List.unmodifiable(_questions);

  @override
  Future<void> create(Question question) async {
    _questions.add(question);
  }

  @override
  Future<void> createMany(List<Question> questions) async {
    _questions.addAll(questions);
  }

  @override
  Future<void> update(Question question) async {
    final index = _questions.indexWhere((item) => item.id == question.id);
    if (index == -1) {
      throw StateError('Questão não encontrada: ${question.id}');
    }
    _questions[index] = question;
  }

  @override
  Future<void> delete(String id) async {
    _questions.removeWhere((question) => question.id == id);
  }
}
