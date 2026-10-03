import 'package:flutter/material.dart';

import '../../shared/widgets/dunots_modal.dart';
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
    return DunotsModal(
      title: 'Vincular fluxogramas',
      subtitle: 'Selecione os fluxogramas relacionados ao conteúdo.',
      icon: Icons.account_tree_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        spacing: 10,
        children: [
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar fluxogramas',
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_selected.length} selecionado(s)',
              style: const TextStyle(color: Color(0xFFB6B7AD)),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * 0.42,
            child: visible.isEmpty
                ? const Center(child: Text('Nenhum fluxograma encontrado.'))
                : ListView(
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
