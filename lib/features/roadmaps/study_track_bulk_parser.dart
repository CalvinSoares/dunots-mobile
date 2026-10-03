/// Item reconhecido no texto de criação de uma trilha em massa.
class StudyTrackImportItem {
  final String title;
  final String? description;
  final int depth;

  const StudyTrackImportItem({
    required this.title,
    required this.depth,
    this.description,
  });
}

/// Mantém o formato de importação usado pelo desktop:
/// `Nome | descrição`, com dois espaços de indentação para filhos.
List<StudyTrackImportItem> parseStudyTrackImportText(String text) {
  final normalizedText = text
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'&#x20;|&nbsp;', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\\\s*(?=\S)'), '\n');
  final rawLines = normalizedText.split(RegExp(r'\r?\n'));
  final hasParts = rawLines.any(
    (line) => RegExp(r'^\s*PARTE\s+\d+', caseSensitive: false).hasMatch(line),
  );
  var hasSection = false;
  var inCodeBlock = false;
  final codeLines = <String>[];
  final items = <StudyTrackImportItem>[];

  void appendCodeToLastItem() {
    if (codeLines.isEmpty || items.isEmpty) return;
    final last = items.removeLast();
    final code = codeLines.join(' ').trim();
    final description = [
      last.description,
      code,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ').trim();
    items.add(
      StudyTrackImportItem(
        title: last.title,
        depth: last.depth,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  for (final rawLine in rawLines) {
    final trimmedRaw = rawLine.trim();
    if (trimmedRaw.startsWith('```')) {
      if (inCodeBlock) appendCodeToLastItem();
      inCodeBlock = !inCodeBlock;
      codeLines.clear();
      continue;
    }
    if (inCodeBlock) {
      if (trimmedRaw.isNotEmpty) codeLines.add(trimmedRaw);
      continue;
    }

    final indentation = RegExp(r'^\s*').firstMatch(rawLine)?.group(0) ?? '';
    final content = rawLine
        .replaceFirst(RegExp(r'^\s*[-*•]\s*'), '')
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .replaceFirst(RegExp(r'\\\s*$'), '')
        .trim();
    if (content.isEmpty) continue;

    final parts = content.split('|');
    final title = parts.first.trim();
    final description = parts.skip(1).join('|').trim();
    final isFormattingOnly = RegExp(r'^[~|\\↔→←—–_.\s-]+$').hasMatch(title);
    final isStandaloneFormula =
        RegExp(r'^[Nn\d\s()+−*/.,=<>≤≥_^|\\-]+$').hasMatch(title) &&
        RegExp(r'[+\-−*/=]').hasMatch(title);
    if (title.isEmpty || isFormattingOnly || isStandaloneFormula) continue;

    final isPart = RegExp(
      r'^PARTE\s+\d+',
      caseSensitive: false,
    ).hasMatch(title);
    final isNumberedSection = RegExp(r'^\d+\.\s+').hasMatch(title);
    if (isNumberedSection) hasSection = true;
    final inferredDepth = isPart
        ? 0
        : isNumberedSection
        ? (hasParts ? 2 : 0)
        : hasSection
        ? (hasParts ? 4 : 2)
        : 0;
    final depth = inferredDepth > indentation.replaceAll('\t', '  ').length
        ? inferredDepth
        : indentation.replaceAll('\t', '  ').length;

    items.add(
      StudyTrackImportItem(
        title: title,
        depth: depth,
        description: description.isEmpty ? null : description,
      ),
    );
  }

  if (inCodeBlock) appendCodeToLastItem();
  return List.unmodifiable(items);
}
