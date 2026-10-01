import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'package:dunots_mobile/features/questions/domain/question.dart';
import 'package:dunots_mobile/features/quizzes/domain/quiz_attempt.dart';
import 'package:dunots_mobile/features/quizzes/quiz_pdf_export_service.dart';

void main() {
  final question = Question(
    id: 'q-1',
    number: 39,
    statement: 'Qual alternativa está correta sobre SQL?',
    alternatives: const ['A', 'B', 'C'],
    correctAlternativeIndex: 1,
    explanation: 'A alternativa B usa a regra correta.',
    contest: 'Transpetro',
    role: 'Infraestrutura',
    topic: 'Banco de dados',
    notes: 'Revisar joins.',
    createdAt: DateTime(2026, 9, 30),
  );

  test('exporta prova com gabarito, explicação e anotação', () async {
    const service = QuizPdfExportService();
    final bytes = await service.exportExam(
      title: 'Transpetro — Prova 6',
      questions: [question],
      includeAnswerKey: true,
      includeExplanations: true,
      includeNotes: true,
    );

    expect(bytes, isA<Uint8List>());
    final document = sf.PdfDocument(inputBytes: bytes);
    try {
      final text = sf.PdfTextExtractor(document).extractText();
      expect(text, contains('Transpetro - Prova 6'));
      expect(text, contains('Gabarito: B'));
      expect(text, contains('Revisar joins.'));
    } finally {
      document.dispose();
    }
  });

  test(
    'exporta resultado com aproveitamento e situação de cada resposta',
    () async {
      const service = QuizPdfExportService();
      final attempt = QuizAttempt(
        id: 'attempt-1',
        title: 'Simulado de SQL',
        questionIds: const ['q-1'],
        currentIndex: 0,
        status: QuizAttemptStatus.finished,
        answers: const {'q-1': 0},
        createdAt: DateTime(2026, 9, 30),
        updatedAt: DateTime(2026, 9, 30),
      );
      final bytes = await service.exportResult(
        attempt: attempt,
        questions: [question],
      );
      final document = sf.PdfDocument(inputBytes: bytes);
      try {
        final text = sf.PdfTextExtractor(document).extractText();
        expect(text, contains('Aproveitamento: 0%'));
        expect(text, contains('Sua resposta: A'));
        expect(text, contains('Gabarito: B'));
        expect(text, contains('Status: erro'));
      } finally {
        document.dispose();
      }
    },
  );
}
