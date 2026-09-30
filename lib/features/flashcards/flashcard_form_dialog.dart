import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';

import '../roadmaps/domain/study_material.dart';
import 'flashcard_material_link_dialog.dart';

class FlashcardFormDialog extends StatefulWidget {
  final Flashcard? initialCard;
  final List<StudyMaterial> availableMaterials;

  const FlashcardFormDialog({
    super.key,
    this.initialCard,
    this.availableMaterials = const [],
  });

  @override
  State<FlashcardFormDialog> createState() => _FlashcardFormDialogState();
}

class _FlashcardFormDialogState extends State<FlashcardFormDialog> {
  late final TextEditingController _frontController;
  late final TextEditingController _backController;
  late final TextEditingController _codeController;
  late final TextEditingController _tagsController;
  late Set<String> _linkedMaterialIds;
  String? _validationError;

  bool get _isEditing => widget.initialCard != null;

  @override
  void initState() {
    super.initState();
    final card = widget.initialCard;
    _frontController = TextEditingController(text: card?.front ?? '');
    _backController = TextEditingController(text: card?.back ?? '');
    _codeController = TextEditingController(text: card?.code ?? '');
    _tagsController = TextEditingController(text: card?.tags.join(', ') ?? '');
    _linkedMaterialIds = {...?card?.linkedMaterialIds};
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _codeController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar flashcard' : 'Novo flashcard'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _frontController,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pergunta',
                  hintText: 'Frente do flashcard',
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: widget.availableMaterials.isEmpty
                      ? null
                      : _chooseMaterials,
                  icon: const Icon(Icons.link),
                  label: Text(
                    _linkedMaterialIds.isEmpty
                        ? 'Vincular questões e materiais'
                        : 'Materiais vinculados: ${_linkedMaterialIds.length}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _backController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Resposta',
                  hintText: 'Verso do flashcard',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeController,
                maxLines: 7,
                minLines: 3,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: 'Código (opcional)',
                  hintText: 'SQL, Java, Dart...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (opcional)',
                  hintText: 'Ex.: redes, SQL, revisão',
                  helperText: 'Separe as tags por vírgula.',
                ),
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _validationError!,
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
          child: Text(_isEditing ? 'Salvar' : 'Criar'),
        ),
      ],
    );
  }

  void _submit() {
    final front = _frontController.text.trim();
    final back = _backController.text.trim();
    if (front.isEmpty || back.isEmpty) {
      setState(
        () => _validationError = 'Pergunta e resposta são obrigatórias.',
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final current = widget.initialCard;
    final now = DateTime.now();
    Navigator.of(context).pop(
      (current ??
              Flashcard(
                id: 'card-${now.microsecondsSinceEpoch}',
                front: front,
                back: back,
                createdAt: now,
              ))
          .copyWith(
            front: front,
            back: back,
            code: _codeController.text.trim(),
            tags: tags,
            linkedMaterialIds: _linkedMaterialIds.toList(growable: false),
          ),
    );
  }

  Future<void> _chooseMaterials() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (_) => FlashcardMaterialLinkDialog(
        materials: widget.availableMaterials,
        initialSelectedIds: _linkedMaterialIds,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _linkedMaterialIds = selected.toSet());
    }
  }
}
