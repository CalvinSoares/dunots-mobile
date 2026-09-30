import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/questions/pdf_import_service.dart';
import 'package:dunots_mobile/features/questions/question_bulk_parser.dart';

void main() {
  test('associa o gabarito à versão correta da prova', () {
    final variants = parsePdfAnswerKey('''
PROVA 4 - ANÁLISE DE SISTEMAS
1 - A   2 - B   3 - C
PROVA 6 - ANÁLISE DE SISTEMAS
1 - D   2 - E   3 - A
''');

    expect(variants, hasLength(2));
    expect(variants.singleWhere((item) => item.version == '4').answers[2], 'B');
    expect(variants.singleWhere((item) => item.version == '6').answers[1], 'D');
  });

  test('detecta versão e preserva página ao ler número isolado', () {
    final version = detectPdfProofVersion(
      'PROVA 6 - ANÁLISE DE SISTEMAS - INFRAESTRUTURA',
    );
    final parsed = parseBulkQuestions('''
[[DUNOTS_PAGE:7]]
39
Qual alternativa está correta?
(A) Um
(B) Dois
(C) Três
Gabarito: 39-B
''', allowNumberOnly: true);

    expect(version, '6');
    expect(parsed.isValid, isTrue);
    expect(parsed.questions.single.number, 39);
    expect(parsed.questions.single.sourcePage, 7);
    expect(parsed.questions.single.correctAlternativeIndex, 1);
  });

  test('mantém blocos estruturados separados entre questões', () {
    final parsed = parseBulkQuestions('''
1. Qual comando é usado?
SELECT *
FROM tabela
A) Um
B) Dois
C) Três
Gabarito: 1-A
''');

    expect(parsed.isValid, isTrue);
    expect(
      parsed.questions.single.statement,
      contains('SELECT *\nFROM tabela'),
    );
  });

  test('aceita número e enunciado na mesma linha sem pontuação', () {
    final parsed = parseBulkQuestions('''
21 Uma questão extraída do cabeçalho do PDF
A) Um
B) Dois
C) Três
Gabarito: 21-C
''', allowNumberOnly: true);

    expect(parsed.isValid, isTrue);
    expect(parsed.questions.single.number, 21);
    expect(parsed.questions.single.statement, contains('Uma questão'));
    expect(parsed.questions.single.correctAlternativeIndex, 2);
  });
}
