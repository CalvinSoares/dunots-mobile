import 'package:flutter/material.dart';

import '../../shared/widgets/dunots_modal.dart';
import 'domain/quiz_exam.dart';

class QuizExamFormData {
  final QuizExam exam;

  const QuizExamFormData(this.exam);
}

class QuizExamFormDialog extends StatefulWidget {
  final QuizExam? initialExam;

  const QuizExamFormDialog({super.key, this.initialExam});

  @override
  State<QuizExamFormDialog> createState() => _QuizExamFormDialogState();
}

class _QuizExamFormDialogState extends State<QuizExamFormDialog> {
  late final TextEditingController titleController;
  late final TextEditingController contestController;
  late final TextEditingController vacancyController;
  late final TextEditingController boardController;
  late final TextEditingController yearController;
  late final TextEditingController versionController;
  late final TextEditingController sourceController;
  late final TextEditingController answerKeyController;
  String? validationError;

  bool get isEditing => widget.initialExam != null;

  @override
  void initState() {
    super.initState();
    final exam = widget.initialExam;
    titleController = TextEditingController(text: exam?.title ?? '');
    contestController = TextEditingController(text: exam?.contestName ?? '');
    vacancyController = TextEditingController(text: exam?.vacancy ?? '');
    boardController = TextEditingController(text: exam?.board ?? '');
    yearController = TextEditingController(text: exam?.year?.toString() ?? '');
    versionController = TextEditingController(text: exam?.proofVersion ?? '');
    sourceController = TextEditingController(text: exam?.sourceName ?? '');
    answerKeyController = TextEditingController(
      text: exam?.answerKeyName ?? '',
    );
  }

  @override
  void dispose() {
    for (final controller in [
      titleController,
      contestController,
      vacancyController,
      boardController,
      yearController,
      versionController,
      sourceController,
      answerKeyController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: isEditing ? 'Editar prova/vaga' : 'Nova prova/vaga',
      subtitle: 'Identifique a prova para organizar questões e gabaritos.',
      icon: Icons.folder_outlined,
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Prova *',
              hintText: 'Ex.: Transpetro 2023',
            ),
          ),
          TextField(
            controller: contestController,
            decoration: const InputDecoration(labelText: 'Concurso'),
          ),
          TextField(
            controller: vacancyController,
            decoration: const InputDecoration(labelText: 'Cargo/vaga'),
          ),
          TextField(
            controller: boardController,
            decoration: const InputDecoration(labelText: 'Banca'),
          ),
          TextField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Ano'),
          ),
          TextField(
            controller: versionController,
            decoration: const InputDecoration(labelText: 'Versão'),
          ),
          TextField(
            controller: sourceController,
            decoration: const InputDecoration(
              labelText: 'Fonte',
              hintText: 'Ex.: PDF da banca',
            ),
          ),
          TextField(
            controller: answerKeyController,
            decoration: const InputDecoration(
              labelText: 'Gabarito',
              hintText: 'Ex.: gabarito-prova-6.pdf',
            ),
          ),
          if (validationError != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
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
    final title = titleController.text.trim();
    final yearText = yearController.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);
    if (title.isEmpty) {
      setState(() => validationError = 'Informe o nome da prova.');
      return;
    }
    if (yearText.isNotEmpty && year == null) {
      setState(() => validationError = 'O ano deve ser inteiro.');
      return;
    }
    final current = widget.initialExam;
    final now = DateTime.now();
    Navigator.of(context).pop(
      QuizExamFormData(
        QuizExam(
          id: current?.id ?? 'exam-${now.microsecondsSinceEpoch}',
          title: title,
          contestName: contestController.text.trim(),
          vacancy: vacancyController.text.trim(),
          board: _optional(boardController.text),
          year: year,
          proofVersion: _optional(versionController.text),
          sourceName: _optional(sourceController.text),
          answerKeyName: _optional(answerKeyController.text),
          createdAt: current?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
    );
  }

  String? _optional(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
