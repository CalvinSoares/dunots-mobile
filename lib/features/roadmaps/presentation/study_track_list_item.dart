import 'package:flutter/material.dart';

import '../domain/study_track.dart';

class StudyTrackListItem extends StatelessWidget {
  final StudyTrack track;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const StudyTrackListItem({
    super.key,
    required this.track,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4A504B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, color: Color(0xFFB79BFF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (track.description.isNotEmpty) ...[
                  Text(
                    track.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFB6B7AD),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  track.progressLabel,
                  style: const TextStyle(
                    color: Color(0xFF78B8FF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Editar trilha',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir trilha',
            onPressed: onDelete,
            color: Theme.of(context).colorScheme.error,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}
