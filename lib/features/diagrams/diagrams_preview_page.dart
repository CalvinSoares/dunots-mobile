import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import 'data/diagram_repository.dart';
import 'domain/study_diagram.dart';

class DiagramsPreviewPage extends StatefulWidget {
  final DiagramRepository? repository;

  const DiagramsPreviewPage({super.key, this.repository});

  @override
  State<DiagramsPreviewPage> createState() => _DiagramsPreviewPageState();
}

class _DiagramsPreviewPageState extends State<DiagramsPreviewPage> {
  late final DiagramRepository _repository;
  late Future<List<StudyDiagram>> _future;
  StudyDiagram? _selected;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryDiagramRepository();
    _reload();
  }

  void _reload() => _future = _repository.getAll();

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.account_tree_outlined,
      title: 'Fluxogramas',
      subtitle: 'Visualize relações entre conceitos e materiais.',
      child: FutureBuilder<List<StudyDiagram>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const StudyLoadingState(
              message: 'Carregando fluxogramas...',
            );
          }
          if (snapshot.hasError) {
            return StudyErrorState(
              message: 'Não foi possível carregar os fluxogramas.',
              onRetry: () => setState(_reload),
            );
          }
          final diagrams = snapshot.data ?? const <StudyDiagram>[];
          if (diagrams.isEmpty) {
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo fluxograma'),
                  ),
                ),
                const SizedBox(height: 16),
                const StudyEmptyState(
                  title: 'Nenhum fluxograma cadastrado.',
                  detail: 'Crie um mapa visual para organizar seus estudos.',
                  icon: Icons.account_tree_outlined,
                ),
              ],
            );
          }
          final selected = _selected ?? diagrams.first;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<StudyDiagram>(
                      initialValue: diagrams.contains(selected)
                          ? selected
                          : diagrams.first,
                      decoration: const InputDecoration(
                        labelText: 'Fluxograma',
                      ),
                      items: diagrams
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.title),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => _selected = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _create,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DiagramCanvas(diagram: selected),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${selected.nodes.length} blocos · ${selected.edges.length} ligações · '
                  '${selected.flashcardIds.length} flashcards · ${selected.problemIds.length} desafios',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    final data = await showDialog<_DiagramFormData>(
      context: context,
      builder: (_) => const _DiagramFormDialog(),
    );
    if (data == null) return;
    final now = DateTime.now();
    await _repository.create(
      StudyDiagram(
        id: 'diagram-${now.microsecondsSinceEpoch}',
        title: data.title,
        description: data.description,
        nodes: [
          {'id': 'start', 'label': data.title, 'x': 70.0, 'y': 70.0},
          {'id': 'next', 'label': 'Próximo passo', 'x': 300.0, 'y': 170.0},
        ],
        edges: const [
          {'source': 'start', 'target': 'next'},
        ],
        createdAt: now,
      ),
    );
    if (mounted) {
      setState(() {
        _selected = null;
        _reload();
      });
    }
  }
}

class _DiagramCanvas extends StatelessWidget {
  final StudyDiagram diagram;

  const _DiagramCanvas({required this.diagram});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(80),
        minScale: 0.5,
        maxScale: 2.5,
        child: CustomPaint(
          size: const Size(620, 320),
          painter: _DiagramPainter(
            diagram: diagram,
            color: Theme.of(context).colorScheme,
          ),
        ),
      ),
    );
  }
}

class _DiagramPainter extends CustomPainter {
  final StudyDiagram diagram;
  final ColorScheme color;

  const _DiagramPainter({required this.diagram, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <String, Offset>{};
    for (var index = 0; index < diagram.nodes.length; index++) {
      final node = diagram.nodes[index];
      final id = node['id']?.toString() ?? 'node-$index';
      positions[id] = Offset(
        (node['x'] as num?)?.toDouble() ?? 60 + (index % 3) * 190,
        (node['y'] as num?)?.toDouble() ?? 60 + (index ~/ 3) * 110,
      );
    }
    final edgePaint = Paint()
      ..color = color.primary.withValues(alpha: 0.65)
      ..strokeWidth = 2;
    for (final edge in diagram.edges) {
      final from = positions[edge['source']?.toString()];
      final to = positions[edge['target']?.toString()];
      if (from != null && to != null) {
        canvas.drawLine(from, to, edgePaint);
      }
    }
    final nodePaint = Paint()..color = color.primaryContainer;
    for (var index = 0; index < diagram.nodes.length; index++) {
      final node = diagram.nodes[index];
      final id = node['id']?.toString() ?? 'node-$index';
      final center = positions[id]!;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 150, height: 58),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, nodePaint);
      final text = TextPainter(
        text: TextSpan(
          text: node['label']?.toString() ?? id,
          style: TextStyle(color: color.onPrimaryContainer, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: 130);
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter oldDelegate) =>
      oldDelegate.diagram != diagram;
}

class _DiagramFormData {
  final String title;
  final String description;
  const _DiagramFormData({required this.title, required this.description});
}

class _DiagramFormDialog extends StatefulWidget {
  const _DiagramFormDialog();

  @override
  State<_DiagramFormDialog> createState() => _DiagramFormDialogState();
}

class _DiagramFormDialogState extends State<_DiagramFormDialog> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Novo fluxograma'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Título *'),
        ),
        TextField(
          controller: _description,
          decoration: const InputDecoration(labelText: 'Descrição'),
          maxLines: 3,
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isEmpty) return;
          Navigator.pop(
            context,
            _DiagramFormData(
              title: _title.text.trim(),
              description: _description.text.trim(),
            ),
          );
        },
        child: const Text('Criar'),
      ),
    ],
  );
}
