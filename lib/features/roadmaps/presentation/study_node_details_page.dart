import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/dunots_theme.dart';
import '../domain/study_material.dart';
import '../domain/study_node.dart';

class StudyNodeDetailsPage extends StatefulWidget {
  final StudyNode node;
  final List<StudyMaterial> linkedMaterials;
  final int completedMaterialCount;
  final VoidCallback? onAddChild;
  final Future<StudyNode?> Function()? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLinkMaterial;
  final VoidCallback? onOpenMaterials;
  final VoidCallback? onStartQuiz;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback? onToggleCompletion;
  final ValueChanged<StudyNodeStatus>? onStatusChanged;

  const StudyNodeDetailsPage({
    super.key,
    required this.node,
    this.linkedMaterials = const [],
    this.completedMaterialCount = 0,
    this.onAddChild,
    this.onEdit,
    this.onDelete,
    this.onLinkMaterial,
    this.onOpenMaterials,
    this.onStartQuiz,
    this.onMoveUp,
    this.onMoveDown,
    this.canMoveUp = false,
    this.canMoveDown = false,
    this.onToggleCompletion,
    this.onStatusChanged,
  });

  @override
  State<StudyNodeDetailsPage> createState() => _StudyNodeDetailsPageState();
}

class _StudyNodeDetailsPageState extends State<StudyNodeDetailsPage> {
  late StudyNode _node;

  StudyNode get node => _node;

  @override
  void initState() {
    super.initState();
    _node = widget.node;
  }

  @override
  Widget build(BuildContext context) {
    final status = _effectiveStatus(node);
    final progressLabel = widget.linkedMaterials.isEmpty
        ? 'Nenhum material vinculado'
        : '${widget.completedMaterialCount}/${widget.linkedMaterials.length} materiais estudados';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do tópico'),
        actions: _hasActions
            ? [
                PopupMenuButton<String>(
                  tooltip: 'Ações do tópico',
                  onSelected: (value) => _handleAction(context, value),
                  itemBuilder: (context) => [
                    if (widget.onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: _MenuAction(
                          icon: Icons.edit_outlined,
                          label: 'Editar',
                        ),
                      ),
                    if (widget.onAddChild != null)
                      const PopupMenuItem(
                        value: 'child',
                        child: _MenuAction(
                          icon: Icons.add,
                          label: 'Adicionar subtópico',
                        ),
                      ),
                    if (widget.onLinkMaterial != null)
                      const PopupMenuItem(
                        value: 'link',
                        child: _MenuAction(
                          icon: Icons.link,
                          label: 'Vincular material',
                        ),
                      ),
                    if (widget.onOpenMaterials != null &&
                        widget.linkedMaterials.isNotEmpty)
                      const PopupMenuItem(
                        value: 'materials',
                        child: _MenuAction(
                          icon: Icons.open_in_new,
                          label: 'Abrir materiais',
                        ),
                      ),
                    if (widget.onStartQuiz != null &&
                        widget.linkedMaterials.isNotEmpty)
                      const PopupMenuItem(
                        value: 'quiz',
                        child: _MenuAction(
                          icon: Icons.quiz_outlined,
                          label: 'Montar simulado',
                        ),
                      ),
                    if (widget.onStatusChanged != null) ...[
                      const PopupMenuDivider(),
                      for (final status in StudyNodeStatus.values)
                        PopupMenuItem(
                          value: 'status:${status.name}',
                          child: _MenuAction(
                            icon: _statusIcon(status),
                            label: 'Marcar como ${_statusLabel(status)}',
                          ),
                        ),
                    ],
                    if (widget.onMoveUp != null ||
                        widget.onMoveDown != null) ...[
                      const PopupMenuDivider(),
                      if (widget.onMoveUp != null)
                        PopupMenuItem(
                          value: 'move-up',
                          enabled: widget.canMoveUp,
                          child: const _MenuAction(
                            icon: Icons.keyboard_arrow_up,
                            label: 'Mover para cima',
                          ),
                        ),
                      if (widget.onMoveDown != null)
                        PopupMenuItem(
                          value: 'move-down',
                          enabled: widget.canMoveDown,
                          child: const _MenuAction(
                            icon: Icons.keyboard_arrow_down,
                            label: 'Mover para baixo',
                          ),
                        ),
                    ],
                    if (widget.onDelete != null) ...[
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: _MenuAction(
                          icon: Icons.delete_outline,
                          label: 'Excluir tópico',
                        ),
                      ),
                    ],
                  ],
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CopyableTopicTitle(
                    title: node.title,
                    onCopy: _copyTitle,
                  ),
                ),
                const SizedBox(width: 12),
                _CompletionBadge(
                  isCompleted: node.isCompleted,
                  onTap: widget.onToggleCompletion,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: _statusIcon(status),
                  label: _statusLabel(status),
                  color: _statusColor(status),
                ),
                if (node.priority != StudyPriority.none)
                  _StatusChip(
                    icon: _priorityIcon(node.priority),
                    label: _priorityLabel(node.priority),
                    color: _priorityColor(node.priority),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            _DetailsSection(
              title: 'Descrição',
              icon: Icons.subject_outlined,
              child: Text(
                node.description.isEmpty
                    ? 'Nenhuma descrição adicionada.'
                    : node.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            if (node.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              _DetailsSection(
                title: 'Anotações',
                icon: Icons.sticky_note_2_outlined,
                child: Text(
                  node.notes,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
            const SizedBox(height: 20),
            _DetailsSection(
              title: 'Materiais',
              icon: Icons.menu_book_outlined,
              trailing: Text(
                progressLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              child: widget.linkedMaterials.isEmpty
                  ? const Text(
                      'Vincule flashcards, questões ou documentos pela trilha.',
                    )
                  : Column(
                      children: [
                        for (final material in widget.linkedMaterials)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_materialIcon(material.type)),
                            title: Text(
                              material.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${_materialTypeLabel(material.type)} · ${material.subtitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyTitle() async {
    await Clipboard.setData(ClipboardData(text: node.title));
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Título copiado.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  bool get _hasActions =>
      widget.onAddChild != null ||
      widget.onEdit != null ||
      widget.onDelete != null ||
      widget.onLinkMaterial != null ||
      widget.onOpenMaterials != null ||
      widget.onStartQuiz != null ||
      widget.onMoveUp != null ||
      widget.onMoveDown != null ||
      widget.onStatusChanged != null;

  Future<void> _handleAction(BuildContext context, String value) async {
    switch (value) {
      case 'edit':
        final updated = await widget.onEdit?.call();
        if (updated != null && mounted) {
          setState(() => _node = updated);
        }
      case 'child':
        widget.onAddChild?.call();
      case 'link':
        widget.onLinkMaterial?.call();
      case 'materials':
        widget.onOpenMaterials?.call();
      case 'quiz':
        widget.onStartQuiz?.call();
      case 'move-up':
        widget.onMoveUp?.call();
      case 'move-down':
        widget.onMoveDown?.call();
      case 'delete':
        widget.onDelete?.call();
      default:
        if (value.startsWith('status:')) {
          final name = value.substring('status:'.length);
          final status = StudyNodeStatus.values.where(
            (candidate) => candidate.name == name,
          );
          if (status.isNotEmpty) widget.onStatusChanged?.call(status.first);
        }
    }
  }
}

class _CopyableTopicTitle extends StatelessWidget {
  final String title;
  final Future<void> Function() onCopy;

  const _CopyableTopicTitle({required this.title, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Copiar título',
      child: Semantics(
        button: true,
        label: 'Título do tópico: $title',
        hint: 'Toque duas vezes para copiar o título',
        child: InkWell(
          key: const ValueKey('copy-topic-title'),
          onTap: onCopy,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuAction({required this.icon, required this.label});

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

class _DetailsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DunotsColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DunotsColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: DefaultTextStyle.merge(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback? onTap;

  const _CompletionBadge({required this.isCompleted, this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = isCompleted
        ? 'Tópico concluído. Marcar como pendente'
        : 'Tópico pendente. Marcar como concluído';
    return Tooltip(
      message: isCompleted ? 'Marcar como pendente' : 'Marcar como concluído',
      child: Semantics(
        button: onTap != null,
        checked: isCompleted,
        label: label,
        onTapHint: isCompleted
            ? 'Marcar tópico como pendente'
            : 'Marcar tópico como concluído',
        onTap: onTap,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          containedInkWell: true,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : DunotsColors.emerald,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _materialIcon(StudyMaterialType type) {
  switch (type) {
    case StudyMaterialType.flashcard:
      return Icons.style_outlined;
    case StudyMaterialType.question:
      return Icons.help_outline;
    case StudyMaterialType.document:
      return Icons.description_outlined;
  }
}

String _materialTypeLabel(StudyMaterialType type) {
  switch (type) {
    case StudyMaterialType.flashcard:
      return 'Flashcard';
    case StudyMaterialType.question:
      return 'Questão';
    case StudyMaterialType.document:
      return 'Documento';
  }
}

String _statusLabel(StudyNodeStatus status) {
  switch (status) {
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

StudyNodeStatus _effectiveStatus(StudyNode node) {
  if (node.isCompleted || node.status == StudyNodeStatus.completed) {
    return StudyNodeStatus.completed;
  }
  return node.status;
}

IconData _statusIcon(StudyNodeStatus status) {
  switch (status) {
    case StudyNodeStatus.todo:
      return Icons.radio_button_unchecked;
    case StudyNodeStatus.inProgress:
      return Icons.play_circle_outline;
    case StudyNodeStatus.review:
      return Icons.refresh;
    case StudyNodeStatus.completed:
      return Icons.check_circle_outline;
  }
}

IconData _priorityIcon(StudyPriority priority) {
  switch (priority) {
    case StudyPriority.none:
      return Icons.flag_outlined;
    case StudyPriority.low:
      return Icons.flag_outlined;
    case StudyPriority.medium:
      return Icons.flag;
    case StudyPriority.high:
      return Icons.outlined_flag;
    case StudyPriority.urgent:
      return Icons.priority_high;
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
      return 'Urgente';
  }
}

Color _statusColor(StudyNodeStatus status) {
  switch (status) {
    case StudyNodeStatus.todo:
      return DunotsColors.muted;
    case StudyNodeStatus.inProgress:
      return DunotsColors.emerald;
    case StudyNodeStatus.review:
      return DunotsColors.amber;
    case StudyNodeStatus.completed:
      return DunotsColors.mint;
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

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      backgroundColor: color.withValues(alpha: 0.16),
      side: BorderSide(color: color.withValues(alpha: 0.42)),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
