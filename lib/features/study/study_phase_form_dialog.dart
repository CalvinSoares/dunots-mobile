import 'package:flutter/material.dart';

import '../../core/models/flashcard.dart';
import '../challenges/domain/challenge.dart';
import 'domain/study_phase.dart';

class StudyPhaseFormDialog extends StatefulWidget {
  final StudyPhase? initialPhase;
  final List<Flashcard> flashcards;
  final List<Challenge> challenges;

  const StudyPhaseFormDialog({
    super.key,
    this.initialPhase,
    this.flashcards = const [],
    this.challenges = const [],
  });

  @override
  State<StudyPhaseFormDialog> createState() => _StudyPhaseFormDialogState();
}

class _StudyPhaseFormDialogState extends State<StudyPhaseFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _searchController;
  late final Set<String> _flashcardIds;
  late final Set<String> _challengeIds;
  String _type = 'all';

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
    _challengeIds = {...?phase?.challengeIds};
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
          final matchesType = _type == 'all' || _type == 'flashcards';
          return matchesType &&
              (query.isEmpty || card.front.toLowerCase().contains(query));
        })
        .toList(growable: false);
    final challenges = widget.challenges
        .where((challenge) {
          final matchesType = _type == 'all' || _type == 'desafios';
          return matchesType &&
              (query.isEmpty || challenge.title.toLowerCase().contains(query));
        })
        .toList(growable: false);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar fase de estudo' : 'Nova fase de estudo'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
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
                  labelText: 'Buscar flashcards e desafios',
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'all', label: Text('Todos')),
                  ButtonSegment(value: 'flashcards', label: Text('Flashcards')),
                  ButtonSegment(value: 'desafios', label: Text('Desafios')),
                ],
                selected: {_type},
                onSelectionChanged: (value) =>
                    setState(() => _type = value.first),
              ),
              const SizedBox(height: 8),
              if (cards.isEmpty && challenges.isEmpty)
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
                ...challenges.map(
                  (challenge) => CheckboxListTile(
                    value: _challengeIds.contains(challenge.id),
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.code_outlined),
                    title: Text(
                      challenge.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text('Desafio'),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _challengeIds.add(challenge.id);
                      } else {
                        _challengeIds.remove(challenge.id);
                      }
                    }),
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
      challengeIds: _challengeIds.toList(growable: false),
      sortOrder: initial?.sortOrder ?? 0,
      createdAt: initial?.createdAt ?? now,
      updatedAt: now,
    );
  }

  void _refresh() => setState(() {});
}
