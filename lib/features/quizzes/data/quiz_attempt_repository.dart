import '../domain/quiz_attempt.dart';

abstract interface class QuizAttemptRepository {
  Future<List<QuizAttempt>> getAll();

  Future<void> create(QuizAttempt attempt);

  Future<void> update(QuizAttempt attempt);

  Future<void> delete(String id);
}

class InMemoryQuizAttemptRepository implements QuizAttemptRepository {
  final List<QuizAttempt> _attempts;

  InMemoryQuizAttemptRepository({List<QuizAttempt>? attempts})
    : _attempts = List.of(attempts ?? const []);

  @override
  Future<List<QuizAttempt>> getAll() async => List.unmodifiable(_attempts);

  @override
  Future<void> create(QuizAttempt attempt) async {
    _attempts.add(attempt);
  }

  @override
  Future<void> update(QuizAttempt attempt) async {
    final index = _attempts.indexWhere((item) => item.id == attempt.id);
    if (index == -1) {
      throw StateError('Simulado não encontrado: ${attempt.id}');
    }
    _attempts[index] = attempt;
  }

  @override
  Future<void> delete(String id) async {
    _attempts.removeWhere((attempt) => attempt.id == id);
  }
}
