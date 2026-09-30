import 'package:flutter/material.dart';

import '../../questions/data/question_repository.dart';
import '../../questions/domain/question.dart';
import '../../quizzes/data/quiz_attempt_repository.dart';
import '../../quizzes/domain/quiz_attempt.dart';
import '../../quizzes/quiz_attempt_page.dart';
import '../../quizzes/quiz_form_dialog.dart';
import '../data/study_material_repository.dart';
import '../data/study_node_repository.dart';
import '../data/study_track_repository.dart';
import '../domain/study_node.dart';
import '../domain/study_material.dart';
import '../domain/study_track.dart';
import 'study_node_filters.dart';
import 'study_nodes_controller.dart';

class StudyTrackDetailsPage extends StatefulWidget {
  final StudyTrack track;
  final StudyNodeRepository repository;
  final StudyTrackRepository? trackRepository;
  final StudyMaterialRepository? materialRepository;
  final StudyNodeMaterialRepository? materialLinkRepository;
  final QuestionRepository? questionRepository;
  final QuizAttemptRepository? attemptRepository;

  const StudyTrackDetailsPage({
    super.key,
    required this.track,
    required this.repository,
    this.trackRepository,
    this.materialRepository,
    this.materialLinkRepository,
    this.questionRepository,
    this.attemptRepository,
  });

  @override
  State<StudyTrackDetailsPage> createState() => _StudyTrackDetailsPageState();
}

class _StudyTrackDetailsPageState extends State<StudyTrackDetailsPage> {
  late final StudyNodesController _controller;
  late final StudyMaterialRepository _materialRepository;
  late final StudyNodeMaterialRepository _materialLinkRepository;
  late final QuestionRepository _questionRepository;
  late final QuizAttemptRepository _attemptRepository;
  final Map<String, List<StudyMaterialLink>> _linksByNode = {};
  String _searchQuery = '';
  StudyPriority? _priorityFilter;
  StudyNodeCompletionFilter _completionFilter = StudyNodeCompletionFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = StudyNodesController(
      trackId: widget.track.id,
      repository: widget.repository,
    );
    _materialRepository =
        widget.materialRepository ?? InMemoryStudyMaterialRepository();
    _materialLinkRepository =
        widget.materialLinkRepository ?? InMemoryStudyNodeMaterialRepository();
    _questionRepository =
        widget.questionRepository ?? InMemoryQuestionRepository();
    _attemptRepository =
        widget.attemptRepository ?? InMemoryQuizAttemptRepository();
    _loadNodes();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.track.title)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.track.description,
                    style: const TextStyle(color: Color(0xFFB6B7AD)),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showNodeDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Novo tópico'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showManualQuestionSelection,
                        icon: const Icon(Icons.checklist),
                        label: const Text('Selecionar questões da trilha'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _showTopicQuizBuilder,
                        icon: const Icon(Icons.account_tree_outlined),
                        label: const Text('Montar simulado por tópicos'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildFilters(),
                  const SizedBox(height: 18),
                  Expanded(child: _buildContent(context)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final state = _controller.state;
    final visibleNodes = StudyNodeFilters.apply(
      nodes: state.nodes,
      query: _searchQuery,
      priority: _priorityFilter,
      completion: _completionFilter,
    );

    switch (state.status) {
      case StudyNodesStatus.initial:
      case StudyNodesStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StudyNodesStatus.empty:
        return Column(
          children: [
            _buildProgress(state.nodes),
            const Expanded(
              child: Center(child: Text('Nenhum tópico cadastrado ainda.')),
            ),
          ],
        );
      case StudyNodesStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(state.errorMessage ?? 'Ocorreu um erro.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _controller.load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      case StudyNodesStatus.data:
        return Column(
          children: [
            _buildProgress(state.nodes),
            const SizedBox(height: 14),
            Expanded(
              child: visibleNodes.isEmpty
                  ? const Center(
                      child: Text('Nenhum tópico corresponde aos filtros.'),
                    )
                  : ListView(children: _buildNodeTree(visibleNodes)),
            ),
          ],
        );
    }
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          key: const ValueKey('study-node-search'),
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Buscar tópico',
            hintText: 'Título, descrição ou anotação',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<StudyPriority?>(
                initialValue: _priorityFilter,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: [
                  const DropdownMenuItem<StudyPriority?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...StudyPriority.values
                      .where((priority) => priority != StudyPriority.none)
                      .map(
                        (priority) => DropdownMenuItem<StudyPriority?>(
                          value: priority,
                          child: Text(_priorityLabel(priority)),
                        ),
                      ),
                ],
                onChanged: (priority) =>
                    setState(() => _priorityFilter = priority),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<StudyNodeCompletionFilter>(
                initialValue: _completionFilter,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(
                    value: StudyNodeCompletionFilter.all,
                    child: Text('Todos'),
                  ),
                  DropdownMenuItem(
                    value: StudyNodeCompletionFilter.pending,
                    child: Text('Pendentes'),
                  ),
                  DropdownMenuItem(
                    value: StudyNodeCompletionFilter.completed,
                    child: Text('Concluídos'),
                  ),
                ],
                onChanged: (filter) {
                  if (filter != null) {
                    setState(() => _completionFilter = filter);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgress(List<StudyNode> nodes) {
    final completed = nodes.where((node) => node.isCompleted).length;
    final progress = nodes.isEmpty ? 0.0 : completed / nodes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progresso',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('$completed/${nodes.length} itens concluídos'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
      ],
    );
  }

  List<Widget> _buildNodeTree(
    List<StudyNode> nodes, {
    String? parentId,
    int depth = 0,
  }) {
    final children = nodes.where((node) => node.parentId == parentId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final widgets = <Widget>[];

    for (final node in children) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: depth * 20.0, bottom: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF292D2A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF4A504B)),
            ),
            child: Row(
              children: [
                Icon(
                  depth == 0
                      ? Icons.radio_button_unchecked
                      : Icons.subdirectory_arrow_right,
                  color: depth == 0
                      ? const Color(0xFF78B8FF)
                      : const Color(0xFFB79BFF),
                ),
                const SizedBox(width: 10),
                Checkbox(
                  value: node.isCompleted,
                  onChanged: (_) => _toggleCompletion(node.id),
                ),
                if (node.priority != StudyPriority.none)
                  _PriorityFlag(priority: node.priority),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (node.description.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          node.description,
                          style: const TextStyle(
                            color: Color(0xFFB6B7AD),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (node.notes.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          node.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB6B7AD),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _NodeActions(
                  canMoveUp: _canMove(node, nodes, direction: -1),
                  canMoveDown: _canMove(node, nodes, direction: 1),
                  onAddChild: () => _showNodeDialog(context, parentId: node.id),
                  onEdit: () => _showNodeDialog(context, node: node),
                  onDelete: () => _confirmDelete(context, node),
                  linkedMaterialsCount: _linksByNode[node.id]?.length ?? 0,
                  linkedQuestionCount:
                      _linksByNode[node.id]
                          ?.where(
                            (link) =>
                                link.materialType == StudyMaterialType.question,
                          )
                          .length ??
                      0,
                  onLinkMaterial: () => _showMaterialDialog(context, node),
                  onStartQuiz: () => _startQuizFromNode(node),
                  onMoveUp: () => _moveNode(node.id, direction: -1),
                  onMoveDown: () => _moveNode(node.id, direction: 1),
                ),
              ],
            ),
          ),
        ),
      );
      widgets.addAll(
        _buildNodeTree(nodes, parentId: node.id, depth: depth + 1),
      );
    }

    return widgets;
  }

  bool _canMove(
    StudyNode node,
    List<StudyNode> nodes, {
    required int direction,
  }) {
    final siblings =
        nodes.where((candidate) => candidate.parentId == node.parentId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final index = siblings.indexWhere((candidate) => candidate.id == node.id);
    final target = index + direction;
    return index >= 0 && target >= 0 && target < siblings.length;
  }

  Future<void> _loadNodes() async {
    await _controller.load();
    await _syncTrackProgress();
    await _loadLinks();
  }

  Future<void> _loadLinks() async {
    final linksByNode = <String, List<StudyMaterialLink>>{};

    for (final node in _controller.state.nodes) {
      linksByNode[node.id] = await _materialLinkRepository.getForNode(node.id);
    }

    if (mounted) {
      setState(() {
        _linksByNode
          ..clear()
          ..addAll(linksByNode);
      });
    }
  }

  Future<void> _toggleCompletion(String nodeId) async {
    await _controller.toggleCompletion(nodeId);
    await _syncTrackProgress();
  }

  Future<void> _moveNode(String nodeId, {required int direction}) async {
    await _controller.moveNode(nodeId, direction: direction);
    await _syncTrackProgress();
  }

  Future<void> _showMaterialDialog(BuildContext context, StudyNode node) async {
    final materials = await _materialRepository.getAll();
    final selectedLinks = await _materialLinkRepository.getForNode(node.id);
    if (!context.mounted) {
      return;
    }

    final links = await showDialog<List<StudyMaterialLink>>(
      context: context,
      builder: (_) => _MaterialLinkDialog(
        nodeId: node.id,
        materials: materials,
        initialLinks: selectedLinks,
      ),
    );

    if (links == null || !context.mounted) {
      return;
    }

    await _materialLinkRepository.replaceForNode(node.id, links);
    await _loadLinks();
  }

  Future<void> _startQuizFromNode(StudyNode node) async {
    await _openQuizBuilder(_questionIdsForNodes(_descendantIds(node.id)));
  }

  Future<void> _showManualQuestionSelection() async {
    final nodeIds = _controller.state.nodes.map((node) => node.id).toSet();
    final questionIds = _questionIdsForNodes(nodeIds);
    final questions = await _questionRepository.getAll();
    final linkedQuestions = questions
        .where((question) => questionIds.contains(question.id))
        .toList();

    if (!mounted) {
      return;
    }
    if (linkedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vincule questões a um tópico antes de iniciar.'),
        ),
      );
      return;
    }

    final selectedIds = await showDialog<List<String>>(
      context: context,
      builder: (_) => _QuestionSelectionDialog(
        questions: linkedQuestions,
        questionOrder: questionIds,
      ),
    );
    if (selectedIds == null || !mounted) {
      return;
    }
    await _openQuizBuilder(selectedIds);
  }

  Future<void> _showTopicQuizBuilder() async {
    final nodes = List<StudyNode>.of(_controller.state.nodes)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crie tópicos antes de montar o simulado.'),
        ),
      );
      return;
    }

    final selectedNodeIds = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _TopicSelectionDialog(nodes: nodes),
    );
    if (selectedNodeIds == null || !mounted) {
      return;
    }

    final questionIds = _questionIdsForNodes(selectedNodeIds);
    final questions = await _questionRepository.getAll();
    final linkedQuestions = questions
        .where((question) => questionIds.contains(question.id))
        .toList();
    if (!mounted) {
      return;
    }
    if (linkedQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Os tópicos escolhidos não possuem questões vinculadas.',
          ),
        ),
      );
      return;
    }

    final selectedQuestionIds = await showDialog<List<String>>(
      context: context,
      builder: (_) => _QuestionSelectionDialog(
        questions: linkedQuestions,
        questionOrder: questionIds,
      ),
    );
    if (selectedQuestionIds == null || !mounted) {
      return;
    }
    await _openQuizBuilder(selectedQuestionIds);
  }

  List<String> _questionIdsForNodes(Set<String> nodeIds) {
    final questionIds = <String>[];
    for (final candidate in _controller.state.nodes) {
      if (!nodeIds.contains(candidate.id)) {
        continue;
      }
      for (final link in _linksByNode[candidate.id] ?? const []) {
        if (link.materialType == StudyMaterialType.question &&
            !questionIds.contains(link.materialId)) {
          questionIds.add(link.materialId);
        }
      }
    }
    return questionIds;
  }

  Future<void> _openQuizBuilder(List<String> questionIds) async {
    final questions = await _questionRepository.getAll();
    final availableIds = questions.map((question) => question.id).toSet();
    final validQuestionIds = questionIds
        .where(availableIds.contains)
        .toList(growable: false);
    if (validQuestionIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vincule questões a este tópico antes de iniciar.'),
          ),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }
    final questionsById = {
      for (final question in questions) question.id: question,
    };
    final orderedQuestions = validQuestionIds
        .map((id) => questionsById[id])
        .whereType<Question>()
        .toList(growable: false);
    final reviewedQuestionIds = await showDialog<List<String>>(
      context: context,
      builder: (_) => _QuizSelectionSummaryDialog(
        questions: orderedQuestions,
        questionOrder: validQuestionIds,
        topicByQuestionId: _topicLabelsForQuestions(validQuestionIds),
      ),
    );
    if (reviewedQuestionIds == null || !mounted) {
      return;
    }

    final data = await showDialog<QuizFormData>(
      context: context,
      builder: (_) => const QuizFormDialog(),
    );
    if (data == null || !mounted) {
      return;
    }

    final now = DateTime.now();
    final attempt = QuizAttempt(
      id: 'quiz-${now.microsecondsSinceEpoch}',
      title: data.title,
      questionIds: List.unmodifiable(reviewedQuestionIds),
      currentIndex: 0,
      status: QuizAttemptStatus.inProgress,
      answers: const {},
      createdAt: now,
      updatedAt: now,
    );
    await _attemptRepository.create(attempt);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizAttemptPage(
          attempt: attempt,
          questionRepository: _questionRepository,
          attemptRepository: _attemptRepository,
        ),
      ),
    );
  }

  Map<String, String> _topicLabelsForQuestions(Iterable<String> questionIds) {
    final wantedIds = questionIds.toSet();
    final labelsByQuestion = <String, List<String>>{};
    for (final node in _controller.state.nodes) {
      for (final link in _linksByNode[node.id] ?? const []) {
        if (link.materialType == StudyMaterialType.question &&
            wantedIds.contains(link.materialId)) {
          labelsByQuestion
              .putIfAbsent(link.materialId, () => [])
              .add(node.title);
        }
      }
    }
    return {
      for (final entry in labelsByQuestion.entries)
        entry.key: entry.value.toSet().join(' · '),
    };
  }

  Future<void> _syncTrackProgress() async {
    final trackRepository = widget.trackRepository;
    if (trackRepository == null) {
      return;
    }

    final tracks = await trackRepository.getAll();
    final matchingTracks = tracks.where((track) => track.id == widget.track.id);
    if (matchingTracks.isEmpty) {
      return;
    }

    final nodes = _controller.state.nodes;
    await trackRepository.update(
      matchingTracks.first.copyWith(
        completedItems: nodes.where((node) => node.isCompleted).length,
        totalItems: nodes.length,
      ),
    );
  }

  Future<void> _showNodeDialog(
    BuildContext context, {
    String? parentId,
    StudyNode? node,
  }) async {
    final data = await showDialog<_NodeFormData>(
      context: context,
      builder: (_) => _NodeFormDialog(
        isChild: parentId != null || node?.parentId != null,
        node: node,
      ),
    );

    if (data == null || !mounted) {
      return;
    }

    try {
      if (node == null) {
        await _controller.createNode(
          title: data.title,
          description: data.description,
          parentId: parentId,
          notes: data.notes,
          priority: data.priority,
        );
      } else {
        await _controller.updateNode(
          id: node.id,
          title: data.title,
          description: data.description,
          notes: data.notes,
          priority: data.priority,
        );
      }
      await _syncTrackProgress();
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _confirmDelete(BuildContext context, StudyNode node) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir tópico?'),
        content: Text(
          '"${node.title}" e todos os seus subtópicos serão removidos.',
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

    if (confirmed != true || !mounted) {
      return;
    }

    final deletedNodeIds = _descendantIds(node.id);
    await _controller.deleteNode(node.id);
    for (final deletedNodeId in deletedNodeIds) {
      await _materialLinkRepository.deleteForNode(deletedNodeId);
    }
    await _loadLinks();
    await _syncTrackProgress();
  }

  Set<String> _descendantIds(String nodeId) {
    final ids = <String>{nodeId};
    var added = true;

    while (added) {
      added = false;
      for (final node in _controller.state.nodes) {
        if (node.parentId != null &&
            ids.contains(node.parentId) &&
            ids.add(node.id)) {
          added = true;
        }
      }
    }

    return ids;
  }
}

class _NodeActions extends StatelessWidget {
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onAddChild;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final int linkedMaterialsCount;
  final int linkedQuestionCount;
  final VoidCallback onLinkMaterial;
  final VoidCallback onStartQuiz;

  const _NodeActions({
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.linkedMaterialsCount,
    required this.linkedQuestionCount,
    required this.onLinkMaterial,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Adicionar subtópico',
              onPressed: onAddChild,
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Editar tópico',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Excluir tópico',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
            IconButton(
              tooltip: 'Vincular material',
              onPressed: onLinkMaterial,
              icon: Badge(
                isLabelVisible: linkedMaterialsCount > 0,
                label: Text('$linkedMaterialsCount'),
                child: const Icon(Icons.link),
              ),
            ),
            IconButton(
              tooltip: 'Montar simulado com questões vinculadas',
              onPressed: linkedQuestionCount == 0 ? null : onStartQuiz,
              icon: Badge(
                isLabelVisible: linkedQuestionCount > 0,
                label: Text('$linkedQuestionCount'),
                child: const Icon(Icons.quiz_outlined),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Mover para cima',
              onPressed: canMoveUp ? onMoveUp : null,
              icon: const Icon(Icons.keyboard_arrow_up),
            ),
            IconButton(
              tooltip: 'Mover para baixo',
              onPressed: canMoveDown ? onMoveDown : null,
              icon: const Icon(Icons.keyboard_arrow_down),
            ),
          ],
        ),
      ],
    );
  }
}

class _NodeFormData {
  final String title;
  final String description;
  final String notes;
  final StudyPriority priority;

  const _NodeFormData({
    required this.title,
    required this.description,
    required this.notes,
    required this.priority,
  });
}

class _MaterialLinkDialog extends StatefulWidget {
  final String nodeId;
  final List<StudyMaterial> materials;
  final List<StudyMaterialLink> initialLinks;

  const _MaterialLinkDialog({
    required this.nodeId,
    required this.materials,
    required this.initialLinks,
  });

  @override
  State<_MaterialLinkDialog> createState() => _MaterialLinkDialogState();
}

class _TopicSelectionDialog extends StatefulWidget {
  final List<StudyNode> nodes;

  const _TopicSelectionDialog({required this.nodes});

  @override
  State<_TopicSelectionDialog> createState() => _TopicSelectionDialogState();
}

class _TopicSelectionDialogState extends State<_TopicSelectionDialog> {
  final Set<String> selectedIds = {};
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final visibleRows = _topicRows(widget.nodes).where((row) {
      final searchable =
          '${row.node.title} ${row.node.description} ${row.node.notes}'
              .toLowerCase();
      return normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
    }).toList();

    return AlertDialog(
      title: const Text('Selecionar tópicos'),
      content: SizedBox(
        width: 560,
        height: 460,
        child: Column(
          children: [
            Text(
              '${selectedIds.length} selecionado(s) de ${widget.nodes.length}',
              style: const TextStyle(color: Color(0xFFB6B7AD)),
            ),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar tópicos',
                hintText: 'Título, descrição ou anotação',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visibleRows.isEmpty
                  ? const Center(child: Text('Nenhum tópico encontrado.'))
                  : ListView.builder(
                      itemCount: visibleRows.length,
                      itemBuilder: (context, index) {
                        final row = visibleRows[index];
                        return CheckboxListTile(
                          value: selectedIds.contains(row.node.id),
                          contentPadding: EdgeInsets.only(
                            left: row.depth * 22.0,
                            right: 0,
                          ),
                          onChanged: (checked) {
                            final relatedIds = _descendantIds(
                              row.node.id,
                              widget.nodes,
                            );
                            setState(() {
                              if (checked == true) {
                                selectedIds.addAll(relatedIds);
                              } else {
                                selectedIds.removeAll(relatedIds);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(row.node.title),
                          subtitle: row.node.description.isEmpty
                              ? null
                              : Text(
                                  row.node.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: selectedIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set.of(selectedIds)),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}

class _QuizSelectionSummaryDialog extends StatefulWidget {
  final List<Question> questions;
  final List<String> questionOrder;
  final Map<String, String> topicByQuestionId;

  const _QuizSelectionSummaryDialog({
    required this.questions,
    required this.questionOrder,
    required this.topicByQuestionId,
  });

  @override
  State<_QuizSelectionSummaryDialog> createState() =>
      _QuizSelectionSummaryDialogState();
}

class _QuizSelectionSummaryDialogState
    extends State<_QuizSelectionSummaryDialog> {
  late final List<String> selectedIds;

  @override
  void initState() {
    super.initState();
    selectedIds = List.of(widget.questionOrder);
  }

  @override
  Widget build(BuildContext context) {
    final questionsById = {
      for (final question in widget.questions) question.id: question,
    };
    final selectedQuestions = selectedIds
        .map((id) => questionsById[id])
        .whereType<Question>()
        .toList(growable: false);

    return AlertDialog(
      title: const Text('Revisar seleção'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedQuestions.length} questão(ões) no simulado',
              style: const TextStyle(color: Color(0xFFB6B7AD)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: selectedQuestions.isEmpty
                  ? const Center(
                      child: Text('Remova todas as questões da seleção.'),
                    )
                  : ListView.separated(
                      itemCount: selectedQuestions.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final question = selectedQuestions[index];
                        final topic = widget.topicByQuestionId[question.id];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            question.statement,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            [
                              if (topic != null && topic.isNotEmpty) topic,
                              if (question.topic.isNotEmpty) question.topic,
                              if (question.exam.isNotEmpty) question.exam,
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Remover questão',
                            onPressed: () =>
                                setState(() => selectedIds.remove(question.id)),
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: selectedIds.isEmpty
              ? null
              : () => Navigator.of(context).pop(List.of(selectedIds)),
          child: Text('Continuar (${selectedIds.length})'),
        ),
      ],
    );
  }
}

class _TopicRow {
  final StudyNode node;
  final int depth;

  const _TopicRow(this.node, this.depth);
}

List<_TopicRow> _topicRows(
  List<StudyNode> nodes, {
  String? parentId,
  int depth = 0,
}) {
  final children = nodes.where((node) => node.parentId == parentId).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  final rows = <_TopicRow>[];
  for (final node in children) {
    rows.add(_TopicRow(node, depth));
    rows.addAll(_topicRows(nodes, parentId: node.id, depth: depth + 1));
  }
  return rows;
}

Set<String> _descendantIds(String nodeId, List<StudyNode> nodes) {
  final ids = <String>{nodeId};
  var added = true;
  while (added) {
    added = false;
    for (final node in nodes) {
      if (node.parentId != null &&
          ids.contains(node.parentId) &&
          ids.add(node.id)) {
        added = true;
      }
    }
  }
  return ids;
}

class _QuestionSelectionDialog extends StatefulWidget {
  final List<Question> questions;
  final List<String> questionOrder;

  const _QuestionSelectionDialog({
    required this.questions,
    required this.questionOrder,
  });

  @override
  State<_QuestionSelectionDialog> createState() =>
      _QuestionSelectionDialogState();
}

class _QuestionSelectionDialogState extends State<_QuestionSelectionDialog> {
  final Set<String> selectedIds = {};
  String query = '';

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final visibleQuestions = widget.questions.where((question) {
      final searchable = [
        question.number?.toString() ?? '',
        question.statement,
        question.contest,
        question.role,
        question.topic,
        question.exam,
      ].join(' ').toLowerCase();
      return normalizedQuery.isEmpty || searchable.contains(normalizedQuery);
    }).toList();

    return AlertDialog(
      title: const Text('Selecionar questões'),
      content: SizedBox(
        width: 560,
        height: 500,
        child: Column(
          children: [
            Text(
              '${selectedIds.length} selecionada(s) de ${widget.questions.length}',
              style: const TextStyle(color: Color(0xFFB6B7AD)),
            ),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar questões',
                hintText: 'Número, enunciado, tópico ou prova',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visibleQuestions.isEmpty
                  ? const Center(child: Text('Nenhuma questão encontrada.'))
                  : ListView.builder(
                      itemCount: visibleQuestions.length,
                      itemBuilder: (context, index) {
                        final question = visibleQuestions[index];
                        final metadata = [
                          if (question.contest.isNotEmpty) question.contest,
                          if (question.exam.isNotEmpty) question.exam,
                          if (question.topic.isNotEmpty) question.topic,
                        ].join(' · ');
                        return CheckboxListTile(
                          value: selectedIds.contains(question.id),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedIds.add(question.id);
                              } else {
                                selectedIds.remove(question.id);
                              }
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            '#${question.number ?? index + 1} · ${question.statement}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: metadata.isEmpty ? null : Text(metadata),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: selectedIds.isEmpty
              ? null
              : () {
                  final orderedIds = widget.questionOrder
                      .where(selectedIds.contains)
                      .toList(growable: false);
                  Navigator.of(context).pop(orderedIds);
                },
          child: const Text('Criar simulado'),
        ),
      ],
    );
  }
}

class _MaterialLinkDialogState extends State<_MaterialLinkDialog> {
  late final Set<StudyMaterialLink> selectedLinks;
  String query = '';

  @override
  void initState() {
    super.initState();
    selectedLinks = widget.initialLinks.toSet();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim().toLowerCase();
    final visibleMaterials = widget.materials.where((material) {
      return normalizedQuery.isEmpty ||
          '${material.title} ${material.subtitle}'.toLowerCase().contains(
            normalizedQuery,
          );
    }).toList();

    return AlertDialog(
      title: const Text('Vincular materiais'),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar material',
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: visibleMaterials.isEmpty
                  ? const Center(child: Text('Nenhum material encontrado.'))
                  : ListView.builder(
                      itemCount: visibleMaterials.length,
                      itemBuilder: (context, index) {
                        final material = visibleMaterials[index];
                        final link = StudyMaterialLink(
                          nodeId: widget.nodeId,
                          materialId: material.id,
                          materialType: material.type,
                        );
                        return CheckboxListTile(
                          value: selectedLinks.contains(link),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedLinks.add(link);
                              } else {
                                selectedLinks.remove(link);
                              }
                            });
                          },
                          secondary: Icon(_materialTypeIcon(material.type)),
                          title: Text(material.title),
                          subtitle: Text(
                            '${_materialTypeLabel(material.type)} · ${material.subtitle}',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(selectedLinks.toList()),
          child: const Text('Salvar vínculos'),
        ),
      ],
    );
  }
}

String _materialTypeLabel(StudyMaterialType type) {
  switch (type) {
    case StudyMaterialType.flashcard:
      return 'Flashcard';
    case StudyMaterialType.question:
      return 'Questão';
    case StudyMaterialType.document:
      return 'Material';
  }
}

IconData _materialTypeIcon(StudyMaterialType type) {
  switch (type) {
    case StudyMaterialType.flashcard:
      return Icons.style_outlined;
    case StudyMaterialType.question:
      return Icons.quiz_outlined;
    case StudyMaterialType.document:
      return Icons.description_outlined;
  }
}

class _PriorityFlag extends StatelessWidget {
  final StudyPriority priority;

  const _PriorityFlag({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _priorityLabel(priority),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(Icons.flag, color: _priorityColor(priority)),
      ),
    );
  }
}

String _priorityLabel(StudyPriority priority) {
  switch (priority) {
    case StudyPriority.none:
      return 'Sem prioridade';
    case StudyPriority.low:
      return 'Prioridade baixa';
    case StudyPriority.medium:
      return 'Prioridade média';
    case StudyPriority.high:
      return 'Prioridade alta';
    case StudyPriority.urgent:
      return 'Prioridade urgente';
  }
}

Color _priorityColor(StudyPriority priority) {
  switch (priority) {
    case StudyPriority.none:
      return const Color(0xFFB6B7AD);
    case StudyPriority.low:
      return const Color(0xFF78B8FF);
    case StudyPriority.medium:
      return const Color(0xFFFFD166);
    case StudyPriority.high:
      return const Color(0xFFFF9F68);
    case StudyPriority.urgent:
      return const Color(0xFFFF7168);
  }
}

class _NodeFormDialog extends StatefulWidget {
  final bool isChild;
  final StudyNode? node;

  const _NodeFormDialog({required this.isChild, this.node});

  @override
  State<_NodeFormDialog> createState() => _NodeFormDialogState();
}

class _NodeFormDialogState extends State<_NodeFormDialog> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController notesController;
  late StudyPriority selectedPriority;
  String? validationError;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.node?.title);
    descriptionController = TextEditingController(
      text: widget.node?.description,
    );
    notesController = TextEditingController(text: widget.node?.notes);
    selectedPriority = widget.node?.priority ?? StudyPriority.none;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.node == null
            ? (widget.isChild ? 'Novo subtópico' : 'Novo tópico')
            : 'Editar tópico',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Título',
                hintText: 'Ex.: Arquiteturas de rede',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<StudyPriority>(
              initialValue: selectedPriority,
              decoration: const InputDecoration(labelText: 'Prioridade'),
              items: StudyPriority.values
                  .map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: _priorityColor(priority)),
                          const SizedBox(width: 8),
                          Text(_priorityLabel(priority)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (priority) {
                if (priority != null) {
                  setState(() => selectedPriority = priority);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Anotações (opcional)',
                hintText: 'Registre observações para este tópico',
              ),
            ),
            if (validationError != null) ...[
              const SizedBox(height: 12),
              Text(
                validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.node == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }

  void _submit() {
    if (titleController.text.trim().isEmpty) {
      setState(() {
        validationError = 'Informe um título.';
      });
      return;
    }

    Navigator.of(context).pop(
      _NodeFormData(
        title: titleController.text,
        description: descriptionController.text,
        notes: notesController.text,
        priority: selectedPriority,
      ),
    );
  }
}
