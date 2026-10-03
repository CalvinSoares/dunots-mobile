import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';

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
    final tagSummary = card.tags.isEmpty
        ? ''
        : ' Tags: ${card.tags.take(3).join(', ')}${card.tags.length > 3 ? ', e mais.' : '.'}';
    return Semantics(
      container: true,
      label: 'Flashcard: ${card.front}. Resposta: ${card.back}.$tagSummary',
      hint: 'Toque para abrir os detalhes.',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 4, 11),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: DunotsColors.emerald.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.style_outlined,
                    color: DunotsColors.emerald,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        card.front,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        card.back,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DunotsColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (card.tags.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          card.tags.take(2).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DunotsColors.purple,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    tooltip: 'Ações do flashcard',
                    icon: const Icon(Icons.more_vert),
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
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.chevron_right_rounded),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
