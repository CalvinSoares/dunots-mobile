import 'package:flutter/material.dart';

import '../../../app/dunots_theme.dart';
import '../domain/study_track.dart';

class StudyTrackListItem extends StatelessWidget {
  final StudyTrack track;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudyTrackListItem({
    super.key,
    required this.track,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  String get _statusLabel {
    if (track.totalItems > 0 && track.completedItems >= track.totalItems) {
      return 'Concluída';
    }
    if (track.completedItems > 0) {
      return 'Em andamento';
    }
    return 'A fazer';
  }

  Color get _statusColor {
    switch (_statusLabel) {
      case 'Concluída':
        return DunotsColors.success;
      case 'Em andamento':
        return DunotsColors.emerald;
      default:
        return DunotsColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label:
          'Abrir trilha ${track.title}. ${track.progressLabel}. '
          'Status: $_statusLabel.',
      hint: 'Toque para ver os tópicos da trilha.',
      child: Tooltip(
        message: 'Abrir trilha',
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
              child: Row(
                children: [
                  _ProgressRing(progress: track.progress, color: _statusColor),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.progressLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _statusLabel,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Ações da trilha',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: _TrackMenuItem(
                          icon: Icons.edit_outlined,
                          label: 'Editar trilha',
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: _TrackMenuItem(
                          icon: Icons.delete_outline,
                          label: 'Excluir trilha',
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color color;

  const _ProgressRing({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 4,
            // O trilho precisa continuar visível em 0%; caso contrário ele
            // se mistura ao card e só aparece o pequeno arco preenchido.
            backgroundColor: DunotsColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '$percent%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TrackMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _TrackMenuItem({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
