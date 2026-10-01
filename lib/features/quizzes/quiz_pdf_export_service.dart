import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../questions/domain/question.dart';
import 'domain/quiz_attempt.dart';
import 'domain/quiz_attempt_result.dart';

/// Gera uma versão portátil da prova ou do resultado sem depender de uma
/// impressora, WebView ou serviço online.
class QuizPdfExportService {
  const QuizPdfExportService();

  Future<Uint8List> exportExam({
    required String title,
    required Iterable<Question> questions,
    bool includeAnswerKey = true,
    bool includeExplanations = false,
    bool includeNotes = false,
  }) async {
    final questionList = questions.toList(growable: false);
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln()
      ..writeln('Questões: ${questionList.length}')
      ..writeln();
    for (var index = 0; index < questionList.length; index++) {
      _writeQuestion(
        buffer,
        questionList[index],
        index,
        includeAnswerKey: includeAnswerKey,
        includeExplanations: includeExplanations,
        includeNotes: includeNotes,
      );
    }
    return _render(buffer.toString());
  }

  Future<Uint8List> exportResult({
    required QuizAttempt attempt,
    required Iterable<Question> questions,
    bool includeExplanations = true,
    bool includeNotes = true,
  }) async {
    final questionList = questions.toList(growable: false);
    final result = QuizAttemptResult.fromAttempt(attempt, questionList);
    final questionsById = {
      for (final question in questionList) question.id: question,
    };
    final buffer = StringBuffer()
      ..writeln('Resultado — ${attempt.title}')
      ..writeln()
      ..writeln('Aproveitamento: ${result.percentage.toStringAsFixed(0)}%')
      ..writeln('Acertos: ${result.correct}')
      ..writeln('Erros: ${result.incorrect}')
      ..writeln('Não respondidas: ${result.unanswered}')
      ..writeln();

    for (var index = 0; index < attempt.questionIds.length; index++) {
      final question = questionsById[attempt.questionIds[index]];
      if (question == null) continue;
      final answer = attempt.answers[question.id];
      buffer
        ..writeln('${index + 1}. ${question.statement}')
        ..writeln('Sua resposta: ${_label(answer)}')
        ..writeln('Gabarito: ${_label(question.correctAlternativeIndex)}')
        ..writeln(
          'Status: ${answer == null
              ? 'não respondida'
              : answer == question.correctAlternativeIndex
              ? 'acerto'
              : 'erro'}',
        );
      if (includeExplanations && question.explanation.trim().isNotEmpty) {
        buffer.writeln('Explicação: ${question.explanation}');
      }
      if (includeNotes && question.notes.trim().isNotEmpty) {
        buffer.writeln('Anotação: ${question.notes}');
      }
      buffer.writeln();
    }
    return _render(buffer.toString());
  }

  Future<Uri?> savePdf(Uint8List bytes, {required String fileName}) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'application/pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
  }

  void _writeQuestion(
    StringBuffer buffer,
    Question question,
    int index, {
    required bool includeAnswerKey,
    required bool includeExplanations,
    required bool includeNotes,
  }) {
    buffer.writeln('${question.number ?? index + 1}. ${question.statement}');
    for (
      var optionIndex = 0;
      optionIndex < question.alternatives.length;
      optionIndex++
    ) {
      buffer.writeln(
        '${_label(optionIndex)}) ${question.alternatives[optionIndex]}',
      );
    }
    if (includeAnswerKey) {
      buffer.writeln('Gabarito: ${_label(question.correctAlternativeIndex)}');
    }
    if (includeExplanations && question.explanation.trim().isNotEmpty) {
      buffer.writeln('Explicação: ${question.explanation}');
    }
    if (includeNotes && question.notes.trim().isNotEmpty) {
      buffer.writeln('Anotação: ${question.notes}');
    }
    if (question.visualImages.isNotEmpty || question.visualImage != null) {
      buffer.writeln('[Imagem/diagrama associado à questão]');
    }
    buffer.writeln();
  }

  Future<Uint8List> _render(String text) async {
    final document = sf.PdfDocument();
    try {
      text = _normalizePdfText(text);
      final font = sf.PdfStandardFont(sf.PdfFontFamily.helvetica, 9);
      final titleFont = sf.PdfStandardFont(
        sf.PdfFontFamily.helvetica,
        15,
        style: sf.PdfFontStyle.bold,
      );
      final page = document.pages.add();
      final size = page.getClientSize();
      final titleEnd = text.indexOf('\n');
      final title = titleEnd < 0 ? text : text.substring(0, titleEnd);
      final body = titleEnd < 0 ? '' : text.substring(titleEnd + 1);
      sf.PdfTextElement(
        text: title,
        font: titleFont,
      ).draw(page: page, bounds: Rect.fromLTWH(0, 0, size.width, 24));
      sf.PdfTextElement(text: body, font: font).draw(
        page: page,
        bounds: Rect.fromLTWH(0, 30, size.width, size.height - 30),
        format: sf.PdfLayoutFormat(layoutType: sf.PdfLayoutType.paginate),
      );
      return Uint8List.fromList(await document.save());
    } finally {
      document.dispose();
    }
  }

  String _label(int? index) {
    return index == null ? '—' : String.fromCharCode(65 + index);
  }

  String _normalizePdfText(String value) {
    return value
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('↔', '<->')
        .replaceAll('→', '->')
        .replaceAll('←', '<-');
  }
}
