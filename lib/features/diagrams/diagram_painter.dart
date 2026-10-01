import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'domain/study_diagram.dart';

class StudyDiagramPainter extends CustomPainter {
  final StudyDiagram diagram;
  final ColorScheme color;

  const StudyDiagramPainter({required this.diagram, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final positions = <String, Offset>{};
    for (var index = 0; index < diagram.nodes.length; index++) {
      final node = diagram.nodes[index];
      final id = node['id']?.toString() ?? 'node-$index';
      positions[id] = Offset(
        _number(node['x'], 70 + (index % 3) * 210),
        _number(node['y'], 70 + (index ~/ 3) * 120),
      );
    }

    for (final edge in diagram.edges) {
      final from = positions[edge['source']?.toString()];
      final to = positions[edge['target']?.toString()];
      if (from == null || to == null) continue;
      final paint = Paint()
        ..color = _color(edge['color'], color.primary.withValues(alpha: 0.7))
        ..strokeWidth = _number(edge['width'], 2.5)
        ..style = PaintingStyle.stroke;
      if (edge['style']?.toString() == 'dashed') {
        _drawDashedLine(canvas, from, to, paint);
      } else {
        canvas.drawLine(from, to, paint);
      }
      if (edge['arrow'] != false) _drawArrow(canvas, from, to, paint);
      _drawEdgeLabel(canvas, edge['label'], from, to, paint.color);
    }

    for (var index = 0; index < diagram.nodes.length; index++) {
      final node = diagram.nodes[index];
      final id = node['id']?.toString() ?? 'node-$index';
      final center = positions[id]!;
      final width = _number(node['width'], 170);
      final height = _number(node['height'], 64);
      final fill = _color(node['color'], color.primaryContainer);
      final border = Paint()
        ..color = color.primary
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final fillPaint = Paint()..color = fill;
      _drawNode(
        canvas,
        center: center,
        width: width,
        height: height,
        shape: node['shape']?.toString() ?? 'rounded',
        fill: fillPaint,
        border: border,
      );
      final text = TextPainter(
        text: TextSpan(
          text: node['label']?.toString() ?? id,
          style: TextStyle(
            color: _contrastColor(fill),
            fontSize: _number(node['fontSize'], 14),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 4,
        ellipsis: '…',
      )..layout(maxWidth: math.max(width - 24, 40));
      text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant StudyDiagramPainter oldDelegate) =>
      oldDelegate.diagram != diagram || oldDelegate.color != color;
}

void _drawNode(
  Canvas canvas, {
  required Offset center,
  required double width,
  required double height,
  required String shape,
  required Paint fill,
  required Paint border,
}) {
  final rect = Rect.fromCenter(center: center, width: width, height: height);
  if (shape == 'ellipse') {
    canvas.drawOval(rect, fill);
    canvas.drawOval(rect, border);
    return;
  }
  if (shape == 'diamond') {
    final path = Path()
      ..moveTo(center.dx, rect.top)
      ..lineTo(rect.right, center.dy)
      ..lineTo(center.dx, rect.bottom)
      ..lineTo(rect.left, center.dy)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, border);
    return;
  }
  final radius = shape == 'rectangle' ? 2.0 : 12.0;
  final rounded = RRect.fromRectAndRadius(rect, Radius.circular(radius));
  canvas.drawRRect(rounded, fill);
  canvas.drawRRect(rounded, border);
  if (shape == 'shadow') {
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rounded.shift(const Offset(0, 3)), shadow);
  }
}

void _drawEdgeLabel(
  Canvas canvas,
  Object? value,
  Offset from,
  Offset to,
  Color color,
) {
  final label = value?.toString().trim() ?? '';
  if (label.isEmpty) return;
  final midpoint = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
  final text = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(color: color, fontSize: 12),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: 180);
  text.paint(canvas, midpoint - Offset(text.width / 2, text.height / 2));
}

Color _color(Object? value, Color fallback) {
  if (value is String) {
    final normalized = value.replaceFirst('#', '').replaceFirst('0x', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed != null) {
      return Color(normalized.length <= 6 ? 0xFF000000 | parsed : parsed);
    }
  }
  return fallback;
}

double _number(Object? value, double fallback) =>
    value is num ? value.toDouble() : fallback;

Color _contrastColor(Color value) =>
    value.computeLuminance() > 0.55 ? Colors.black87 : Colors.white;

void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
  final distance = (to - from).distance;
  if (distance == 0) return;
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
