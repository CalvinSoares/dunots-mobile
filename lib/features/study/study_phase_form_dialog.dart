import 'package:flutter/material.dart';

import '../../core/models/flashcard.dart';
import 'domain/study_phase.dart';
import '../../shared/widgets/dunots_modal.dart';

class StudyPhaseFormDialog extends StatefulWidget {
  final StudyPhase? initialPhase;
  final List<Flashcard> flashcards;

  const StudyPhaseFormDialog({
    super.key,
    this.initialPhase,
    this.flashcards = const [],
  });

  @override
  State<StudyPhaseFormDialog> createState() => _StudyPhaseFormDialogState();
}

class _StudyPhaseFormDialogState extends State<StudyPhaseFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _searchController;
  late final Set<String> _flashcardIds;

  bool get _isEditing => widget.initialPhase != null;

  @override
  void initState() {
    super.initState();
    final phase = widget.initialPhase;
    _titleController = TextEditingController(text: phase?.title ?? '');
    _descriptionController = TextEditingController(
      text: phase?.description ?? '',
    );
    _searchController = TextEditingController()..addListener(_refresh);
    _flashcardIds = {...?phase?.flashcardIds};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final cards = widget.flashcards
        .where((card) {
          return query.isEmpty || card.front.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return DunotsModal(
      title: _isEditing ? 'Editar fase de estudo' : 'Nova fase de estudo',
      icon: Icons.layers_outlined,
      subtitle: 'Monte uma sessão de revisão com flashcards.',
      // ignore: sort_child_properties_last
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _titleController,
            autofocus: !_isEditing,
            decoration: const InputDecoration(labelText: 'Nome *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descrição',
              hintText: 'Qual é o objetivo desta fase?',
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Itens associados',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar flashcards',
            ),
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhum item encontrado.'),
            )
          else ...[
            ...cards.map(
              (card) => CheckboxListTile(
                value: _flashcardIds.contains(card.id),
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.style_outlined),
                title: Text(
                  card.front,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Flashcard'),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    _flashcardIds.add(card.id);
                  } else {
                    _flashcardIds.remove(card.id);
                  }
                }),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(_buildPhase()),
          child: Text(_isEditing ? 'Salvar alterações' : 'Criar fase'),
        ),
      ],
    );
  }

  StudyPhase _buildPhase() {
    final now = DateTime.now();
    final initial = widget.initialPhase;
    return StudyPhase(
      id: initial?.id ?? 'study-phase-${now.microsecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      flashcardIds: _flashcardIds.toList(growable: false),
      sortOrder: initial?.sortOrder ?? 0,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
  }

  void _refresh() => setState(() {});
}
