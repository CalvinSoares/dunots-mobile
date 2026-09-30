import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/question_bulk_parser.dart';

void main() {
  test('reconhece questões numeradas, alternativas e X inline', () {
    final result = parseBulkQuestions('''
1. Qual alternativa está correta?
(A) Errada
(B) Correta [x]
(C) Outra
(D) Outra
(E) Outra
''');

    expect(result.isValid, isTrue);
    expect(result.questions, hasLength(1));
    expect(result.questions.single.statement, 'Qual alternativa está correta?');
    expect(result.questions.single.alternatives, hasLength(5));
    expect(result.questions.single.correctAlternativeIndex, 1);
  });

  test('associa o gabarito separado à questão correta', () {
    final result = parseBulkQuestions('''
1) Primeira questão
A) Um
B) Dois
C) Três

2. Segunda questão
A. Quatro
B. Cinco
C. Seis
Gabarito: 1-C, 2-A
''');

    expect(result.isValid, isTrue);
    expect(
      result.questions.map((question) => question.correctAlternativeIndex),
      [2, 0],
    );
  });

  test('aceita alternativas compactadas e rejeita gabarito inválido', () {
    final compact = parseBulkQuestions('''
3. Escolha uma opção
A.firmezaB.rispidezC.discriçãoD.desgostoE.incompreensão
Gabarito: C
''');
    expect(compact.isValid, isTrue);
    expect(compact.questions.single.alternatives, hasLength(5));
    expect(compact.questions.single.correctAlternativeIndex, 2);

    final invalid = parseBulkQuestions('''
4. Questão inválida
A) Um
B) Dois
Gabarito: 4-E
''');
    expect(invalid.isValid, isFalse);
    expect(invalid.errors.single, contains('não corresponde'));
  });

  test(
    'separa enunciado e alternativas quando o PDF trouxe tudo na mesma linha',
    () {
      final result = parseBulkQuestions(
        '5. Qual é a resposta? A) Uma B) Duas [x] C) Três D) Quatro E) Cinco',
      );

      expect(result.isValid, isTrue);
      expect(result.questions.single.statement, 'Qual é a resposta?');
      expect(result.questions.single.alternatives, hasLength(5));
      expect(result.questions.single.correctAlternativeIndex, 1);
    },
  );
}
