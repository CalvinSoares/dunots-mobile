import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import '../../shared/widgets/study_widgets.dart';
import '../../shared/widgets/dunots_modal.dart';
import '../diagrams/data/diagram_repository.dart';
import '../diagrams/diagram_link_dialog.dart';
import '../diagrams/domain/study_diagram.dart';
import 'data/challenge_repository.dart';
import 'challenge_details_page.dart';
import 'challenge_study_session_page.dart';
import 'domain/challenge.dart';

class ChallengesPreviewPage extends StatefulWidget {
  final ChallengeRepository? repository;
  final DiagramRepository? diagramRepository;

  const ChallengesPreviewPage({
    super.key,
    this.repository,
    this.diagramRepository,
  });

  @override
  State<ChallengesPreviewPage> createState() => _ChallengesPreviewPageState();
}

class _ChallengesPreviewPageState extends State<ChallengesPreviewPage> {
  late final ChallengeRepository _repository;
  late Future<List<Challenge>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryChallengeRepository();
    _reload();
  }

  void _reload() {
    _future = _repository.getAll();
  }

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.code_outlined,
      title: 'Desafios',
      subtitle: 'Pratique problemas e acompanhe sua evolução.',
      child: FutureBuilder<List<Challenge>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudyLoadingState(message: 'Carregando desafios...');
          }
          if (snapshot.hasError) {
            return StudyErrorState(
              message: 'Não foi possível carregar os desafios.',
              onRetry: () => setState(_reload),
            );
          }
          final challenges = (snapshot.data ?? const <Challenge>[])
              .where(
                (item) =>
                    item.title.toLowerCase().contains(_search.toLowerCase()),
              )
              .toList(growable: false);
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 520;
              return Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar desafios',
                    ),
                    onChanged: (value) => setState(() => _search = value),
                  ),
                  const SizedBox(height: 12),
                  if (compact) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _create,
                        icon: const Icon(Icons.add),
                        label: const Text('Novo desafio'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: challenges.isEmpty
                            ? null
                            : () => _startSession(challenges),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Praticar resultados'),
                      ),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: challenges.isEmpty
                                ? null
                                : () => _startSession(challenges),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Praticar resultados'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _create,
                          icon: const Icon(Icons.add),
                          label: const Text('Novo desafio'),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  if (challenges.isEmpty)
                    const StudyEmptyState(
                      title: 'Nenhum desafio encontrado.',
                      detail: 'Cadastre um problema para começar a praticar.',
                      icon: Icons.code_outlined,
                    )
                  else
                    ...challenges.map(_buildCard),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startSession(List<Challenge> challenges) async {
    final now = DateTime.now();
    final due = challenges
        .where((challenge) => challenge.isDueAt(now))
        .toList();
    final session = due.isEmpty ? challenges : due;
    final reviewed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChallengeStudySessionPage(
          challenges: session,
          repository: _repository,
        ),
      ),
    );
    if (reviewed == true && mounted) setState(_reload);
  }

  Widget _buildCard(Challenge challenge) {
    final color = switch (challenge.difficulty) {
      ChallengeDifficulty.easy => DunotsColors.mint,
      ChallengeDifficulty.medium => DunotsColors.amber,
      ChallengeDifficulty.hard => Colors.red,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => _openDetails(challenge),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          child: Icon(Icons.code, color: color),
        ),
        title: Text(challenge.title),
        subtitle: Text(
          '${challenge.difficulty.name} · ${challenge.tags.join(', ')}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') await _edit(challenge);
            if (value == 'delete') await _delete(challenge);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Excluir')),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetails(Challenge challenge) async {
    final reviewed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ChallengeDetailsPage(challenge: challenge, repository: _repository),
      ),
    );
    if (reviewed == true && mounted) setState(_reload);
  }

  Future<void> _create() async {
    final diagrams =
        await widget.diagramRepository?.getAll() ?? const <StudyDiagram>[];
    if (!mounted) return;
    final data = await showDunotsDrawer<_ChallengeFormData>(
      context: context,
      builder: (_) => _ChallengeFormDialog(
        title: 'Novo desafio',
        availableDiagrams: diagrams,
      ),
    );
    if (data == null) return;
    final now = DateTime.now();
    await _repository.create(
      Challenge(
        id: 'challenge-${now.microsecondsSinceEpoch}',
        title: data.title,
        problemId: data.problemId,
        difficulty: data.difficulty,
        tags: data.tags,
        strategy: data.strategy,
        solution: data.solution,
        notes: data.notes,
        diagramIds: data.diagramIds,
        createdAt: now,
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _edit(Challenge challenge) async {
    final diagrams =
        await widget.diagramRepository?.getAll() ?? const <StudyDiagram>[];
    if (!mounted) return;
    final data = await showDunotsDrawer<_ChallengeFormData>(
      context: context,
      builder: (_) => _ChallengeFormDialog(
        title: 'Editar desafio',
        initial: challenge,
        availableDiagrams: diagrams,
      ),
    );
    if (data == null) return;
    await _repository.update(
      challenge.copyWith(
        title: data.title,
        problemId: data.problemId,
        difficulty: data.difficulty,
        tags: data.tags,
        strategy: data.strategy,
        solution: data.solution,
        notes: data.notes,
        diagramIds: data.diagramIds,
        updatedAt: DateTime.now(),
      ),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _delete(Challenge challenge) async {
    final confirmed = await showDunotsDrawer<bool>(
      context: context,
      builder: (_) => DunotsConfirmDialog(
        title: 'Excluir desafio?',
        message: 'O desafio “${challenge.title}” será removido.',
        confirmLabel: 'Excluir',
        icon: Icons.delete_outline,
      ),
    );
    if (confirmed != true) return;
    await _repository.delete(challenge.id);
    if (mounted) setState(_reload);
  }
}

class _ChallengeFormData {
  final String title;
  final String problemId;
  final ChallengeDifficulty difficulty;
  final List<String> tags;
  final String strategy;
  final String solution;
  final String notes;
  final List<String> diagramIds;

  const _ChallengeFormData({
    required this.title,
    required this.problemId,
    required this.difficulty,
    required this.tags,
    required this.strategy,
    required this.solution,
    required this.notes,
    required this.diagramIds,
  });
}

class _ChallengeFormDialog extends StatefulWidget {
  final String title;
  final Challenge? initial;
  final List<StudyDiagram> availableDiagrams;

  const _ChallengeFormDialog({
    required this.title,
    this.initial,
    this.availableDiagrams = const [],
  });

  @override
  State<_ChallengeFormDialog> createState() => _ChallengeFormDialogState();
}

class _ChallengeFormDialogState extends State<_ChallengeFormDialog> {
  late final TextEditingController _title;
  late final TextEditingController _problemId;
  late final TextEditingController _tags;
  late final TextEditingController _strategy;
  late final TextEditingController _solution;
  late final TextEditingController _notes;
  late Set<String> _linkedDiagramIds;
  late ChallengeDifficulty _difficulty;

  @override
  void initState() {
    super.initState();
    final item = widget.initial;
    _title = TextEditingController(text: item?.title);
    _problemId = TextEditingController(text: item?.problemId);
    _tags = TextEditingController(text: item?.tags.join(', '));
    _strategy = TextEditingController(text: item?.strategy);
    _solution = TextEditingController(text: item?.solution);
    _notes = TextEditingController(text: item?.notes);
    _linkedDiagramIds = {...?item?.diagramIds};
    _difficulty = item?.difficulty ?? ChallengeDifficulty.medium;
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _problemId,
      _tags,
      _strategy,
      _solution,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: widget.title,
      icon: Icons.code_outlined,
      subtitle: 'Registre o problema, a solução e os pontos de revisão.',
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        children: [
          TextField(
            controller: _title,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Título *',
              hintText: 'Ex.: Two Sum',
            ),
            onChanged: (_) => setState(() {}),
          ),
          TextField(
            controller: _problemId,
            decoration: const InputDecoration(
              labelText: 'ID do problema',
              hintText: 'Ex.: leetcode-001',
            ),
          ),
          DropdownButtonFormField<ChallengeDifficulty>(
            initialValue: _difficulty,
            decoration: const InputDecoration(labelText: 'Dificuldade'),
            items: ChallengeDifficulty.values
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) =>
                setState(() => _difficulty = value ?? _difficulty),
          ),
          OutlinedButton.icon(
            onPressed: widget.availableDiagrams.isEmpty
                ? null
                : _chooseDiagrams,
            icon: const Icon(Icons.account_tree_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _linkedDiagramIds.isEmpty
                    ? 'Vincular fluxogramas'
                    : 'Fluxogramas vinculados: ${_linkedDiagramIds.length}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'redes, grafos, algoritmos',
              helperText: 'Separe as tags por vírgula.',
            ),
          ),
          TextField(
            controller: _strategy,
            decoration: const InputDecoration(
              labelText: 'Estratégia',
              hintText: 'Como você pretende resolver?',
            ),
            maxLines: 3,
          ),
          TextField(
            controller: _solution,
            decoration: const InputDecoration(
              labelText: 'Solução',
              alignLabelWithHint: true,
            ),
            minLines: 5,
            maxLines: 10,
          ),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Anotações',
              alignLabelWithHint: true,
            ),
            minLines: 3,
            maxLines: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _title.text.trim().isEmpty
              ? null
              : () => Navigator.pop(
                  context,
                  _ChallengeFormData(
                    title: _title.text.trim(),
                    problemId: _problemId.text.trim(),
                    difficulty: _difficulty,
                    tags: _tags.text
                        .split(',')
                        .map((item) => item.trim())
                        .where((item) => item.isNotEmpty)
                        .toList(),
                    strategy: _strategy.text.trim(),
                    solution: _solution.text.trim(),
                    notes: _notes.text.trim(),
                    diagramIds: _linkedDiagramIds.toList(growable: false),
                  ),
                ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _chooseDiagrams() async {
    final selected = await showDunotsDrawer<List<String>>(
      context: context,
      builder: (_) => DiagramLinkDialog(
        diagrams: widget.availableDiagrams,
        initialSelectedIds: _linkedDiagramIds,
      ),
    );
    if (selected != null && mounted) {
      setState(() => _linkedDiagramIds = selected.toSet());
    }
  }
}
