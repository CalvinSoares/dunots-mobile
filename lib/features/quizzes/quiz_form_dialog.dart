import 'package:flutter/material.dart';

import '../../shared/widgets/dunots_modal.dart';

class QuizFormData {
  final String title;

  const QuizFormData(this.title);
}

class QuizFormDialog extends StatefulWidget {
  const QuizFormDialog({super.key});

  @override
  State<QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<QuizFormDialog> {
  late final TextEditingController titleController;
  String? validationError;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: 'Novo simulado',
      icon: Icons.quiz_outlined,
      // ignore: sort_child_properties_last
      child: TextField(
        controller: titleController,
        autofocus: true,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Nome do simulado *',
          hintText: 'Ex.: Revisão de redes',
          errorText: validationError,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Criar')),
      ],
    );
  }

  void _submit() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      setState(() => validationError = 'Informe um nome.');
      return;
    }
    Navigator.of(context).pop(QuizFormData(title));
  }
}
