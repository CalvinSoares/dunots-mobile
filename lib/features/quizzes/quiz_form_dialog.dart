import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Novo simulado'),
      content: TextField(
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
