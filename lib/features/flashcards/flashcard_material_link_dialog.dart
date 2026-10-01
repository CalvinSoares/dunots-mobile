import 'package:flutter/material.dart';

import '../roadmaps/domain/study_material.dart';

class FlashcardMaterialLinkDialog extends StatefulWidget {
  final List<StudyMaterial> materials;
  final Set<String> initialSelectedIds;

  const FlashcardMaterialLinkDialog({
    super.key,
    required this.materials,
    this.initialSelectedIds = const {},
  });

  @override
  State<FlashcardMaterialLinkDialog> createState() =>
      _FlashcardMaterialLinkDialogState();
}

class _FlashcardMaterialLinkDialogState
    extends State<FlashcardMaterialLinkDialog> {
  late final Set<String> _selectedIds;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = {...widget.initialSelectedIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMaterials = widget.materials.where(_matchesSearch).toList();
    return AlertDialog(
      title: const Text('Vincular materiais'),
      content: SizedBox(
        width: 560,
        height: 500,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Buscar questão ou material',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_selectedIds.length} selecionado(s)',
                style: const TextStyle(color: Color(0xFFB6B7AD)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visibleMaterials.isEmpty
                  ? const Center(child: Text('Nenhum material encontrado.'))
                  : ListView.separated(
                      itemCount: visibleMaterials.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final material = visibleMaterials[index];
                        return CheckboxListTile(
                          value: _selectedIds.contains(material.id),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedIds.add(material.id);
                              } else {
                                _selectedIds.remove(material.id);
                              }
                            });
                          },
                          secondary: Icon(_materialIcon(material.type)),
                          title: Text(
                            material.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(material.subtitle),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          child: const Text('Vincular'),
        ),
      ],
    );
  }

  bool _matchesSearch(StudyMaterial material) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return true;
    return material.title.toLowerCase().contains(query) ||
        material.subtitle.toLowerCase().contains(query);
  }

  IconData _materialIcon(StudyMaterialType type) {
    return switch (type) {
      StudyMaterialType.flashcard => Icons.style_outlined,
      StudyMaterialType.question => Icons.quiz_outlined,
      StudyMaterialType.challenge => Icons.code_outlined,
      StudyMaterialType.document => Icons.description_outlined,
      StudyMaterialType.diagram => Icons.account_tree_outlined,
    };
  }
}
