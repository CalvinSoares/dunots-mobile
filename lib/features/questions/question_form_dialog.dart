import 'package:flutter/material.dart';

import 'domain/question.dart';
import 'domain/quiz_exam.dart';

class QuestionFormData {
  final Question question;

  const QuestionFormData(this.question);
}

class QuestionFormDialog extends StatefulWidget {
  final Question? initialQuestion;
  final List<QuizExam> exams;

  const QuestionFormDialog({
    super.key,
    this.initialQuestion,
    this.exams = const [],
  });

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  late final TextEditingController numberController;
  late final TextEditingController statementController;
  late final TextEditingController explanationController;
  late final TextEditingController contestController;
  late final TextEditingController roleController;
  late final TextEditingController topicController;
  late final TextEditingController subjectController;
  late final TextEditingController examController;
  late final TextEditingController notesController;
  late final TextEditingController sourceController;
  late final TextEditingController sourcePageController;
  late final List<TextEditingController> alternativeControllers;
  late int correctAlternativeIndex;
  String? selectedExamId;
  String? validationError;

  bool get isEditing => widget.initialQuestion != null;

  @override
  void initState() {
    super.initState();
    final question = widget.initialQuestion;
    numberController = TextEditingController(
      text: question?.number?.toString() ?? '',
    );
    statementController = TextEditingController(text: question?.statement);
    explanationController = TextEditingController(text: question?.explanation);
    contestController = TextEditingController(text: question?.contest);
    roleController = TextEditingController(text: question?.role);
    topicController = TextEditingController(text: question?.topic);
    subjectController = TextEditingController(text: question?.subject);
    examController = TextEditingController(text: question?.exam);
    notesController = TextEditingController(text: question?.notes);
    sourceController = TextEditingController(text: question?.sourceName);
    sourcePageController = TextEditingController(
      text: question?.sourcePage?.toString() ?? '',
    );
    selectedExamId = question?.examId;
    final alternatives = question?.alternatives ?? const <String>[];
    alternativeControllers = List.generate(
      5,
      (index) => TextEditingController(
        text: index < alternatives.length ? alternatives[index] : '',
      ),
    );
    correctAlternativeIndex = question?.correctAlternativeIndex ?? 0;
  }

  @override
  void dispose() {
    numberController.dispose();
    statementController.dispose();
    explanationController.dispose();
    contestController.dispose();
    roleController.dispose();
    topicController.dispose();
    subjectController.dispose();
    examController.dispose();
    notesController.dispose();
    sourceController.dispose();
    sourcePageController.dispose();
    for (final controller in alternativeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Editar questão' : 'Nova questão'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Número',
                        hintText: 'Ex.: 42',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: roleController,
                      decoration: const InputDecoration(labelText: 'Cargo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contestController,
                decoration: const InputDecoration(labelText: 'Concurso'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: 'Tópico',
                  hintText: 'Ex.: Redes, Banco de Dados, Segurança',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(
                  labelText: 'Disciplina/assunto',
                  hintText: 'Ex.: Redes de Computadores',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: examController,
                decoration: const InputDecoration(
                  labelText: 'Prova/versão',
                  hintText: 'Ex.: Prova 6, versão A',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue:
                    widget.exams.any((exam) => exam.id == selectedExamId)
                    ? selectedExamId
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Vínculo com prova/vaga *',
                  helperText:
                      'Escolha uma prova ou deixe explícito como avulsa.',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Questão avulsa (sem prova)'),
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
              TextField(
                controller: statementController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Enunciado *',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Alternativas A–E',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              const SizedBox(height: 8),
              ...alternativeControllers.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: '${String.fromCharCode(65 + entry.key)} *',
                    ),
                  ),
                );
              }),
              DropdownButtonFormField<int>(
                initialValue: correctAlternativeIndex,
                decoration: const InputDecoration(labelText: 'Gabarito *'),
                items: List.generate(
                  5,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(String.fromCharCode(65 + index)),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => correctAlternativeIndex = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: explanationController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Explicação do gabarito',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Anotações privadas',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: sourceController,
                      decoration: const InputDecoration(labelText: 'Fonte'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: sourcePageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Página'),
                    ),
                  ),
                ],
              ),
              if (validationError != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    validationError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
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
        FilledButton(
          onPressed: _submit,
          child: Text(isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }

  void _submit() {
    final statement = statementController.text.trim();
    final alternatives = alternativeControllers
        .map((controller) => controller.text.trim())
        .toList(growable: false);
    final numberText = numberController.text.trim();
    final number = numberText.isEmpty ? null : int.tryParse(numberText);
    final sourcePageText = sourcePageController.text.trim();
    final sourcePage = sourcePageText.isEmpty
        ? null
        : int.tryParse(sourcePageText);

    if (statement.isEmpty) {
      setState(() => validationError = 'Informe o enunciado.');
      return;
    }
    if (numberText.isNotEmpty && number == null) {
      setState(() => validationError = 'O número deve ser inteiro.');
      return;
    }
    if (sourcePageText.isNotEmpty && sourcePage == null) {
      setState(() => validationError = 'A página deve ser inteira.');
      return;
    }
    if (alternatives.any((alternative) => alternative.isEmpty)) {
      setState(() => validationError = 'Preencha as cinco alternativas.');
      return;
    }

    final current = widget.initialQuestion;
    Navigator.of(context).pop(
      QuestionFormData(
        Question(
          id:
              current?.id ??
              'question-${DateTime.now().microsecondsSinceEpoch}',
          number: number,
          statement: statement,
          alternatives: alternatives,
          correctAlternativeIndex: correctAlternativeIndex,
          explanation: explanationController.text.trim(),
          contest: contestController.text.trim(),
          role: roleController.text.trim(),
          topic: topicController.text.trim(),
          exam: examController.text.trim(),
          examId: selectedExamId,
          subject: subjectController.text.trim(),
          notes: notesController.text.trim(),
          sourceName: _optional(sourceController.text),
          sourcePage: sourcePage,
          createdAt: current?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
