import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/sync/quiz_sync_mappers.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/questions/domain/quiz_exam.dart';

void main() {
  test('converte prova/vaga no contrato compartilhado', () {
    final exam = QuizExam(
      id: 'exam-1',
      title: 'Transpetro 2023',
      contestName: 'Transpetro',
      vacancy: 'Infraestrutura',
      board: 'Cesgranrio',
      year: 2023,
      proofVersion: 'Prova 6',
      sourceName: 'prova.pdf',
      answerKeyName: 'gabarito.pdf',
      createdAt: DateTime(2026, 9, 30),
    );

    final record = QuizExamSyncMapper.toRecord(exam);
    final restored = QuizExamSyncMapper.fromRecord(record);

    expect(record.values['proofVersion'], 'Prova 6');
    expect(record.values['answerKeyName'], 'gabarito.pdf');
    expect(restored.vacancy, exam.vacancy);
    expect(restored.year, 2023);
  });

  test('converte questão para options/correctOption e restaura os campos', () {
    final question = Question(
      id: 'question-1',
      number: 39,
      statement: 'Qual é a resposta?',
      alternatives: const ['A1', 'B1', 'C1'],
      correctAlternativeIndex: 1,
      explanation: 'Porque B.',
      contest: 'Transpetro',
      role: 'Infraestrutura',
      topic: 'Redes',
      exam: 'Prova 6',
      examId: 'exam-1',
      subject: 'Redes de Computadores',
      notes: 'Revisar subnetting.',
      sourceName: 'prova.pdf',
      sourcePage: 39,
      visualImages: const ['diagram.png'],
      createdAt: DateTime(2026, 9, 30),
    );

    final record = QuestionSyncMapper.toRecord(question);
    final restored = QuestionSyncMapper.fromRecord(record);

    expect(record.values['correctOption'], 'B');
    expect((record.values['options'] as List).length, 3);
    expect(restored.alternatives, question.alternatives);
    expect(restored.correctAlternativeIndex, 1);
    expect(restored.examId, 'exam-1');
    expect(restored.notes, question.notes);
    expect(restored.sourcePage, 39);
    expect(restored.visualImages, ['diagram.png']);
  });
}
