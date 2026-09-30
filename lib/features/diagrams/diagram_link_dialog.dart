import 'package:flutter/material.dart';

import 'domain/study_diagram.dart';

class DiagramLinkDialog extends StatefulWidget {
  final List<StudyDiagram> diagrams;
  final Set<String> initialSelectedIds;

  const DiagramLinkDialog({
    super.key,
    required this.diagrams,
    this.initialSelectedIds = const {},
  });

  @override
  State<DiagramLinkDialog> createState() => _DiagramLinkDialogState();
}

class _DiagramLinkDialogState extends State<DiagramLinkDialog> {
  late final Set<String> _selected;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelectedIds};
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.diagrams
        .where((diagram) {
          final query = _search.trim().toLowerCase();
          return query.isEmpty || diagram.title.toLowerCase().contains(query);
        })
        .toList(growable: false);
    return AlertDialog(
      title: const Text('Vincular fluxogramas'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar fluxogramas...',
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: visible.isEmpty
                  ? const Center(child: Text('Nenhum fluxograma encontrado.'))
                  : ListView(
                      shrinkWrap: true,
                      children: visible
                          .map(
                            (diagram) => CheckboxListTile(
                              value: _selected.contains(diagram.id),
                              title: Text(diagram.title),
                              subtitle: Text('${diagram.nodes.length} blocos'),
                              onChanged: (checked) => setState(() {
                                if (checked == true) {
                                  _selected.add(diagram.id);
                                } else {
                                  _selected.remove(diagram.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          child: const Text('Vincular'),
        ),
      ],
    );
  }
}
