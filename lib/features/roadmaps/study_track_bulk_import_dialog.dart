import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import '../../shared/widgets/dunots_modal.dart';
import 'domain/study_node.dart';
import 'study_track_bulk_parser.dart';

class StudyTrackBulkFormData {
  final String title;
  final String description;
  final String text;
  final StudyPriority priority;
  final List<StudyTrackImportItem> items;

  const StudyTrackBulkFormData({
    required this.title,
    required this.description,
    required this.text,
    required this.priority,
    required this.items,
  });
}

class _FormatDisclaimer extends StatelessWidget {
  const _FormatDisclaimer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Formato aceito', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text(
            'Uma linha por item usando Nome | Descrição. Use dois espaços no início para criar um filho. Linhas sem indentação ficam no mesmo nível.',
            style: TextStyle(fontSize: 12),
          ),
          SizedBox(height: 8),
          Text(
            '- Roteamento | Fundamentos\n  - Estático | Rotas manuais\n  - Dinâmico | Rotas aprendidas',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final List<StudyTrackImportItem> items;

  const _PreviewCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            items.isEmpty
                ? 'Prévia reconhecida: nenhum item'
                : 'Prévia reconhecida: ${items.length} item(ns)',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'Cole pelo menos um tópico no formato indicado acima.',
              style: TextStyle(fontSize: 12),
            )
          else
            Column(
              children: [
                for (final item in items.take(12)) ...[
                  Padding(
                    padding: EdgeInsets.only(left: item.depth * 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          item.depth == 0
                              ? Icons.topic_outlined
                              : Icons.subdirectory_arrow_right,
                          size: 17,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.description == null
                                ? item.title
                                : '${item.title} · ${item.description}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item != items.take(12).last) const Divider(height: 12),
                ],
                if (items.length > 12) ...[
                  const SizedBox(height: 8),
                  Text(
                    '+ ${items.length - 12} item(ns) serão criados',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class StudyTrackBulkImportForm extends StatefulWidget {
  final ValueChanged<StudyTrackBulkFormData>? onSubmitted;
  final VoidCallback? onChanged;

  const StudyTrackBulkImportForm({super.key, this.onSubmitted, this.onChanged});

  @override
  StudyTrackBulkImportFormState createState() =>
      StudyTrackBulkImportFormState();
}

class StudyTrackBulkImportFormState extends State<StudyTrackBulkImportForm> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController textController;
  StudyPriority priority = StudyPriority.none;

  List<StudyTrackImportItem> get items =>
      parseStudyTrackImportText(textController.text);

  bool get canSubmit =>
      titleController.text.trim().isNotEmpty && items.isNotEmpty;

  StudyTrackBulkFormData? get formData {
    if (!canSubmit) return null;
    return StudyTrackBulkFormData(
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      text: textController.text,
      priority: priority,
      items: items,
    );
  }

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsFormColumn(
      children: [
        TextField(
          controller: titleController,
          autofocus: true,
          maxLength: 160,
          onChanged: (_) => _notifyChanged(),
          decoration: const InputDecoration(
            labelText: 'Nome da trilha *',
            hintText: 'Ex.: Redes de Computadores',
          ),
        ),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          maxLength: 600,
          onChanged: (_) => _notifyChanged(),
          decoration: const InputDecoration(
            labelText: 'Descrição (opcional)',
            hintText: 'Objetivo ou contexto da trilha',
          ),
        ),
        TextField(
          controller: textController,
          minLines: 8,
          maxLines: 14,
          onChanged: (_) => _notifyChanged(),
          decoration: const InputDecoration(
            labelText: 'Tópicos e subtópicos *',
            hintText: '- Redes de computadores | Fundamentos\n  - Modelo OSI | Sete camadas\n  - TCP/IP | Pilha de protocolos',
            alignLabelWithHint: true,
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
        DropdownButtonFormField<StudyPriority>(
          initialValue: priority,
          decoration: const InputDecoration(
            labelText: 'Prioridade aplicada aos itens',
          ),
          items: StudyPriority.values
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: _priorityColor(value)),
                      const SizedBox(width: 8),
                      Text(_priorityLabel(value)),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) {
              setState(() => priority = value);
              _notifyChanged();
            }
          },
        ),
        const _FormatDisclaimer(),
        _PreviewCard(items: items),
      ],
    );
  }

  void submit() {
    final data = formData;
    if (data != null) widget.onSubmitted?.call(data);
  }

  void _notifyChanged() {
    setState(() {});
    widget.onChanged?.call();
  }

  Color _priorityColor(StudyPriority value) {
    switch (value) {
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

  String _priorityLabel(StudyPriority value) {
    switch (value) {
      case StudyPriority.none:
        return 'Sem prioridade';
      case StudyPriority.low:
        return 'Baixa';
      case StudyPriority.medium:
        return 'Média';
      case StudyPriority.high:
        return 'Alta';
      case StudyPriority.urgent:
        return 'Urgente';
    }
  }
}
