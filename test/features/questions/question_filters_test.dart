import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/domain/question.dart';
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
}
