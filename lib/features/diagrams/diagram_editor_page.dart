import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:math' as math;

import '../../shared/widgets/dunots_modal.dart';
import 'data/diagram_repository.dart';
import 'domain/study_diagram.dart';

class DiagramEditorPage extends StatefulWidget {
  final StudyDiagram diagram;
  final DiagramRepository repository;

  const DiagramEditorPage({
    super.key,
    required this.diagram,
    required this.repository,
  });

  @override
  State<DiagramEditorPage> createState() => _DiagramEditorPageState();
}

class _DiagramEditorPageState extends State<DiagramEditorPage> {
  late List<Map<String, dynamic>> _nodes;
  late List<Map<String, dynamic>> _edges;
  final Set<String> _selectedIds = {};
  final Set<int> _selectedEdgeIndexes = {};
  final List<Map<String, dynamic>> _clipboard = [];
  final List<Map<String, dynamic>> _clipboardEdges = [];
  Map<String, Offset> _dragStartPositions = {};
  Offset _dragOffset = Offset.zero;
  Offset? _selectionStart;
  Rect? _selectionRect;
  bool _saving = false;
  late final TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    _nodes = _cloneMaps(widget.diagram.nodes);
    _edges = _cloneMaps(widget.diagram.edges);
    _transformController = TransformationController();
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            _copySelected,
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            _copySelected,
        const SingleActivator(LogicalKeyboardKey.keyX, control: true):
            _cutSelected,
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true):
            _cutSelected,
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): _paste,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): _paste,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Editar · ${widget.diagram.title}'),
            actions: [
              IconButton(
                tooltip: 'Selecionar todos',
                onPressed: _selectAll,
                icon: const Icon(Icons.select_all),
              ),
              IconButton(
                tooltip: 'Copiar seleção',
                onPressed: _selectedIds.isEmpty ? null : _copySelected,
                icon: const Icon(Icons.copy_outlined),
              ),
              IconButton(
                tooltip: 'Recortar seleção',
                onPressed: _selectedIds.isEmpty ? null : _cutSelected,
                icon: const Icon(Icons.content_cut),
              ),
              IconButton(
                tooltip: 'Colar blocos',
                onPressed: _clipboard.isEmpty ? null : _paste,
                icon: const Icon(Icons.content_paste),
              ),
              IconButton(
                tooltip: 'Novo bloco',
                onPressed: _createNode,
                icon: const Icon(Icons.add_box_outlined),
              ),
              IconButton(
                tooltip: 'Excluir seleção',
                onPressed: _selectedIds.isEmpty && _selectedEdgeIndexes.isEmpty
                    ? null
                    : _deleteSelection,
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                tooltip: 'Conectar dois blocos selecionados',
                onPressed: _selectedIds.length == 2 ? _createEdge : null,
                icon: const Icon(Icons.account_tree_outlined),
              ),
              IconButton(
                tooltip: 'Editar conexões',
                onPressed: _edges.isEmpty ? null : _editEdges,
                icon: const Icon(Icons.link_outlined),
              ),
              IconButton(
                tooltip: 'Aumentar zoom',
                onPressed: () => _scaleCanvas(1.2),
                icon: const Icon(Icons.zoom_in),
              ),
              IconButton(
                tooltip: 'Reduzir zoom',
                onPressed: () => _scaleCanvas(0.8),
                icon: const Icon(Icons.zoom_out),
              ),
              IconButton(
                tooltip: 'Ajustar ao canvas',
                onPressed: _fitCanvas,
                icon: const Icon(Icons.fit_screen_outlined),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Salvar'),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Arraste no espaço vazio para selecionar blocos. Segure e arraste um bloco para mover toda a seleção. Ctrl/Cmd+C, X e V também funcionam.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                Expanded(child: _buildEditorViewport(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_nodes.length} blocos · ${_edges.length} ligações · ${_selectedIds.length} blocos selecionados · ${_selectedEdgeIndexes.length} conexões selecionadas',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorViewport(BuildContext context) {
    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.35,
          maxScale: 3.5,
          boundaryMargin: const EdgeInsets.all(180),
          constrained: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 1100,
              height: 720,
              child: _buildCanvas(context),
            ),
          ),
        ),
        Positioned(right: 18, top: 18, child: _buildMiniMap(context)),
      ],
    );
  }

  Widget _buildMiniMap(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 150,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CustomPaint(
            painter: _MiniMapPainter(nodes: _nodes, edges: _edges),
            child: const Center(
              child: Text('minimapa', style: TextStyle(fontSize: 10)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: _startAreaSelection,
            onPanUpdate: _updateAreaSelection,
            onPanEnd: (_) => setState(() {
              _selectionStart = null;
              _selectionRect = null;
            }),
            onTapUp: (details) => _selectEdgeAt(details.localPosition),
            child: const SizedBox.expand(),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _EditorEdgesPainter(
                nodes: _nodes,
                edges: _edges,
                color: Theme.of(context).colorScheme,
                selectedIndexes: _selectedEdgeIndexes,
              ),
            ),
          ),
        ),
        ..._nodes.map((node) => _buildNode(context, node)),
        if (_selectionRect != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SelectionPainter(rect: _selectionRect!),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNode(BuildContext context, Map<String, dynamic> node) {
    final id = node['id']?.toString() ?? '';
    final position = _position(node);
    final selected = _selectedIds.contains(id);
    final width = _number(node['width'], 170);
    final height = _number(node['height'], 64);
    final shape = node['shape']?.toString() ?? 'rounded';
    final nodeColor = _colorFromValue(
      node['color'],
      Theme.of(context).colorScheme.primaryContainer,
    );
    return Positioned(
      left: position.dx - width / 2,
      top: position.dy - height / 2,
      child: Listener(
        key: ValueKey('diagram-node-$id'),
        onPointerDown: (_) => _startNodeDrag(id),
        onPointerMove: (event) => _updateNodeDrag(event.delta),
        onPointerUp: (_) {
          _dragStartPositions = {};
          _dragOffset = Offset.zero;
        },
        onPointerCancel: (_) {
          _dragStartPositions = {};
          _dragOffset = Offset.zero;
        },
        child: GestureDetector(
          onTap: () => _selectNode(id),
          onDoubleTap: () => _editNode(node),
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            decoration: _nodeDecoration(
              nodeColor: selected
                  ? Theme.of(context).colorScheme.primary
                  : nodeColor,
              borderColor: selected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
              shape: shape,
              selected: selected,
            ),
            child: Text(
              node['label']?.toString() ?? id,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected
                    ? Theme.of(context).colorScheme.onPrimary
                    : _contrastColor(nodeColor),
                fontSize: _number(node['fontSize'], 14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectNode(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _startAreaSelection(DragStartDetails details) {
    setState(() {
      _selectedIds.clear();
      _selectionStart = details.localPosition;
      _selectionRect = Rect.fromPoints(
        details.localPosition,
        details.localPosition,
      );
    });
  }

  void _updateAreaSelection(DragUpdateDetails details) {
    final start = _selectionStart;
    if (start == null) return;
    final rect = Rect.fromPoints(start, details.localPosition);
    final selected = <String>{};
    for (final node in _nodes) {
      final id = node['id']?.toString() ?? '';
      final center = _position(node);
      if (rect.overlaps(
        Rect.fromCenter(
          center: center,
          width: _number(node['width'], 170),
          height: _number(node['height'], 64),
        ),
      )) {
        selected.add(id);
      }
    }
    setState(() {
      _selectionRect = rect;
      _selectedIds
        ..clear()
        ..addAll(selected);
    });
  }

  void _selectEdgeAt(Offset point) {
    final positions = {
      for (final node in _nodes) node['id'].toString(): _position(node),
    };
    var closestIndex = -1;
    var closestDistance = double.infinity;
    for (var index = 0; index < _edges.length; index++) {
      final edge = _edges[index];
      final from = positions[edge['source']?.toString()];
      final to = positions[edge['target']?.toString()];
      if (from == null || to == null) continue;
      final distance = _distanceToSegment(point, from, to);
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = index;
      }
    }
    setState(() {
      _selectedIds.clear();
      if (closestIndex < 0 || closestDistance > 14) {
        _selectedEdgeIndexes.clear();
        return;
      }
      if (_selectedEdgeIndexes.contains(closestIndex)) {
        _selectedEdgeIndexes.remove(closestIndex);
      } else {
        _selectedEdgeIndexes.add(closestIndex);
      }
    });
  }

  void _startNodeDrag(String id) {
    if (!_selectedIds.contains(id)) {
      _selectedIds
        ..clear()
        ..add(id);
    }
    _dragStartPositions = {
      for (final node in _nodes)
        if (_selectedIds.contains(node['id']?.toString()))
          node['id'].toString(): _position(node),
    };
    _dragOffset = Offset.zero;
  }

  void _updateNodeDrag(Offset delta) {
    if (_dragStartPositions.isEmpty) return;
    _dragOffset += delta;
    setState(() {
      _nodes = _nodes
          .map((node) {
            final id = node['id']?.toString();
            final start = id == null ? null : _dragStartPositions[id];
            if (start == null) return node;
            return {
              ...node,
              'x': start.dx + _dragOffset.dx,
              'y': start.dy + _dragOffset.dy,
            };
          })
          .toList(growable: false);
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(_nodes.map((node) => node['id'].toString()));
    });
  }

  Future<void> _createNode() async {
    final node = await showDunotsDrawer<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _NodeEditorDialog(),
    );
    if (node == null) return;
    final index = _nodes.length;
    setState(() {
      _nodes = [
        ..._nodes,
        {
          ...node,
          'id': 'node-${DateTime.now().microsecondsSinceEpoch}',
          'x': 140.0 + (index % 4) * 220,
          'y': 120.0 + (index ~/ 4) * 130,
        },
      ];
    });
  }

  void _deleteSelection() {
    if (_selectedIds.isEmpty && _selectedEdgeIndexes.isEmpty) return;
    setState(() {
      _nodes = _nodes
          .where((node) => !_selectedIds.contains(node['id']?.toString()))
          .toList(growable: false);
      _edges = _edges
          .asMap()
          .entries
          .where((entry) {
            final edge = entry.value;
            final touchesDeletedNode =
                _selectedIds.contains(edge['source']?.toString()) ||
                _selectedIds.contains(edge['target']?.toString());
            return !_selectedEdgeIndexes.contains(entry.key) &&
                !touchesDeletedNode;
          })
          .map((entry) => entry.value)
          .toList(growable: false);
      _selectedIds.clear();
      _selectedEdgeIndexes.clear();
    });
  }

  Future<void> _createEdge() async {
    if (_selectedIds.length != 2) return;
    final selected = _selectedIds.toList(growable: false);
    final edge = await showDunotsDrawer<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EdgeEditorDialog(
        initial: const {},
        source: selected[0],
        target: selected[1],
      ),
    );
    if (edge == null) return;
    setState(() => _edges = [..._edges, edge]);
  }

  Future<void> _editNode(Map<String, dynamic> node) async {
    final updated = await showDunotsDrawer<Map<String, dynamic>>(
      context: context,
      builder: (_) => _NodeEditorDialog(initial: node),
    );
    if (updated == null) return;
    setState(() {
      final id = node['id']?.toString();
      _nodes = _nodes
          .map(
            (item) =>
                item['id']?.toString() == id ? {...item, ...updated} : item,
          )
          .toList(growable: false);
    });
  }

  Future<void> _editEdges() async {
    final result = await showDunotsDrawer<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) =>
          _EdgeListDialog(edges: _edges, onEdit: (index) => _editEdge(index)),
    );
    if (result != null) setState(() => _edges = result);
  }

  Future<Map<String, dynamic>?> _editEdge(int index) async {
    final updated = await showDunotsDrawer<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EdgeEditorDialog(
        initial: _edges[index],
        source: _edges[index]['source']?.toString() ?? '',
        target: _edges[index]['target']?.toString() ?? '',
      ),
    );
    if (updated == null) return null;
    setState(() {
      _edges = _edges
          .asMap()
          .entries
          .map(
            (entry) =>
                entry.key == index ? {...entry.value, ...updated} : entry.value,
          )
          .toList(growable: false);
    });
    return updated;
  }

  void _scaleCanvas(double factor) {
    final current = _transformController.value.getMaxScaleOnAxis();
    final next = (current * factor).clamp(0.35, 3.5);
    _transformController.value = Matrix4.identity()
      ..scaleByDouble(next, next, 1, 1);
  }

  void _fitCanvas() {
    _transformController.value = Matrix4.identity();
  }

  void _copySelected() {
    _clipboard
      ..clear()
      ..addAll(
        _nodes
            .where((node) => _selectedIds.contains(node['id']?.toString()))
            .map((node) => {...node}),
      );
    _clipboardEdges
      ..clear()
      ..addAll(
        _edges
            .where(
              (edge) =>
                  _selectedIds.contains(edge['source']?.toString()) &&
                  _selectedIds.contains(edge['target']?.toString()),
            )
            .map((edge) => {...edge}),
      );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_clipboard.length} bloco(s) copiado(s).')),
      );
      setState(() {});
    }
  }

  void _cutSelected() {
    if (_selectedIds.isEmpty) return;
    _copySelected();
    setState(() {
      _nodes = _nodes
          .where((node) => !_selectedIds.contains(node['id']?.toString()))
          .toList(growable: false);
      _edges = _edges
          .where(
            (edge) =>
                !_selectedIds.contains(edge['source']?.toString()) &&
                !_selectedIds.contains(edge['target']?.toString()),
          )
          .toList(growable: false);
      _selectedIds.clear();
    });
  }

  void _paste() {
    if (_clipboard.isEmpty) return;
    final idMap = <String, String>{};
    final pasted = <Map<String, dynamic>>[];
    for (final source in _clipboard) {
      final oldId = source['id'].toString();
      final newId =
          'node-${DateTime.now().microsecondsSinceEpoch}-${pasted.length}';
      idMap[oldId] = newId;
      pasted.add({
        ...source,
        'id': newId,
        'x': (_position(source).dx + 40),
        'y': (_position(source).dy + 40),
      });
    }
    final pastedEdges = _clipboardEdges
        .where(
          (edge) =>
              idMap.containsKey(edge['source']?.toString()) &&
              idMap.containsKey(edge['target']?.toString()),
        )
        .map(
          (edge) => {
            ...edge,
            'source': idMap[edge['source'].toString()],
            'target': idMap[edge['target'].toString()],
          },
        );
    setState(() {
      _nodes = [..._nodes, ...pasted];
      _edges = [..._edges, ...pastedEdges];
      _selectedIds
        ..clear()
        ..addAll(pasted.map((node) => node['id'].toString()));
    });
  }

  Offset _position(Map<String, dynamic> node) => Offset(
    (node['x'] as num?)?.toDouble() ?? 80,
    (node['y'] as num?)?.toDouble() ?? 80,
  );

  double _number(Object? value, double fallback) =>
      value is num ? value.toDouble() : fallback;

  Color _colorFromValue(Object? value, Color fallback) {
    if (value is String) {
      final normalized = value.replaceFirst('#', '');
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed != null) {
        return Color(normalized.length <= 6 ? 0xFF000000 | parsed : parsed);
      }
    }
    return fallback;
  }

  Color _contrastColor(Color color) =>
      color.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

  BoxDecoration _nodeDecoration({
    required Color nodeColor,
    required Color borderColor,
    required String shape,
    required bool selected,
  }) {
    final radius = shape == 'ellipse'
        ? const BorderRadius.all(Radius.elliptical(90, 45))
        : shape == 'diamond'
        ? const BorderRadius.all(Radius.circular(4))
        : BorderRadius.circular(shape == 'rectangle' ? 2 : 12);
    return BoxDecoration(
      color: nodeColor,
      borderRadius: radius,
      border: Border.all(color: borderColor, width: selected ? 3 : 1),
      boxShadow: shape == 'shadow'
          ? const [BoxShadow(blurRadius: 8, color: Colors.black26)]
          : null,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.repository.update(
        widget.diagram.copyWith(
          nodes: _nodes,
          edges: _edges,
          updatedAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Map<String, dynamic>> _cloneMaps(List<Map<String, dynamic>> values) =>
      values.map((value) => Map<String, dynamic>.from(value)).toList();
}

double _distanceToSegment(Offset point, Offset start, Offset end) {
  final vector = end - start;
  final lengthSquared = vector.dx * vector.dx + vector.dy * vector.dy;
  if (lengthSquared == 0) return (point - start).distance;
  final projection =
      ((point.dx - start.dx) * vector.dx + (point.dy - start.dy) * vector.dy) /
      lengthSquared;
  final t = projection.clamp(0.0, 1.0);
  final projected = Offset(start.dx + vector.dx * t, start.dy + vector.dy * t);
  return (point - projected).distance;
}

class _EditorEdgesPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;
  final ColorScheme color;
  final Set<int> selectedIndexes;

  const _EditorEdgesPainter({
    required this.nodes,
    required this.edges,
    required this.color,
    required this.selectedIndexes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final positions = {
      for (final node in nodes)
        node['id'].toString(): Offset(
          (node['x'] as num?)?.toDouble() ?? 80,
          (node['y'] as num?)?.toDouble() ?? 80,
        ),
    };
    for (var index = 0; index < edges.length; index++) {
      final edge = edges[index];
      final from = positions[edge['source']?.toString()];
      final to = positions[edge['target']?.toString()];
      if (from == null || to == null) continue;
      final paint = Paint()
        ..color = selectedIndexes.contains(index)
            ? color.secondary
            : _paintColor(edge['color'], color.primary.withValues(alpha: 0.65))
        ..strokeWidth = _paintNumber(edge['width'], 2.5)
        ..style = PaintingStyle.stroke;
      final dashed = edge['style']?.toString() == 'dashed';
      if (dashed) {
        _drawDashedLine(canvas, from, to, paint);
      } else {
        canvas.drawLine(from, to, paint);
      }
      if (edge['arrow'] != false) _drawArrow(canvas, from, to, paint);
      final label = edge['label']?.toString().trim() ?? '';
      if (label.isNotEmpty) {
        final midpoint = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
        final text = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(color: paint.color, fontSize: 12),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 180);
        text.paint(canvas, midpoint - Offset(text.width / 2, text.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EditorEdgesPainter oldDelegate) => true;
}

Color _paintColor(Object? value, Color fallback) {
  if (value is String) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(normalized.length <= 6 ? 0xFF000000 | parsed : parsed);
    }
  }
  return fallback;
}

double _paintNumber(Object? value, double fallback) =>
    value is num ? value.toDouble() : fallback;

void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  final distance = (to - from).distance;
  final direction = (to - from) / distance;
  for (var start = 0.0; start < distance; start += 12) {
    final end = math.min(start + 7, distance);
    canvas.drawLine(from + direction * start, from + direction * end, paint);
  }
}

void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
  final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
  const size = 9.0;
  final path = Path()
    ..moveTo(to.dx, to.dy)
    ..lineTo(
      to.dx - size * math.cos(angle - math.pi / 6),
      to.dy - size * math.sin(angle - math.pi / 6),
    )
    ..moveTo(to.dx, to.dy)
    ..lineTo(
      to.dx - size * math.cos(angle + math.pi / 6),
      to.dy - size * math.sin(angle + math.pi / 6),
    );
  canvas.drawPath(path, paint);
}

class _SelectionPainter extends CustomPainter {
  final Rect rect;

  const _SelectionPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _SelectionPainter oldDelegate) =>
      oldDelegate.rect != rect;
}

class _MiniMapPainter extends CustomPainter {
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> edges;

  const _MiniMapPainter({required this.nodes, required this.edges});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    final bounds = _diagramBounds(nodes);
    final scale = math.min(
      size.width / math.max(bounds.width, 1),
      size.height / math.max(bounds.height, 1),
    );
    final offset = Offset(
      (size.width - bounds.width * scale) / 2 - bounds.left * scale,
      (size.height - bounds.height * scale) / 2 - bounds.top * scale,
    );

    Offset mapPoint(Map<String, dynamic> node) =>
        Offset(
              (node['x'] as num?)?.toDouble() ?? 80,
              (node['y'] as num?)?.toDouble() ?? 80,
            ) *
            scale +
        offset;

    final positions = {
      for (final node in nodes) node['id'].toString(): mapPoint(node),
    };
    final edgePaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.65)
      ..strokeWidth = 1;
    for (final edge in edges) {
      final from = positions[edge['source']?.toString()];
      final to = positions[edge['target']?.toString()];
      if (from != null && to != null) canvas.drawLine(from, to, edgePaint);
    }

    final nodePaint = Paint()..color = Colors.blueAccent;
    for (final node in nodes) {
      final center = mapPoint(node);
      canvas.drawRect(
        Rect.fromCenter(center: center, width: 8, height: 5),
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniMapPainter oldDelegate) => true;
}

Rect _diagramBounds(List<Map<String, dynamic>> nodes) {
  final points = nodes
      .map((node) {
        return Offset(
          (node['x'] as num?)?.toDouble() ?? 80,
          (node['y'] as num?)?.toDouble() ?? 80,
        );
      })
      .toList(growable: false);
  final minX = points.map((point) => point.dx).reduce(math.min);
  final maxX = points.map((point) => point.dx).reduce(math.max);
  final minY = points.map((point) => point.dy).reduce(math.min);
  final maxY = points.map((point) => point.dy).reduce(math.max);
  return Rect.fromLTRB(minX - 90, minY - 50, maxX + 90, maxY + 50);
}

class _NodeEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;

  const _NodeEditorDialog({this.initial});

  @override
  State<_NodeEditorDialog> createState() => _NodeEditorDialogState();
}

class _NodeEditorDialogState extends State<_NodeEditorDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _colorController;
  late final TextEditingController _fontSizeController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late String _shape;

  static const _shapes = [
    'rounded',
    'rectangle',
    'ellipse',
    'diamond',
    'shadow',
  ];

  @override
  void initState() {
    super.initState();
    final node = widget.initial ?? const <String, dynamic>{};
    _labelController = TextEditingController(
      text: node['label']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: node['color']?.toString() ?? '#334155',
    );
    _fontSizeController = TextEditingController(
      text: (node['fontSize'] as num?)?.toString() ?? '14',
    );
    _widthController = TextEditingController(
      text: (node['width'] as num?)?.toString() ?? '170',
    );
    _heightController = TextEditingController(
      text: (node['height'] as num?)?.toString() ?? '64',
    );
    final initialShape = node['shape']?.toString() ?? 'rounded';
    _shape = _shapes.contains(initialShape) ? initialShape : 'rounded';
  }

  @override
  void dispose() {
    _labelController.dispose();
    _colorController.dispose();
    _fontSizeController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: widget.initial == null ? 'Novo bloco' : 'Editar bloco',
      subtitle: 'Defina o texto e a aparência do bloco.',
      icon: Icons.crop_square_outlined,
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        children: [
          TextField(
            controller: _labelController,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Texto *'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _shape,
            decoration: const InputDecoration(labelText: 'Formato'),
            items: _shapes
                .map(
                  (shape) => DropdownMenuItem(value: shape, child: Text(shape)),
                )
                .toList(),
            onChanged: (value) => setState(() => _shape = value ?? 'rounded'),
          ),
          TextField(
            controller: _colorController,
            decoration: const InputDecoration(
              labelText: 'Cor',
              hintText: '#334155 ou 0xFF334155',
            ),
          ),
          _numberField(_fontSizeController, 'Fonte'),
          _numberField(_widthController, 'Largura'),
          _numberField(_heightController, 'Altura'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.initial == null ? 'Criar' : 'Salvar'),
        ),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  void _submit() {
    final label = _labelController.text.trim();
    if (label.isEmpty) return;
    final values = <String, dynamic>{
      'label': label,
      'shape': _shape,
      'color': _colorController.text.trim(),
      'fontSize': _positiveNumber(_fontSizeController.text, 14),
      'width': _positiveNumber(_widthController.text, 170),
      'height': _positiveNumber(_heightController.text, 64),
    };
    Navigator.of(context).pop(values);
  }
}

class _EdgeEditorDialog extends StatefulWidget {
  final Map<String, dynamic> initial;
  final String source;
  final String target;

  const _EdgeEditorDialog({
    required this.initial,
    required this.source,
    required this.target,
  });

  @override
  State<_EdgeEditorDialog> createState() => _EdgeEditorDialogState();
}

class _EdgeEditorDialogState extends State<_EdgeEditorDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _colorController;
  late final TextEditingController _widthController;
  late String _style;
  late bool _arrow;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.initial['label']?.toString() ?? '',
    );
    _colorController = TextEditingController(
      text: widget.initial['color']?.toString() ?? '#64748B',
    );
    _widthController = TextEditingController(
      text: (widget.initial['width'] as num?)?.toString() ?? '2.5',
    );
    _style = widget.initial['style']?.toString() == 'dashed'
        ? 'dashed'
        : 'solid';
    _arrow = widget.initial['arrow'] != false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _colorController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: 'Editar conexão',
      subtitle: '${widget.source} → ${widget.target}',
      icon: Icons.link_outlined,
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(labelText: 'Rótulo'),
          ),
          TextField(
            controller: _colorController,
            decoration: const InputDecoration(labelText: 'Cor'),
          ),
          TextField(
            controller: _widthController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Espessura'),
          ),
          DropdownButtonFormField<String>(
            initialValue: _style,
            decoration: const InputDecoration(labelText: 'Estilo'),
            items: const [
              DropdownMenuItem(value: 'solid', child: Text('Sólida')),
              DropdownMenuItem(value: 'dashed', child: Text('Tracejada')),
            ],
            onChanged: (value) => setState(() => _style = value ?? 'solid'),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _arrow,
            onChanged: (value) => setState(() => _arrow = value ?? true),
            title: const Text('Exibir seta'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Salvar')),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop({
      'source': widget.source,
      'target': widget.target,
      'label': _labelController.text.trim(),
      'color': _colorController.text.trim(),
      'width': _positiveNumber(_widthController.text, 2.5),
      'style': _style,
      'arrow': _arrow,
    });
  }
}

class _EdgeListDialog extends StatefulWidget {
  final List<Map<String, dynamic>> edges;
  final Future<Map<String, dynamic>?> Function(int index) onEdit;

  const _EdgeListDialog({required this.edges, required this.onEdit});

  @override
  State<_EdgeListDialog> createState() => _EdgeListDialogState();
}

class _EdgeListDialogState extends State<_EdgeListDialog> {
  late List<Map<String, dynamic>> _edges;

  @override
  void initState() {
    super.initState();
    _edges = widget.edges.map(Map<String, dynamic>.from).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: 'Conexões',
      subtitle: 'Edite ou remova as ligações entre os blocos.',
      icon: Icons.link_outlined,
      scrollable: false,
      // ignore: sort_child_properties_last
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.sizeOf(context).height * 0.48,
        child: _edges.isEmpty
            ? const Text('Nenhuma conexão cadastrada.')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: _edges.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final edge = _edges[index];
                  final source = edge['source']?.toString() ?? '?';
                  final target = edge['target']?.toString() ?? '?';
                  final label = edge['label']?.toString().trim() ?? '';
                  return ListTile(
                    dense: true,
                    title: Text('$source → $target'),
                    subtitle: label.isEmpty ? null : Text(label),
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Editar conexão',
                          onPressed: () => _edit(index),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Excluir conexão',
                          onPressed: () =>
                              setState(() => _edges.removeAt(index)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_edges),
          child: const Text('Concluir'),
        ),
      ],
    );
  }

  Future<void> _edit(int index) async {
    final updated = await widget.onEdit(index);
    if (updated == null || !mounted) return;
    setState(() => _edges[index] = updated);
  }
}

double _positiveNumber(String value, double fallback) {
  final parsed = double.tryParse(value.replaceAll(',', '.'));
  if (parsed == null || parsed <= 0) return fallback;
  return parsed;
}
