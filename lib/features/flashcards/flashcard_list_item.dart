import 'package:flutter/material.dart';

import 'package:dunots_mobile/core/models/flashcard.dart';

import '../questions/data/question_repository.dart';
import '../roadmaps/data/study_material_repository.dart';
import 'data/flashcard_repository.dart';
import 'flashcard_details_page.dart';

class FlashcardListItem extends StatelessWidget {
  final Flashcard card;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final FlashcardRepository? flashcardRepository;
  final QuestionRepository? questionRepository;
  final StudyMaterialRepository? materialRepository;

  const FlashcardListItem({
    super.key,
    required this.card,
    this.onEdit,
    this.onDelete,
    this.flashcardRepository,
    this.questionRepository,
    this.materialRepository,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FlashcardDetailsPage(
              card: card,
              flashcardRepository: flashcardRepository,
              questionRepository: questionRepository,
              materialRepository: materialRepository,
            ),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 8, 14),
          child: Row(
            children: [
              const Icon(Icons.style_outlined, color: Color(0xFF78B8FF)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.front,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.back,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFB6B7AD)),
                    ),
                    if (card.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: card.tags
                            .map((tag) => Chip(label: Text(tag)))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null || onDelete != null)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                )
              else
                const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
