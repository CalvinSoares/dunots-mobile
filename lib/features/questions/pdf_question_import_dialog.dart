import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'domain/question.dart';
import 'domain/quiz_exam.dart';
import 'pdf_import_service.dart';
import 'question_bulk_parser.dart';

class PdfQuestionImportData {
  final List<Question> questions;

  const PdfQuestionImportData(this.questions);
}

class PdfQuestionImportDialog extends StatefulWidget {
  final List<QuizExam> exams;
  final PdfImportService service;

  const PdfQuestionImportDialog({
    super.key,
    required this.exams,
    this.service = const DefaultPdfImportService(),
  });

  @override
  State<PdfQuestionImportDialog> createState() =>
      _PdfQuestionImportDialogState();
}

class _PdfQuestionImportDialogState extends State<PdfQuestionImportDialog> {
  final subjectController = TextEditingController();
  final topicController = TextEditingController();
  String? selectedExamId;
  String? selectedVersion;
  PlatformFile? proofFile;
  PlatformFile? answerKeyFile;
  Uint8List? proofBytes;
  PdfExtractionResult? extraction;
  List<PdfAnswerKeyVariant> variants = const [];
  BulkQuestionParseResult parseResult = const BulkQuestionParseResult(
    questions: [],
    errors: [],
  );
  bool loading = false;
  String? error;

  QuizExam? get selectedExam {
    for (final exam in widget.exams) {
      if (exam.id == selectedExamId) return exam;
    }
    return null;
  }

  PdfAnswerKeyVariant? get selectedVariant {
    if (variants.isEmpty) return null;
    for (final variant in variants) {
      if (variant.version == selectedVersion) return variant;
    }
    return variants.first;
  }

  bool get canAnalyze =>
      proofFile != null &&
      answerKeyFile != null &&
      selectedExam != null &&
      !loading;

  bool get canSave =>
      extraction != null &&
      parseResult.questions.isNotEmpty &&
      parseResult.questions.every(_questionHasAnswer) &&
      subjectController.text.trim().isNotEmpty &&
      topicController.text.trim().isNotEmpty &&
      selectedExam != null &&
      !loading;

  @override
  void dispose() {
    subjectController.dispose();
    topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar prova e gabarito em PDF'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'A leitura é feita no dispositivo. O PDF da prova e o gabarito são associados pelo número da questão.',
              ),
              const SizedBox(height: 14),
              _FilePickerTile(
                label: 'PDF da prova *',
                file: proofFile,
                icon: Icons.picture_as_pdf_outlined,
                onPressed: loading ? null : () => _pickFile(false),
              ),
              const SizedBox(height: 8),
              _FilePickerTile(
                label: 'PDF do gabarito *',
                file: answerKeyFile,
                icon: Icons.fact_check_outlined,
                onPressed: loading ? null : () => _pickFile(true),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedExamId,
                decoration: const InputDecoration(
                  labelText: 'Prova/vaga *',
                  helperText: 'A importação sempre fica ligada a um agrupador.',
                ),
                items: widget.exams
                    .map(
                      (exam) => DropdownMenuItem<String>(
                        value: exam.id,
                        child: Text(
                          '${exam.title}${exam.proofVersion == null ? '' : ' · ${exam.proofVersion}'}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: loading
                    ? null
                    : (value) => setState(() => selectedExamId = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Disciplina/assunto *',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: topicController,
                      decoration: const InputDecoration(labelText: 'Tópico *'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: canAnalyze ? _analyze : null,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.manage_search),
                label: Text(loading ? 'Analisando PDFs...' : 'Analisar PDFs'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                _MessageBox(
                  message: error!,
                  color: Theme.of(context).colorScheme.errorContainer,
                  icon: Icons.error_outline,
                ),
              ],
              if (extraction != null) ...[
                const SizedBox(height: 16),
                _AnalysisSummary(
                  extraction: extraction!,
                  parseResult: parseResult,
                  selectedVariant: selectedVariant,
                ),
                if (variants.length > 1) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedVersion,
                    decoration: const InputDecoration(
                      labelText: 'Versão do gabarito',
                      helperText:
                          'Selecione a mesma versão identificada na prova.',
                    ),
                    items: variants
                        .map(
                          (variant) => DropdownMenuItem<String?>(
                            value: variant.version,
                            child: Text(variant.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedVersion = value),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    itemCount: parseResult.questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) => _PdfQuestionPreview(
                      question: parseResult.questions[index],
                      answer: _answerFor(parseResult.questions[index]),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const _PdfDisclaimer(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: canSave ? _submit : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Importar questões'),
        ),
      ],
    );
  }

  Future<void> _pickFile(bool answerKey) async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || !mounted) return;
    setState(() {
      if (answerKey) {
        answerKeyFile = result;
      } else {
        proofFile = result;
      }
      extraction = null;
      variants = const [];
      parseResult = const BulkQuestionParseResult(questions: [], errors: []);
      error = null;
    });
  }

  Future<void> _analyze() async {
    if (!canAnalyze) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final proof = await proofFile!.readAsBytes();
      final answerKey = await answerKeyFile!.readAsBytes();
      final parsedPdf = await widget.service.extract(proof);
      final parsedAnswers = await widget.service.readAnswerKey(answerKey);
      if (!parsedPdf.hasText) {
        throw StateError(
          'O PDF da prova não possui texto selecionável. OCR para PDFs escaneados será adicionado em uma etapa própria.',
        );
      }
      final parsedQuestions = parsePdfQuestions(parsedPdf);
      if (parsedQuestions.questions.isEmpty) {
        throw StateError('Nenhuma questão numerada foi encontrada no PDF.');
      }
      final detectedVersion =
          parsedPdf.proofVersion ?? selectedExam?.proofVersion;
      final preferred = _preferredVariant(parsedAnswers, detectedVersion);
      if (parsedAnswers.isEmpty) {
        throw StateError('Nenhuma resposta A–E foi encontrada no gabarito.');
      }
      if (!mounted) return;
      setState(() {
        proofBytes = proof;
        extraction = parsedPdf;
        parseResult = parsedQuestions;
        variants = parsedAnswers;
        selectedVersion = preferred?.version;
        loading = false;
      });
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = exception.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  PdfAnswerKeyVariant? _preferredVariant(
    List<PdfAnswerKeyVariant> values,
    String? detectedVersion,
  ) {
    if (detectedVersion != null) {
      for (final variant in values) {
        if (variant.version != null &&
            _normalizeVersion(variant.version!) ==
                _normalizeVersion(detectedVersion)) {
          return variant;
        }
      }
    }
    for (final variant in values) {
      if (variant.version == null) return variant;
    }
    return values.isEmpty ? null : values.first;
  }

  String _normalizeVersion(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\b(prova|vers(?:ão|ao)|caderno)\b'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  String? _answerFor(BulkParsedQuestion question) {
    final selected = selectedVariant;
    if (selected == null) return null;
    return selected.answerFor(question.number);
  }

  bool _questionHasAnswer(BulkParsedQuestion question) {
    if (question.error != null &&
        !question.error!.contains('informe o gabarito')) {
      return false;
    }
    final answer = _answerFor(question);
    return answer != null &&
        question.alternatives.any((alternative) => alternative.label == answer);
  }

  Future<void> _submit() async {
    if (!canSave || proofBytes == null) return;
    final exam = selectedExam!;
    final now = DateTime.now();
    final questions = <Question>[];
    for (var index = 0; index < parseResult.questions.length; index++) {
      final parsed = parseResult.questions[index];
      final answer = _answerFor(parsed)!;
      final correctIndex = parsed.alternatives.indexWhere(
        (alternative) => alternative.label == answer,
      );
      final shouldAttachPage = RegExp(
        r'figura|imagem|diagrama|tabela|gráfico|grafico|código|codigo',
        caseSensitive: false,
      ).hasMatch(parsed.statement);
      final image = shouldAttachPage && parsed.sourcePage != null
          ? await widget.service.renderPage(proofBytes!, parsed.sourcePage!)
          : null;
      final createdAt = now.add(Duration(microseconds: index));
      questions.add(
        Question(
          id: 'question-${createdAt.microsecondsSinceEpoch}',
          number: parsed.number,
          statement: parsed.statement,
          alternatives: parsed.alternatives
              .map((alternative) => alternative.text)
              .toList(growable: false),
          correctAlternativeIndex: correctIndex,
          explanation: '',
          contest: exam.contestName,
          role: exam.vacancy,
          topic: topicController.text.trim(),
          exam: exam.title,
          examId: exam.id,
          subject: subjectController.text.trim(),
          sourceName: proofFile?.name,
          sourcePage: parsed.sourcePage,
          visualImages: image == null ? const [] : [imageBytesToDataUri(image)],
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(PdfQuestionImportData(questions));
  }
}

class _FilePickerTile extends StatelessWidget {
  final String label;
  final PlatformFile? file;
  final IconData icon;
  final VoidCallback? onPressed;

  const _FilePickerTile({
    required this.label,
    required this.file,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          file == null ? label : '$label  ${file!.name}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AnalysisSummary extends StatelessWidget {
  final PdfExtractionResult extraction;
  final BulkQuestionParseResult parseResult;
  final PdfAnswerKeyVariant? selectedVariant;

  const _AnalysisSummary({
    required this.extraction,
    required this.parseResult,
    required this.selectedVariant,
  });

  @override
  Widget build(BuildContext context) {
    final ready = parseResult.questions.where((question) {
      final answer = selectedVariant?.answerFor(question.number);
      return question.error == null &&
          answer != null &&
          question.alternatives.any((item) => item.label == answer);
    }).length;
    return _MessageBox(
      icon: Icons.check_circle_outline,
      color: const Color(0xFF292D2A),
      message:
          '${extraction.pageCount} página(s) lida(s) · ${parseResult.questions.length} questão(ões) encontrada(s) · $ready pronta(s) com gabarito.',
    );
  }
}

class _PdfQuestionPreview extends StatelessWidget {
  final BulkParsedQuestion question;
  final String? answer;

  const _PdfQuestionPreview({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final valid =
        question.error == null &&
        answer != null &&
        question.alternatives.any((item) => item.label == answer);
    return Card(
      color: valid ? null : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questão ${question.number ?? '—'} · página ${question.sourcePage ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              question.statement,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 5),
            Text(
              valid
                  ? 'Gabarito: $answer'
                  : 'Não pronta: ${question.error ?? 'gabarito não encontrado ou incompatível.'}',
              style: TextStyle(
                color: valid
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfDisclaimer extends StatelessWidget {
  const _PdfDisclaimer();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Suporta PDFs digitais com questões numeradas, alternativas A–E, tabelas, blocos de código, imagens e duas colunas. Cabeçalhos, rodapés e marcas de página repetidos são removidos. PDFs escaneados ainda precisam de OCR.',
      style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFFB6B7AD)),
    );
  }
}

class _MessageBox extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;

  const _MessageBox({
    required this.message,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
