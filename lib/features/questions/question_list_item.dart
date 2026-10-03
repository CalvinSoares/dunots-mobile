import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import 'domain/question.dart';
import 'question_details_page.dart';

class QuestionListItem extends StatelessWidget {
  final Question question;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool?>? onSelected;

  const QuestionListItem({
    super.key,
    required this.question,
    this.onEdit,
    this.onDelete,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final number = question.number?.toString() ?? 'sem número';
    final contextSummary = [
      question.role,
      question.contest,
      question.topic,
      question.exam,
      if (question.examId == null) 'Sem prova vinculada',
    ].where((item) => item.isNotEmpty).join(' · ');
    return Semantics(
      container: true,
      label: 'Questão $number: ${question.statement}',
      value: contextSummary.isEmpty ? null : contextSummary,
      hint: selectable
          ? selected
                ? 'Selecionada. Toque para desmarcar.'
                : 'Toque para selecionar.'
          : 'Toque para abrir os detalhes.',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (selectable) {
              onSelected?.call(!selected);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => QuestionDetailsPage(question: question),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 4, 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DunotsColors.emerald.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    question.number?.toString() ?? '?',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: DunotsColors.emerald,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        question.statement,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      if (contextSummary.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          contextSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DunotsColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                selectable
                    ? Checkbox(value: selected, onChanged: onSelected)
                    : PopupMenuButton<String>(
                        tooltip: 'Ações da questão',
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit?.call();
                          } else if (value == 'delete') {
                            onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
