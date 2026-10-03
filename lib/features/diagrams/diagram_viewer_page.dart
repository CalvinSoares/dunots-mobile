import 'package:flutter/material.dart';

import 'diagram_painter.dart';
import 'domain/study_diagram.dart';

class DiagramViewerPage extends StatelessWidget {
  final StudyDiagram diagram;

  const DiagramViewerPage({super.key, required this.diagram});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(diagram.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            if (diagram.description.isNotEmpty) ...[
              Text(diagram.description),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 520,
              child: InteractiveViewer(
                boundaryMargin: const EdgeInsets.all(120),
                minScale: 0.5,
                maxScale: 3,
                child: CustomPaint(
                  size: const Size(820, 480),
                  painter: StudyDiagramPainter(
                    diagram: diagram,
                    color: Theme.of(context).colorScheme,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${diagram.nodes.length} blocos · ${diagram.edges.length} ligações',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
