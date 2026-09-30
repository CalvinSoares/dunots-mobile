import 'package:flutter/material.dart';

import 'domain/question.dart';
import 'domain/quiz_exam.dart';
import 'question_bulk_parser.dart';

class QuestionBulkFormData {
  final List<Question> questions;

  const QuestionBulkFormData(this.questions);
}

class QuestionBulkFormDialog extends StatefulWidget {
  final List<QuizExam> exams;

  const QuestionBulkFormDialog({super.key, this.exams = const []});

  @override
  State<QuestionBulkFormDialog> createState() => _QuestionBulkFormDialogState();
}

class _QuestionBulkFormDialogState extends State<QuestionBulkFormDialog> {
  late final TextEditingController inputController;
  late final TextEditingController subjectController;
  late final TextEditingController topicController;
  String? selectedExamId;
  late BulkQuestionParseResult parseResult;

  @override
  void initState() {
    super.initState();
    inputController = TextEditingController();
    subjectController = TextEditingController();
    topicController = TextEditingController();
    parseResult = parseBulkQuestions('');
  }

  @override
  void dispose() {
    inputController.dispose();
    subjectController.dispose();
    topicController.dispose();
    super.dispose();
  }

  bool get canSave =>
      parseResult.isValid && subjectController.text.trim().isNotEmpty;

  QuizExam? get selectedExam {
    for (final exam in widget.exams) {
      if (exam.id == selectedExamId) return exam;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedExam;
    return AlertDialog(
      title: const Text('Cadastro rápido em massa'),
      content: SizedBox(
        width: 780,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cole as questões no formato indicado. O preview é atualizado antes de qualquer gravação.',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                initialValue: selectedExamId,
                decoration: const InputDecoration(
                  labelText: 'Prova/vaga',
                  helperText: 'Pode deixar explícito como questão avulsa.',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Questões avulsas (sem prova)'),
                  ),
                  ...widget.exams.map(
                    (exam) => DropdownMenuItem<String?>(
                      value: exam.id,
                      child: Text(
                        '${exam.title}${exam.proofVersion == null ? '' : ' · ${exam.proofVersion}'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => selectedExamId = value),
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
                      decoration: const InputDecoration(labelText: 'Tópico'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: inputController,
                minLines: 10,
                maxLines: 18,
                onChanged: (value) {
                  setState(() => parseResult = parseBulkQuestions(value));
                },
                decoration: const InputDecoration(
                  labelText: 'Questões *',
                  hintText: 'Cole aqui o texto das questões...',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              _FormatDisclaimer(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Prévia reconhecida',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${parseResult.questions.length} questão(ões)',
                    style: const TextStyle(color: Color(0xFFB6B7AD)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (parseResult.questions.isEmpty)
                const _PreviewMessage(
                  icon: Icons.info_outline,
                  message: 'Cole um conteúdo para gerar a prévia.',
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: parseResult.questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _QuestionPreviewCard(
                        question: parseResult.questions[index],
                      );
                    },
                  ),
                ),
              if (parseResult.errors.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Corrija antes de salvar:',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      ...parseResult.errors.map((error) => Text('• $error')),
                    ],
                  ),
                ),
              ],
              if (selected == null && widget.exams.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Nenhuma prova selecionada: as questões serão salvas como avulsas.',
                  style: TextStyle(color: Color(0xFFFFC857)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: canSave ? _submit : null,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Criar questões'),
        ),
      ],
    );
  }

  void _submit() {
    if (!canSave) return;
    final exam = selectedExam;
    final now = DateTime.now();
    final subject = subjectController.text.trim();
    final topic = topicController.text.trim();
    final questions = parseResult.questions
        .asMap()
        .entries
        .map((entry) {
          final parsed = entry.value;
          final createdAt = now.add(Duration(microseconds: entry.key));
          return Question(
            id: 'question-${createdAt.microsecondsSinceEpoch}',
            number: parsed.number,
            statement: parsed.statement,
            alternatives: parsed.alternatives
                .map((alternative) => alternative.text)
                .toList(growable: false),
            correctAlternativeIndex: parsed.correctAlternativeIndex!,
            explanation: '',
            contest: exam?.contestName ?? '',
            role: exam?.vacancy ?? '',
            topic: topic,
            exam: exam?.title ?? '',
            examId: exam?.id,
            subject: subject,
            createdAt: createdAt,
            updatedAt: createdAt,
          );
        })
        .toList(growable: false);
    Navigator.of(context).pop(QuestionBulkFormData(questions));
  }
}

class _FormatDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        border: Border.all(color: const Color(0xFF4A504B)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Formato aceito:\n'
        '1. Enunciado da questão\n'
        'A) Alternativa A\n'
        'B) Alternativa B [x]\n'
        'C) Alternativa C\n\n'
        'Use X, [x] ou * na alternativa correta. Também é possível informar '
        '“Gabarito: 1-B, 2-C” ao final.',
        style: TextStyle(fontSize: 12, height: 1.45),
      ),
    );
  }
}

class _QuestionPreviewCard extends StatelessWidget {
  final BulkParsedQuestion question;

  const _QuestionPreviewCard({required this.question});

  @override
  Widget build(BuildContext context) {
    final hasError = question.error != null;
    return Card(
      color: hasError ? Theme.of(context).colorScheme.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questão ${question.number ?? '—'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              question.statement,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            ...question.alternatives.map(
              (alternative) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Icon(
                      alternative.markedCorrect
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: alternative.markedCorrect
                          ? Colors.green
                          : const Color(0xFFB6B7AD),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text('${alternative.label}) ${alternative.text}'),
                    ),
                  ],
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 5),
              Text(
                question.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ] else ...[
              const SizedBox(height: 5),
              Text(
                'Gabarito: ${String.fromCharCode(65 + question.correctAlternativeIndex!)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _PreviewMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF78B8FF)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
