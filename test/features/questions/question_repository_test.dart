import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/data/question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';

void main() {
  test('o repositório em memória conserva uma questão criada', () async {
    final repository = InMemoryQuestionRepository(questions: const []);
    final question = Question(
      id: 'question-test',
      number: 42,
      statement: 'Qual é a máscara de uma rede /23?',
      alternatives: const ['255.255.254.0', '255.255.255.0'],
      correctAlternativeIndex: 0,
      explanation: 'Um prefixo /23 reserva 23 bits para a rede.',
      contest: 'Teste',
      role: 'Infraestrutura',
      createdAt: DateTime(2026, 9, 30),
    );

    await repository.create(question);

    expect((await repository.getAll()).single.statement, question.statement);
    expect((await repository.getAll()).single.correctAlternativeIndex, 0);

    await repository.update(
      question.copyWith(statement: 'Enunciado atualizado'),
    );
    expect(
      (await repository.getAll()).single.statement,
      'Enunciado atualizado',
    );

    await repository.delete(question.id);
    expect(await repository.getAll(), isEmpty);
  });
}
