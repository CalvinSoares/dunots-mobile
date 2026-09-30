import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/data/quiz_exam_repository.dart';
import 'package:dunots_mobile/features/questions/domain/quiz_exam.dart';

void main() {
  test('o repositório conserva os dados da prova/vaga', () async {
    final repository = InMemoryQuizExamRepository();
    final exam = QuizExam(
      id: 'exam-6',
      title: 'Transpetro 2023',
      contestName: 'Transpetro',
      vacancy: 'Análise de Sistemas - Infraestrutura',
      board: 'Cesgranrio',
      year: 2023,
      proofVersion: 'Prova 6',
      sourceName: 'prova.pdf',
      answerKeyName: 'gabarito.pdf',
      createdAt: DateTime(2026, 9, 30),
    );

    await repository.create(exam);
    expect((await repository.getAll()).single.vacancy, exam.vacancy);
    expect((await repository.getAll()).single.answerKeyName, 'gabarito.pdf');

    await repository.update(exam.copyWith(title: 'Transpetro atualizada'));
    expect((await repository.getAll()).single.title, 'Transpetro atualizada');

    await repository.delete(exam.id);
    expect(await repository.getAll(), isEmpty);
  });
}
