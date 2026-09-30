import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import 'question_bulk_parser.dart';

class PdfExtractedLine {
  final int pageNumber;
  final String text;
  final Rect bounds;

  const PdfExtractedLine({
    required this.pageNumber,
    required this.text,
    required this.bounds,
  });
}

class PdfExtractionResult {
  final String text;
  final int pageCount;
  final Map<int, List<PdfExtractedLine>> pages;
  final String? proofVersion;

  const PdfExtractionResult({
    required this.text,
    required this.pageCount,
    required this.pages,
    this.proofVersion,
  });

  bool get hasText => text.replaceAll(RegExp(r'\s'), '').isNotEmpty;
}

class PdfAnswerKeyVariant {
  final String? version;
  final Map<int, String> answers;

  const PdfAnswerKeyVariant({required this.version, required this.answers});

  String get label => version == null ? 'Gabarito comum' : 'Prova $version';

  String? answerFor(int? questionNumber) {
    if (questionNumber == null) return null;
    return answers[questionNumber];
  }
}

abstract interface class PdfImportService {
  Future<PdfExtractionResult> extract(Uint8List bytes);

  Future<List<PdfAnswerKeyVariant>> readAnswerKey(Uint8List bytes);

  Future<Uint8List?> renderPage(Uint8List bytes, int pageNumber);
}

/// Importador para PDFs digitais. A extração é feita por linhas para preservar
/// tabelas, blocos de código e a ordem de leitura de páginas com duas colunas.
class DefaultPdfImportService implements PdfImportService {
  const DefaultPdfImportService();

  @override
  Future<PdfExtractionResult> extract(Uint8List bytes) async {
    return _extract(bytes, cleanChrome: true);
  }

  @override
  Future<List<PdfAnswerKeyVariant>> readAnswerKey(Uint8List bytes) async {
    final extracted = await _extract(bytes, cleanChrome: false);
    return parsePdfAnswerKey(extracted.text);
  }

  @override
  Future<Uint8List?> renderPage(Uint8List bytes, int pageNumber) async {
    final document = await pdfx.PdfDocument.openData(bytes);
    try {
      if (pageNumber < 1 || pageNumber > document.pagesCount) return null;
      final page = await document.getPage(pageNumber);
      try {
        final scale = math.min(1.5, 1600 / page.width);
        final image = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 82,
        );
        return image?.bytes;
      } finally {
        await page.close();
      }
    } finally {
      await document.close();
    }
  }

  Future<PdfExtractionResult> _extract(
    Uint8List bytes, {
    required bool cleanChrome,
  }) async {
    final document = sf.PdfDocument(inputBytes: bytes);
    try {
      final extractedLines = sf.PdfTextExtractor(document).extractTextLines();
      final byPage = <int, List<PdfExtractedLine>>{};
      for (final line in extractedLines) {
        final text = _normalizeGlyphs(line.text).trimRight();
        if (text.trim().isEmpty) continue;
        final pageNumber = line.pageIndex + 1;
        byPage
            .putIfAbsent(pageNumber, () => [])
            .add(
              PdfExtractedLine(
                pageNumber: pageNumber,
                text: text,
                bounds: line.bounds,
              ),
            );
      }

      final pages = <int, List<PdfExtractedLine>>{};
      final rawVersion = detectPdfProofVersion(
        byPage.values
            .expand((page) => page)
            .map((line) => line.text)
            .join('\n'),
      );
      final repeatedChrome = cleanChrome ? _repeatedChrome(byPage) : <String>{};
      for (
        var pageNumber = 1;
        pageNumber <= document.pages.count;
        pageNumber++
      ) {
        var pageLines = [...?byPage[pageNumber]];
        if (cleanChrome) {
          pageLines = _removeChrome(pageLines, repeatedChrome);
        }
        pages[pageNumber] = _orderPage(pageLines);
      }

      final buffer = StringBuffer();
      for (
        var pageNumber = 1;
        pageNumber <= document.pages.count;
        pageNumber++
      ) {
        buffer.writeln('[[DUNOTS_PAGE:$pageNumber]]');
        for (final line in pages[pageNumber] ?? const <PdfExtractedLine>[]) {
          buffer.writeln(line.text);
        }
      }
      return PdfExtractionResult(
        text: buffer.toString(),
        pageCount: document.pages.count,
        pages: Map.unmodifiable(pages),
        proofVersion: rawVersion,
      );
    } finally {
      document.dispose();
    }
  }
}

List<PdfExtractedLine> _orderPage(List<PdfExtractedLine> lines) {
  if (lines.length < 10) {
    return [...lines]..sort(_compareReadingOrder);
  }
  final sortedByX = [...lines]
    ..sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
  var bestGap = 0.0;
  var splitX = 0.0;
  for (var index = 1; index < sortedByX.length; index++) {
    final gap =
        sortedByX[index].bounds.left - sortedByX[index - 1].bounds.right;
    if (gap > bestGap) {
      bestGap = gap;
      splitX =
          (sortedByX[index].bounds.left + sortedByX[index - 1].bounds.right) /
          2;
    }
  }
  final left = lines.where((line) => line.bounds.center.dx < splitX).toList();
  final right = lines.where((line) => line.bounds.center.dx >= splitX).toList();
  if (bestGap < 70 || left.length < 6 || right.length < 6) {
    return [...lines]..sort(_compareReadingOrder);
  }
  left.sort(_compareReadingOrder);
  right.sort(_compareReadingOrder);
  return [...left, ...right];
}

int _compareReadingOrder(PdfExtractedLine a, PdfExtractedLine b) {
  final top = a.bounds.top.compareTo(b.bounds.top);
  if (top != 0) return top;
  return a.bounds.left.compareTo(b.bounds.left);
}

Set<String> _repeatedChrome(Map<int, List<PdfExtractedLine>> byPage) {
  final counts = <String, int>{};
  for (final lines in byPage.values) {
    final seenOnPage = <String>{};
    for (final line in lines) {
      if (!_looksLikeChrome(line.text)) continue;
      seenOnPage.add(_lineKey(line.text));
    }
    for (final key in seenOnPage) {
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  final pageCount = byPage.length;
  return counts.entries
      .where(
        (entry) => entry.value >= 2 || (pageCount == 1 && entry.value == 1),
      )
      .map((entry) => entry.key)
      .toSet();
}

List<PdfExtractedLine> _removeChrome(
  List<PdfExtractedLine> lines,
  Set<String> repeatedChrome,
) {
  if (lines.isEmpty) return lines;
  final bottom = lines.map((line) => line.bounds.bottom).reduce(math.max);
  return lines.where((line) {
    final key = _lineKey(line.text);
    if (repeatedChrome.contains(key)) return false;
    if (_looksLikeChrome(line.text)) return false;
    if (RegExp(r'^\d{1,3}$').hasMatch(line.text.trim()) &&
        line.bounds.bottom >= bottom - 45) {
      return false;
    }
    return true;
  }).toList();
}

bool _looksLikeChrome(String value) {
  final normalized = _lineKey(value);
  if (normalized.isEmpty) return true;
  return normalized.contains('WWW.') ||
      normalized.contains('PCICONCURSOS') ||
      normalized.contains('TRANSPETRO') ||
      normalized == 'TERRA' ||
      normalized.startsWith('PROVA ') ||
      normalized.startsWith('CONHECIMENTOS ESPECIFICOS') ||
      normalized.startsWith('LINGUA INGLESA') ||
      normalized.startsWith('LINGUA PORTUGUESA') ||
      normalized.startsWith('ANALISE DE SISTEMAS');
}

String _lineKey(String value) {
  return _normalizeGlyphs(value)
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .toUpperCase();
}

String _normalizeGlyphs(String value) {
  return value
      .replaceAll('\uF028', '↔')
      .replaceAll('\uF0B7', '•')
      .replaceAll('\uF0D8', '▲')
      .replaceAll('\uF0D9', '▼')
      .replaceAll('\uFFFD', '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(' - ', ' – ');
}

String? detectPdfProofVersion(String value) {
  final match = RegExp(
    r'(?:PROVA|VERS(?:ÃO|AO)|CADERNO)\s*(?:N[ºO.]?\s*)?([0-9A-Z]+)',
    caseSensitive: false,
  ).firstMatch(value);
  return match?.group(1)?.trim();
}

List<PdfAnswerKeyVariant> parsePdfAnswerKey(String value) {
  final lines = value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final variants = <String?, Map<int, String>>{};
  String? currentVersion;
  void ensureVariant(String? version) {
    variants.putIfAbsent(version, () => <int, String>{});
  }

  ensureVariant(null);
  for (final rawLine in lines) {
    final line = _normalizeGlyphs(rawLine).trim();
    if (line.isEmpty) continue;
    final version = detectPdfProofVersion(line);
    if (version != null) {
      currentVersion = version;
      ensureVariant(currentVersion);
      // O título pode conter "6 - Administração" e parecer a resposta
      // "6-A" para a expressão regular. As respostas desse bloco serão lidas
      // nas linhas seguintes, evitando esse falso positivo.
      continue;
    }
    final pairPattern = RegExp(
      r'(\d{1,4})\s*(?:[-–—.:)]|\s)\s*([A-E])\b',
      caseSensitive: false,
    );
    for (final match in pairPattern.allMatches(line)) {
      variants[currentVersion]![int.parse(match.group(1)!)] = match
          .group(2)!
          .toUpperCase();
    }
  }
  variants.removeWhere((version, answers) => answers.isEmpty);
  final result = variants.entries
      .map(
        (entry) => PdfAnswerKeyVariant(
          version: entry.key,
          answers: Map.unmodifiable(entry.value),
        ),
      )
      .toList();
  result.sort((a, b) {
    if (a.version == null) return -1;
    if (b.version == null) return 1;
    return a.version!.compareTo(b.version!);
  });
  return List.unmodifiable(result);
}

BulkQuestionParseResult parsePdfQuestions(PdfExtractionResult extraction) {
  return parseBulkQuestions(extraction.text, allowNumberOnly: true);
}

String imageBytesToDataUri(Uint8List bytes) {
  return 'data:image/jpeg;base64,${base64Encode(bytes)}';
}
