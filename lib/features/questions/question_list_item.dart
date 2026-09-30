import 'package:flutter/material.dart';

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
    return Card(
      child: ListTile(
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
        leading: CircleAvatar(child: Text(question.number?.toString() ?? '?')),
        title: Text(
          question.statement,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            question.role,
            question.contest,
            question.topic,
            question.exam,
            question.examId == null ? 'Sem prova vinculada' : '',
          ].where((item) => item.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: selectable
            ? Checkbox(value: selected, onChanged: onSelected)
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit?.call();
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Excluir')),
                ],
              ),
      ),
    );
  }
}
