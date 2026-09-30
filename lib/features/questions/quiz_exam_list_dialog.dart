import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import 'data/quiz_exam_repository.dart';
import 'domain/quiz_exam.dart';
import 'quiz_exam_form_dialog.dart';

class QuizExamListDialog extends StatefulWidget {
  final QuizExamRepository repository;

  const QuizExamListDialog({super.key, required this.repository});

  @override
  State<QuizExamListDialog> createState() => _QuizExamListDialogState();
}

class _QuizExamListDialogState extends State<QuizExamListDialog> {
  late Future<List<QuizExam>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Provas e vagas'),
      content: SizedBox(
        width: 620,
        height: 460,
        child: FutureBuilder<List<QuizExam>>(
          future: _examsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const StudyLoadingState(message: 'Carregando provas...');
            }
            if (snapshot.hasError) {
              return StudyErrorState(
                message: 'Não foi possível carregar as provas.',
                onRetry: () => setState(_reload),
              );
            }
            final exams = snapshot.data ?? const <QuizExam>[];
            if (exams.isEmpty) {
              return const StudyEmptyState(
                title: 'Nenhuma prova cadastrada.',
                detail: 'Crie uma prova/vaga para vincular novas questões.',
                icon: Icons.folder_outlined,
              );
            }
            return ListView.separated(
              itemCount: exams.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final exam = exams[index];
                return Card(
                  child: ListTile(
                    title: Text(exam.title),
                    subtitle: Text(
                      [
                        if (exam.contestName.isNotEmpty) exam.contestName,
                        if (exam.vacancy.isNotEmpty) exam.vacancy,
                        if (exam.proofVersion?.isNotEmpty == true)
                          exam.proofVersion!,
                        if (exam.year != null) '${exam.year}',
                      ].join(' · '),
                    ),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Editar prova',
                          onPressed: () => _edit(exam),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Excluir prova',
                          onPressed: () => _delete(exam),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: const Text('Nova prova/vaga'),
        ),
      ],
    );
  }

  void _reload() {
    _examsFuture = widget.repository.getAll();
  }

  Future<void> _create() async {
    final data = await showDialog<QuizExamFormData>(
      context: context,
      builder: (_) => const QuizExamFormDialog(),
    );
    if (data == null || !mounted) return;
    await widget.repository.create(data.exam);
    if (mounted) setState(_reload);
  }

  Future<void> _edit(QuizExam exam) async {
    final data = await showDialog<QuizExamFormData>(
      context: context,
      builder: (_) => QuizExamFormDialog(initialExam: exam),
    );
    if (data == null || !mounted) return;
    await widget.repository.update(data.exam);
    if (mounted) setState(_reload);
  }

  Future<void> _delete(QuizExam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir prova/vaga?'),
        content: const Text(
          'As questões vinculadas serão preservadas como avulsas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.repository.delete(exam.id);
    if (mounted) setState(_reload);
  }
}
