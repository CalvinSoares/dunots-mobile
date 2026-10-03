import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../app/dunots_theme.dart';

import '../../questions/data/question_repository.dart';
import '../../questions/domain/question.dart';
import '../../questions/question_details_page.dart';
import '../../flashcards/data/flashcard_repository.dart';
import '../../flashcards/flashcard_details_page.dart';
import '../../quizzes/data/quiz_attempt_repository.dart';
import '../../quizzes/domain/quiz_attempt.dart';
import '../../quizzes/quiz_attempt_page.dart';
import '../../quizzes/quiz_form_dialog.dart';
import '../data/study_material_repository.dart';
import '../data/study_node_repository.dart';
import '../data/study_track_repository.dart';
import '../domain/study_node.dart';
import '../domain/study_material.dart';
import '../data/study_document_repository.dart';
import '../data/study_material_progress_repository.dart';
import 'study_document_viewer_page.dart';
import 'study_node_details_page.dart';
import '../domain/study_track.dart';
import 'study_node_filters.dart';
import 'study_nodes_controller.dart';
import '../../../shared/widgets/dunots_modal.dart';

class StudyTrackDetailsPage extends StatefulWidget {
  final StudyTrack track;
  final StudyNodeRepository repository;
  final StudyTrackRepository? trackRepository;
  final StudyMaterialRepository? materialRepository;
  final StudyNodeMaterialRepository? materialLinkRepository;
  final QuestionRepository? questionRepository;
  final FlashcardRepository? flashcardRepository;
  final StudyDocumentRepository? documentRepository;
  final StudyMaterialProgressRepository? materialProgressRepository;
  final QuizAttemptRepository? attemptRepository;

  const StudyTrackDetailsPage({
    super.key,
    required this.track,
    required this.repository,
    this.trackRepository,
    this.materialRepository,
    this.materialLinkRepository,
    this.questionRepository,
    this.flashcardRepository,
    this.documentRepository,
    this.materialProgressRepository,
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
  late final StudyMaterialProgressRepository _materialProgressRepository;
  final Map<String, List<StudyMaterialLink>> _linksByNode = {};
  final Map<String, Set<String>> _completedMaterialKeysByNode = {};
  final Set<String> _collapsedNodeIds = <String>{};
  final ScrollController _nodeListController = ScrollController();
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
    _materialProgressRepository =
        widget.materialProgressRepository ??
        InMemoryStudyMaterialProgressRepository();
    _loadNodes();
  }

  @override
  void dispose() {
    _nodeListController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.track.title),
            actions: [
              IconButton(
                tooltip: 'Buscar e filtrar tópicos',
                onPressed: _showNodeSearchAndFilters,
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Novo tópico',
                onPressed: () => _showNodeDialog(context),
                icon: const Icon(Icons.add),
              ),
              PopupMenuButton<String>(
                tooltip: 'Ações da trilha',
                onSelected: (value) {
                  switch (value) {
                    case 'questions':
                      _showManualQuestionSelection();
                    case 'quiz':
                      _showTopicQuizBuilder();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'questions',
                    child: ListTile(
                      leading: Icon(Icons.checklist),
                      title: Text('Selecionar questões'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'quiz',
                    child: ListTile(
                      leading: Icon(Icons.quiz_outlined),
                      title: Text('Montar simulado'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 560;
                final header = [
                  if (widget.track.description.isNotEmpty)
                    Text(
                      widget.track.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: DunotsColors.muted),
                    ),
                  if (widget.track.description.isNotEmpty)
                    const SizedBox(height: 10),
                ];
                if (compact) {
                  return ListView(
                    key: const PageStorageKey('study-track-node-list'),
                    controller: _nodeListController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    children: [
                      ...header,
                      _buildContent(context, compact: true),
                    ],
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...header,
                      Expanded(child: _buildContent(context)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, {bool compact = false}) {
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
        if (compact) {
          return Column(
            children: [
              _buildProgress(state.nodes),
              const SizedBox(height: 20),
              const Text('Nenhum tópico cadastrado ainda.'),
            ],
          );
        }
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
        final nextNode = _findNextNode(visibleNodes);
        if (compact) {
          final rows = _flattenVisibleNodeRows(visibleNodes);
          return Column(
            children: [
              _buildProgress(state.nodes),
              if (nextNode != null) ...[
                const SizedBox(height: 12),
                _buildNextTopic(context, nextNode),
              ],
              const SizedBox(height: 14),
              if (visibleNodes.isEmpty)
                const Text('Nenhum tópico corresponde aos filtros.')
              else
                ...rows.map(
                  (row) => _buildNodeCard(
                    context,
                    row.node,
                    row.depth,
                    visibleNodes,
                    isNext: row.node.id == nextNode?.id,
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            _buildProgress(state.nodes),
            if (nextNode != null) ...[
              const SizedBox(height: 12),
              _buildNextTopic(context, nextNode),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: visibleNodes.isEmpty
                  ? const Center(
                      child: Text('Nenhum tópico corresponde aos filtros.'),
                    )
                  : Builder(
                      builder: (context) {
                        final rows = _flattenVisibleNodeRows(visibleNodes);
                        return ListView.builder(
                          key: const PageStorageKey('study-track-node-list'),
                          controller: _nodeListController,
                          scrollCacheExtent: ScrollCacheExtent.pixels(1200),
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            final row = rows[index];
                            return _buildNodeCard(
                              context,
                              row.node,
                              row.depth,
                              visibleNodes,
                              isNext: row.node.id == nextNode?.id,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
    }
  }

  Future<void> _showNodeSearchAndFilters() async {
    final searchController = TextEditingController(text: _searchQuery);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buscar e filtrar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey('study-node-search'),
                      controller: searchController,
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        setSheetState(() {});
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        labelText: 'Buscar tópicos',
                        hintText: 'Título, descrição ou anotação',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<StudyPriority?>(
                      initialValue: _priorityFilter,
                      decoration: const InputDecoration(
                        labelText: 'Prioridade',
                      ),
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
                      onChanged: (priority) {
                        setState(() => _priorityFilter = priority);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<StudyNodeCompletionFilter>(
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
                        if (filter == null) return;
                        setState(() => _completionFilter = filter);
                        setSheetState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _priorityFilter = null;
                            _completionFilter = StudyNodeCompletionFilter.all;
                          });
                          Navigator.of(sheetContext).pop();
                        },
                        child: const Text('Limpar filtros'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
  }

  Widget _buildProgress(List<StudyNode> nodes) {
    final completed = nodes
        .where(
          (node) =>
              node.isCompleted || node.status == StudyNodeStatus.completed,
        )
        .length;
    final progress = nodes.isEmpty ? 0.0 : completed / nodes.length;
    final percent = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percent%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: DunotsColors.ink,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$completed de ${nodes.length} ${nodes.length == 1 ? 'item' : 'itens'}',
                  style: const TextStyle(
                    color: DunotsColors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            color: DunotsColors.mint,
            backgroundColor: DunotsColors.border,
          ),
        ),
      ],
    );
  }

  Widget _buildNextTopic(BuildContext context, StudyNode node) {
    return Semantics(
      button: true,
      label: 'Próximo tópico: ${node.title}',
      onTapHint: 'Abrir próximo tópico',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openNodeDetails(context, node),
          child: Ink(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: DunotsColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DunotsColors.emerald, width: 1.2),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  color: DunotsColors.emerald,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Próximo tópico',
                        style: TextStyle(
                          color: DunotsColors.emerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '→ ${node.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: DunotsColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  StudyNode? _findNextNode(List<StudyNode> nodes) {
    final pending = nodes
        .where(
          (node) =>
              !node.isCompleted && node.status != StudyNodeStatus.completed,
        )
        .toList();
    if (pending.isEmpty) return null;

    final pendingIds = pending.map((node) => node.id).toSet();
    bool hasPendingDescendant(String nodeId) {
      final children = nodes.where((node) => node.parentId == nodeId);
      for (final child in children) {
        if (pendingIds.contains(child.id) || hasPendingDescendant(child.id)) {
          return true;
        }
      }
      return false;
    }

    final leaves = pending
        .where((node) => !hasPendingDescendant(node.id))
        .toList();
    final candidates = leaves.isEmpty ? pending : leaves;

    candidates.sort((a, b) {
      final priority = _priorityRank(b.priority)
          .compareTo(_priorityRank(a.priority));
      if (priority != 0) return priority;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return candidates.first;
  }

  int _priorityRank(StudyPriority priority) {
    switch (priority) {
      case StudyPriority.none:
        return 0;
      case StudyPriority.low:
        return 1;
      case StudyPriority.medium:
        return 2;
      case StudyPriority.high:
        return 3;
      case StudyPriority.urgent:
        return 4;
    }
  }

  String _nodeStatusLabel(StudyNode node, int completedMaterials) {
    switch (_effectiveNodeStatus(node, completedMaterials)) {
      case StudyNodeStatus.todo:
        return 'A fazer';
      case StudyNodeStatus.inProgress:
        return 'Em andamento';
      case StudyNodeStatus.review:
        return 'Revisar';
      case StudyNodeStatus.completed:
        return 'Concluído';
    }
  }

  StudyNodeStatus _effectiveNodeStatus(StudyNode node, int completedMaterials) {
    if (node.isCompleted || node.status == StudyNodeStatus.completed) {
      return StudyNodeStatus.completed;
    }
    if (node.status != StudyNodeStatus.todo) return node.status;
    if (completedMaterials > 0) return StudyNodeStatus.inProgress;
    return StudyNodeStatus.todo;
  }

  Color _nodeStatusColor(String status) {
    switch (status) {
      case 'Concluído':
        return DunotsColors.success;
      case 'Em andamento':
        return DunotsColors.emerald;
      case 'Revisar':
        return DunotsColors.amber;
      default:
        return DunotsColors.muted;
    }
  }

  List<StudyNode> _subtreeNodes(StudyNode root, List<StudyNode> nodes) {
    final subtree = <StudyNode>[root];
    var index = 0;
    while (index < subtree.length) {
      final parentId = subtree[index].id;
      subtree.addAll(nodes.where((node) => node.parentId == parentId));
      index++;
    }
    return subtree;
  }

  List<_VisibleNodeRow> _flattenVisibleNodeRows(List<StudyNode> nodes) {
    final childrenByParent = <String?, List<StudyNode>>{};
    for (final node in nodes) {
      childrenByParent.putIfAbsent(node.parentId, () => []).add(node);
    }
    for (final children in childrenByParent.values) {
      children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    final rows = <_VisibleNodeRow>[];
    void visit(String? parentId, int depth) {
      for (final node in childrenByParent[parentId] ?? const <StudyNode>[]) {
        rows.add(_VisibleNodeRow(node, depth));
        if (!_collapsedNodeIds.contains(node.id)) {
          visit(node.id, depth + 1);
        }
      }
    }

    visit(null, 0);
    return rows;
  }

  void _toggleNodeExpansion(String nodeId) {
    setState(() {
      if (!_collapsedNodeIds.add(nodeId)) {
        _collapsedNodeIds.remove(nodeId);
      }
    });
  }

  Widget _buildNodeCard(
    BuildContext context,
    StudyNode node,
    int depth,
    List<StudyNode> visibleNodes, {
    bool isNext = false,
  }) {
    final links = _linksByNode[node.id] ?? const <StudyMaterialLink>[];
    final completedMaterials =
        _completedMaterialKeysByNode[node.id]?.length ?? 0;
    final subtree = _subtreeNodes(node, _controller.state.nodes);
    final completedItems = subtree
        .where(
          (candidate) =>
              candidate.isCompleted ||
              candidate.status == StudyNodeStatus.completed,
        )
        .length;
    final statusLabel = _nodeStatusLabel(node, completedMaterials);
    final statusColor = _nodeStatusColor(statusLabel);
    final hasChildren = visibleNodes.any(
      (candidate) => candidate.parentId == node.id,
    );
    final isCollapsed = _collapsedNodeIds.contains(node.id);
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0, bottom: 10),
      child: Semantics(
        container: true,
        button: true,
        label:
            'Tópico ${node.title}. Status: $statusLabel${isNext ? '. Próximo tópico.' : '.'}',
        checked: node.isCompleted,
        onTapHint: 'Abrir detalhes do tópico',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openNodeDetails(context, node),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
              decoration: BoxDecoration(
                color: DunotsColors.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isNext
                      ? DunotsColors.emerald
                      : statusColor.withValues(alpha: 0.62),
                  width: isNext ? 1.5 : 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasChildren)
                    IconButton(
                      tooltip: isCollapsed
                          ? 'Expandir grupo'
                          : 'Recolher grupo',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      icon: Icon(
                        isCollapsed ? Icons.chevron_right : Icons.expand_more,
                      ),
                      onPressed: () => _toggleNodeExpansion(node.id),
                    ),
                  _StudyCheckbox(
                    value: node.isCompleted,
                    label: 'Concluir tópico ${node.title}',
                    onChanged: (_) => _toggleCompletion(node.id),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            node.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (node.description.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                node.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: DunotsColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _NodeStatusChip(
                                label: statusLabel,
                                color: statusColor,
                              ),
                              if (isNext)
                                const _NodeStatusChip(
                                  label: 'Próximo',
                                  color: DunotsColors.emerald,
                                ),
                              if (links.isNotEmpty)
                                Text(
                                  '$completedMaterials/${links.length}',
                                  style: const TextStyle(
                                    color: DunotsColors.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (subtree.length > 1 || links.isEmpty)
                                Text(
                                  '$completedItems/${subtree.length} itens',
                                  style: const TextStyle(
                                    color: DunotsColors.textTertiary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (node.priority != StudyPriority.none)
                    _PriorityDot(priority: node.priority),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openNodeDetails(BuildContext context, StudyNode node) async {
    final links = _linksByNode[node.id] ?? const <StudyMaterialLink>[];
    final catalog = await _materialRepository.getAll();
    final linkedMaterials = catalog
        .where(
          (material) => links.any(
            (link) =>
                link.materialId == material.id &&
                link.materialType == material.type,
          ),
        )
        .toList(growable: false);
    if (!context.mounted) return;
    void closeAndRun(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyNodeDetailsPage(
          node: node,
          linkedMaterials: linkedMaterials,
          completedMaterialCount:
              _completedMaterialKeysByNode[node.id]?.length ?? 0,
          onAddChild: () =>
              closeAndRun(() => _showNodeDialog(context, parentId: node.id)),
          onEdit: () => _editNodeFromDetails(context, node.id),
          onDelete: () => closeAndRun(() => _confirmDelete(context, node)),
          onLinkMaterial: () =>
              closeAndRun(() => _showMaterialDialog(context, node)),
          onOpenMaterials: () =>
              closeAndRun(() => _openLinkedMaterials(context, node)),
          onStartQuiz: () => closeAndRun(() => _startQuizFromNode(node)),
          canMoveUp: _canMove(node, _controller.state.nodes, direction: -1),
          canMoveDown: _canMove(node, _controller.state.nodes, direction: 1),
          onMoveUp: () => closeAndRun(() => _moveNode(node.id, direction: -1)),
          onMoveDown: () => closeAndRun(() => _moveNode(node.id, direction: 1)),
          onToggleCompletion: () =>
              closeAndRun(() => _toggleCompletion(node.id)),
          onStatusChanged: (status) async {
            Navigator.of(context).pop();
            await _controller.setStatus(node.id, status);
            await _syncTrackProgress();
          },
        ),
      ),
    );
  }

  // Mantido temporariamente para compatibilidade durante a migração da árvore.
  // ignore: unused_element
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
              color: DunotsColors.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DunotsColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  depth == 0
                      ? Icons.radio_button_unchecked
                      : Icons.subdirectory_arrow_right,
                  color: depth == 0
                      ? DunotsColors.emerald
                      : DunotsColors.purple,
                ),
                const SizedBox(width: 10),
                Checkbox(
                  value: node.isCompleted,
                  onChanged: (_) => _toggleCompletion(node.id),
                ),
                if (node.priority != StudyPriority.none)
                  _PriorityDot(priority: node.priority),
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
                            color: DunotsColors.muted,
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
                            color: DunotsColors.muted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      if ((_linksByNode[node.id]?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_completedMaterialKeysByNode[node.id]?.length ?? 0}/'
                          '${_linksByNode[node.id]?.length ?? 0} materiais estudados',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
                  onOpenMaterials: () => _openLinkedMaterials(context, node),
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
    final completedByNode = <String, Set<String>>{};

    for (final node in _controller.state.nodes) {
      final links = await _materialLinkRepository.getForNode(node.id);
      linksByNode[node.id] = links;
      final completed = await _materialProgressRepository.getForNode(node.id);
      completedByNode[node.id] = completed
          .map(
            (item) => _materialProgressKey(item.materialId, item.materialType),
          )
          .toSet();
    }

    if (mounted) {
      setState(() {
        _linksByNode
          ..clear()
          ..addAll(linksByNode);
        _completedMaterialKeysByNode
          ..clear()
          ..addAll(completedByNode);
      });
    }
  }

  String _materialProgressKey(String materialId, StudyMaterialType type) =>
      '$materialId:${type.name}';

  Future<void> _markMaterialStudied(
    StudyNode node,
    StudyMaterial material,
  ) async {
    final link = StudyMaterialLink(
      nodeId: node.id,
      materialId: material.id,
      materialType: material.type,
    );
    await _materialProgressRepository.markCompleted(link);
    final links = _linksByNode[node.id] ?? const <StudyMaterialLink>[];
    final allCompleted =
        links.isNotEmpty &&
        (await Future.wait(links.map(_materialProgressRepository.isCompleted)))
            .every((completed) => completed);
    if (allCompleted) {
      await _controller.setCompletion(node.id, true);
      await _syncTrackProgress();
    }
    await _loadLinks();
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

    final links = await showDunotsDrawer<List<StudyMaterialLink>>(
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

  Future<void> _openLinkedMaterials(
    BuildContext context,
    StudyNode node,
  ) async {
    final links = _linksByNode[node.id] ?? const <StudyMaterialLink>[];
    final catalog = await _materialRepository.getAll();
    final linked = catalog
        .where(
          (material) => links.any(
            (link) =>
                link.materialId == material.id &&
                link.materialType == material.type,
          ),
        )
        .toList(growable: false);
    if (!context.mounted) return;
    if (linked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum material vinculado encontrado.')),
      );
      return;
    }
    final selected = linked.length == 1
        ? linked.first
        : await showDunotsDrawer<StudyMaterial>(
            context: context,
            builder: (_) => _LinkedMaterialPickerDialog(materials: linked),
          );
    if (selected == null || !context.mounted) return;
    await _openMaterial(context, node, selected);
  }

  Future<void> _openMaterial(
    BuildContext context,
    StudyNode node,
    StudyMaterial material,
  ) async {
    var studied = false;
    switch (material.type) {
      case StudyMaterialType.flashcard:
        final repository = widget.flashcardRepository;
        if (repository == null) return;
        final card = (await repository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (card != null && context.mounted) {
          studied =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => FlashcardDetailsPage(
                    card: card,
                    flashcardRepository: repository,
                    questionRepository: _questionRepository,
                    materialRepository: _materialRepository,
                  ),
                ),
              ) ??
              false;
        }
      case StudyMaterialType.question:
        final question = (await _questionRepository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (question != null && context.mounted) {
          studied =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => QuestionDetailsPage(question: question),
                ),
              ) ??
              false;
        }
      case StudyMaterialType.document:
        final repository = widget.documentRepository;
        if (repository == null) return;
        final document = (await repository.getAll())
            .where((item) => item.id == material.id)
            .firstOrNull;
        if (document != null && context.mounted) {
          studied =
              await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => StudyDocumentViewerPage(document: document),
                ),
              ) ??
              false;
        }
    }
    if (studied && context.mounted) {
      await _markMaterialStudied(node, material);
    }
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

    final selectedIds = await showDunotsDrawer<List<String>>(
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

    final selectedNodeIds = await showDunotsDrawer<Set<String>>(
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

    final selectedQuestionIds = await showDunotsDrawer<List<String>>(
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
    final reviewedQuestionIds = await showDunotsDrawer<List<String>>(
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

    final data = await showDunotsDrawer<QuizFormData>(
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
        completedItems: nodes
            .where(
              (node) =>
                  node.isCompleted || node.status == StudyNodeStatus.completed,
            )
            .length,
        totalItems: nodes.length,
      ),
    );
  }

  Future<StudyNode?> _editNodeFromDetails(
    BuildContext context,
    String nodeId,
  ) async {
    final node = _nodeById(nodeId);
    if (node == null) return null;
    final saved = await _showNodeDialog(context, node: node);
    return saved ? _nodeById(nodeId) : null;
  }

  StudyNode? _nodeById(String nodeId) {
    for (final node in _controller.state.nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }

  Future<bool> _showNodeDialog(
    BuildContext context, {
    String? parentId,
    StudyNode? node,
  }) async {
    final data = await showDunotsDrawer<_NodeFormData>(
      context: context,
      builder: (_) => _NodeFormDialog(
        isChild: parentId != null || node?.parentId != null,
        node: node,
      ),
    );

    if (data == null || !mounted) {
      return false;
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
      return true;
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return false;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
      return false;
    }
  }

  Future<void> _confirmDelete(BuildContext context, StudyNode node) async {
    final descendantIds = _descendantIds(node.id);
    final descendantCount = descendantIds.length - 1;
    final choice = await showDunotsDrawer<_DeleteNodeChoice>(
      context: context,
      builder: (_) => _DeleteNodeDrawer(
        nodeTitle: node.title,
        descendantCount: descendantCount,
      ),
    );

    if (choice == null || !mounted) {
      return;
    }

    final deletedNodeIds = choice.deleteDescendants
        ? descendantIds
        : <String>{node.id};
    await _controller.deleteNode(
      node.id,
      preserveChildren: !choice.deleteDescendants,
    );
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

class _DeleteNodeChoice {
  final bool deleteDescendants;

  const _DeleteNodeChoice({required this.deleteDescendants});
}

class _DeleteNodeDrawer extends StatefulWidget {
  final String nodeTitle;
  final int descendantCount;

  const _DeleteNodeDrawer({
    required this.nodeTitle,
    required this.descendantCount,
  });

  @override
  State<_DeleteNodeDrawer> createState() => _DeleteNodeDrawerState();
}

class _DeleteNodeDrawerState extends State<_DeleteNodeDrawer> {
  bool _deleteDescendants = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescendants = widget.descendantCount > 0;
    final descendantLabel = widget.descendantCount == 1
        ? '1 subtópico'
        : '${widget.descendantCount} subtópicos';

    return DunotsModal(
      title: 'Excluir tópico?',
      subtitle: 'Esta ação remove “${widget.nodeTitle}”.',
      icon: Icons.delete_outline,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.of(context)
              .pop(_DeleteNodeChoice(deleteDescendants: _deleteDescendants)),
          child: const Text('Excluir'),
        ),
      ],
      child: DunotsFormColumn(
        spacing: 10,
        children: [
          Text(
            hasDescendants
                ? 'Escolha o que deve acontecer com os subtópicos.'
                : 'O tópico será removido permanentemente.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasDescendants)
            Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.45,
              ),
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: CheckboxListTile(
                value: _deleteDescendants,
                onChanged: (value) =>
                    setState(() => _deleteDescendants = value ?? false),
                title: Text('Excluir também $descendantLabel'),
                subtitle: const Text(
                  'Desmarcado: eles sobem para o mesmo nível deste tópico.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
        ],
      ),
    );
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
  final VoidCallback onOpenMaterials;
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
    required this.onOpenMaterials,
    required this.onStartQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Adicionar subtópico',
          onPressed: onAddChild,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(Icons.add, size: 20),
        ),
        PopupMenuButton<String>(
          tooltip: 'Mais ações do tópico',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'delete':
                onDelete();
              case 'link':
                onLinkMaterial();
              case 'materials':
                onOpenMaterials();
              case 'quiz':
                onStartQuiz();
              case 'moveUp':
                onMoveUp();
              case 'moveDown':
                onMoveDown();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: _NodeMenuItem(icon: Icons.edit_outlined, label: 'Editar'),
            ),
            const PopupMenuItem(
              value: 'link',
              child: _NodeMenuItem(
                icon: Icons.link,
                label: 'Vincular material',
              ),
            ),
            PopupMenuItem(
              value: 'materials',
              enabled: linkedMaterialsCount > 0,
              child: _NodeMenuItem(
                icon: Icons.open_in_new,
                label: 'Abrir materiais ($linkedMaterialsCount)',
              ),
            ),
            PopupMenuItem(
              value: 'quiz',
              enabled: linkedQuestionCount > 0,
              child: _NodeMenuItem(
                icon: Icons.quiz_outlined,
                label: 'Montar simulado ($linkedQuestionCount)',
              ),
            ),
            if (compact) ...[
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'moveUp',
                enabled: canMoveUp,
                child: const _NodeMenuItem(
                  icon: Icons.keyboard_arrow_up,
                  label: 'Mover para cima',
                ),
              ),
              PopupMenuItem(
                value: 'moveDown',
                enabled: canMoveDown,
                child: const _NodeMenuItem(
                  icon: Icons.keyboard_arrow_down,
                  label: 'Mover para baixo',
                ),
              ),
            ],
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: _NodeMenuItem(
                icon: Icons.delete_outline,
                label: 'Excluir tópico',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NodeMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NodeMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
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

class _LinkedMaterialPickerDialog extends StatelessWidget {
  final List<StudyMaterial> materials;

  const _LinkedMaterialPickerDialog({required this.materials});

  @override
  Widget build(BuildContext context) {
    final listHeight = (MediaQuery.sizeOf(context).height * 0.46)
        .clamp(200.0, 420.0)
        .toDouble();

    return DunotsModal(
      title: 'Abrir material vinculado',
      subtitle: 'Escolha o material que deseja abrir.',
      icon: Icons.link_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        height: listHeight,
        child: ListView.separated(
          itemCount: materials.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final material = materials[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_materialTypeIcon(material.type)),
              title: Text(
                material.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_materialTypeLabel(material.type)} · ${material.subtitle}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(context).pop(material),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
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

    return DunotsModal(
      title: 'Selecionar tópicos',
      subtitle: 'Escolha os tópicos que farão parte do simulado.',
      icon: Icons.topic_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: (MediaQuery.sizeOf(context).height * 0.52)
            .clamp(260.0, 520.0)
            .toDouble(),
        child: Column(
          children: [
            Text(
              '${selectedIds.length} selecionado(s) de ${widget.nodes.length}',
              style: const TextStyle(color: DunotsColors.muted),
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

    return DunotsModal(
      title: 'Revisar seleção',
      subtitle: 'Remova questões antes de criar o simulado.',
      icon: Icons.fact_check_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: (MediaQuery.sizeOf(context).height * 0.54)
            .clamp(280.0, 560.0)
            .toDouble(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedQuestions.length} questão(ões) no simulado',
              style: const TextStyle(color: DunotsColors.muted),
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

class _VisibleNodeRow {
  final StudyNode node;
  final int depth;

  const _VisibleNodeRow(this.node, this.depth);
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

    return DunotsModal(
      title: 'Selecionar questões',
      subtitle: 'Filtre e escolha as questões que entrarão no simulado.',
      icon: Icons.quiz_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: (MediaQuery.sizeOf(context).height * 0.54)
            .clamp(280.0, 560.0)
            .toDouble(),
        child: Column(
          children: [
            Text(
              '${selectedIds.length} selecionada(s) de ${widget.questions.length}',
              style: const TextStyle(color: DunotsColors.muted),
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

    return DunotsModal(
      title: 'Vincular materiais',
      subtitle: 'Associe flashcards, questões e documentos.',
      icon: Icons.link_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: (MediaQuery.sizeOf(context).height * 0.48)
            .clamp(240.0, 480.0)
            .toDouble(),
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

class _StudyCheckbox extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool?> onChanged;

  const _StudyCheckbox({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      checked: value,
      label: label,
      onTapHint: value ? 'Marcar como pendente' : 'Marcar como concluído',
      onTap: () => onChanged(!value),
      child: InkResponse(
        onTap: () => onChanged(!value),
        radius: 24,
        containedInkWell: true,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? DunotsColors.emerald : Colors.transparent,
                border: Border.all(
                  color: value ? DunotsColors.emerald : DunotsColors.muted,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      size: 15,
                      color: DunotsColors.background,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final StudyPriority priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _priorityLabel(priority),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          label: _priorityLabel(priority),
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _priorityColor(priority),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _priorityColor(priority).withValues(alpha: 0.42),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NodeStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _NodeStatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        border: Border.all(color: color.withValues(alpha: 0.34)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
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
      return DunotsColors.muted;
    case StudyPriority.low:
      return DunotsColors.mint;
    case StudyPriority.medium:
      return DunotsColors.amber;
    case StudyPriority.high:
      return DunotsColors.emerald;
    case StudyPriority.urgent:
      return DunotsColors.danger;
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
    return DunotsModal(
      title: widget.node == null
          ? (widget.isChild ? 'Novo subtópico' : 'Novo tópico')
          : 'Editar tópico',
      icon: widget.isChild ? Icons.account_tree_outlined : Icons.topic_outlined,
      // ignore: sort_child_properties_last
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
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Prioridade'),
            items: StudyPriority.values
                .map(
                  (priority) => DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: _priorityColor(priority),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _priorityLabel(priority),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
