import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/questions/domain/quiz_exam.dart';
import 'package:dunots_mobile/features/questions/question_filters.dart';

void main() {
  final questions = [
    Question(
      id: 'q-1',
      number: 1,
      statement: 'Qual protocolo resolve nomes?',
      alternatives: const ['DNS', 'HTTP'],
      correctAlternativeIndex: 0,
      explanation: '',
      contest: 'Transpetro',
      role: 'Redes',
      exam: 'Transpetro 2023',
      examId: 'exam-1',
      createdAt: DateTime(2026, 9, 30),
    ),
    Question(
      id: 'q-2',
      number: 2,
      statement: 'O que é uma VLAN?',
      alternatives: const ['Rede lógica', 'Cabo'],
      correctAlternativeIndex: 0,
      explanation: '',
      contest: 'Dataprev',
      role: 'Segurança',
      exam: 'Dataprev 2026',
      examId: 'exam-2',
      createdAt: DateTime(2026, 9, 30),
    ),
  ];

  test('filtra por busca, concurso e cargo', () {
    expect(QuestionFilters(search: 'vlan').apply(questions).single.id, 'q-2');
    expect(
      QuestionFilters(contest: 'Transpetro').apply(questions).single.id,
      'q-1',
    );
    expect(
      QuestionFilters(role: 'Segurança').apply(questions).single.id,
      'q-2',
    );
  });

  test('filtra diretamente por prova, banca, ano e versão', () {
    final exams = [
      QuizExam(
        id: 'exam-1',
        title: 'Transpetro 2023',
        contestName: 'Transpetro',
        vacancy: 'Redes',
        board: 'Cesgranrio',
        year: 2023,
        proofVersion: '6',
        createdAt: DateTime(2026, 9, 30),
      ),
      QuizExam(
        id: 'exam-2',
        title: 'Dataprev 2026',
        contestName: 'Dataprev',
        vacancy: 'Segurança',
        board: 'FGV',
        year: 2026,
        proofVersion: '1',
        createdAt: DateTime(2026, 9, 30),
      ),
    ];

    final filters = QuestionFilters(
      examId: 'exam-1',
      board: 'Cesgranrio',
      year: 2023,
      proofVersion: '6',
    );
    expect(filters.apply(questions, exams: exams).single.id, 'q-1');
    expect(
      QuestionFilters(board: 'FGV').apply(questions, exams: exams).single.id,
      'q-2',
    );
  });
}
