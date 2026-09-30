import 'package:flutter/material.dart';

import '../data/study_node_repository.dart';
import '../domain/study_node.dart';
import '../domain/study_track.dart';
import 'study_nodes_controller.dart';

class StudyTrackDetailsPage extends StatefulWidget {
  final StudyTrack track;
  final StudyNodeRepository repository;

  const StudyTrackDetailsPage({
    super.key,
    required this.track,
    required this.repository,
  });

  @override
  State<StudyTrackDetailsPage> createState() => _StudyTrackDetailsPageState();
}

class _StudyTrackDetailsPageState extends State<StudyTrackDetailsPage> {
  late final StudyNodesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudyNodesController(
      trackId: widget.track.id,
      repository: widget.repository,
    );
    _controller.load();
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
                  FilledButton.icon(
                    onPressed: () => _showNodeDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Novo tópico'),
                  ),
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

    switch (state.status) {
      case StudyNodesStatus.initial:
      case StudyNodesStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case StudyNodesStatus.empty:
        return const Center(child: Text('Nenhum tópico cadastrado ainda.'));
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
        return ListView(children: _buildNodeTree(state.nodes));
    }
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
                    ],
                  ),
                ),
                _NodeActions(
                  canMoveUp: _canMove(node, nodes, direction: -1),
                  canMoveDown: _canMove(node, nodes, direction: 1),
                  onAddChild: () => _showNodeDialog(context, parentId: node.id),
                  onEdit: () => _showNodeDialog(context, node: node),
                  onDelete: () => _confirmDelete(context, node),
                  onMoveUp: () => _controller.moveNode(node.id, direction: -1),
                  onMoveDown: () => _controller.moveNode(node.id, direction: 1),
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
        );
      } else {
        await _controller.updateNode(
          id: node.id,
          title: data.title,
          description: data.description,
        );
      }
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

    await _controller.deleteNode(node.id);
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

  const _NodeActions({
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onAddChild,
    required this.onEdit,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
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

  const _NodeFormData({required this.title, required this.description});
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
  String? validationError;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.node?.title);
    descriptionController = TextEditingController(
      text: widget.node?.description,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isChild ? 'Novo subtópico' : 'Novo tópico'),
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
      ),
    );
  }
}
