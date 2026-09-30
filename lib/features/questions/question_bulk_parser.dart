class BulkQuestionAlternative {
  final String label;
  final String text;
  final bool markedCorrect;

  const BulkQuestionAlternative({
    required this.label,
    required this.text,
    required this.markedCorrect,
  });
}

class BulkParsedQuestion {
  final int? number;
  final String statement;
  final List<BulkQuestionAlternative> alternatives;
  final int? correctAlternativeIndex;
  final String? error;
  final int? sourcePage;

  const BulkParsedQuestion({
    required this.number,
    required this.statement,
    required this.alternatives,
    required this.correctAlternativeIndex,
    this.error,
    this.sourcePage,
  });

  bool get isValid => error == null;
}

class BulkQuestionParseResult {
  final List<BulkParsedQuestion> questions;
  final List<String> errors;

  const BulkQuestionParseResult({
    required this.questions,
    required this.errors,
  });

  bool get isValid => questions.isNotEmpty && errors.isEmpty;
}

/// Parser tolerante para o cadastro rápido de questões.
///
/// Formatos aceitos:
///
/// ```text
/// 1. Enunciado da questão
/// A) Alternativa A
/// B) Alternativa B [x]
/// C) Alternativa C
///
/// 2) Outro enunciado
/// A. Alternativa A
/// B. Alternativa B
/// Gabarito: 2-C
/// ```
///
/// A marcação pode ser `[x]`, `X` ou `*` no início/fim da alternativa.
/// O gabarito também pode ser informado em uma linha separada como
/// `Gabarito: 1-B, 2-C`.
BulkQuestionParseResult parseBulkQuestions(
  String input, {
  bool allowNumberOnly = false,
}) {
  final lines = input
      .replaceAll('\uFEFF', '')
      .replaceAll('\u00A0', ' ')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final drafts = <_QuestionDraft>[];
  final answerKey = <int, String>{};
  _QuestionDraft? current;
  var currentPage = 1;

  void finishCurrent() {
    if (current != null) drafts.add(current!);
    current = null;
  }

  for (final rawLine in lines) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;

    final pageMarker = RegExp(r'^\[\[DUNOTS_PAGE:(\d+)\]\]$').firstMatch(line);
    if (pageMarker != null) {
      currentPage = int.parse(pageMarker.group(1)!);
      continue;
    }

    final answerKeyMatch = _answerKeyPattern.firstMatch(line);
    if (answerKeyMatch != null) {
      final answerValue = answerKeyMatch.group(1)?.trim() ?? '';
      _readAnswerKey(answerValue, answerKey);
      final singleAnswer = RegExp(
        r'^[A-E]$',
        caseSensitive: false,
      ).firstMatch(answerValue);
      if (singleAnswer != null && current?.number != null) {
        answerKey[current!.number!] = singleAnswer.group(0)!.toUpperCase();
      }
      continue;
    }

    final questionMatch =
        _questionPattern.firstMatch(line) ??
        (allowNumberOnly ? _numberOnlyPattern.firstMatch(line) : null) ??
        (allowNumberOnly ? _numberWithSpacePattern.firstMatch(line) : null);
    if (questionMatch != null) {
      finishCurrent();
      final remainder = questionMatch.groupCount >= 2
          ? questionMatch.group(2)?.trim() ?? ''
          : '';
      final inline = _splitInlineAlternatives(remainder);
      current = _QuestionDraft(
        number: int.parse(questionMatch.group(1)!),
        statement: inline?.statement ?? remainder,
        sourcePage: currentPage,
      );
      if (inline != null) current!.alternatives.addAll(inline.alternatives);
      continue;
    }

    final draft = current;
    if (draft == null) continue;

    final alternatives = _extractAlternatives(line);
    if (alternatives.isNotEmpty) {
      draft.alternatives.addAll(alternatives);
    } else if (draft.alternatives.isEmpty) {
      draft.statement = _join(draft.statement, line);
    } else {
      final last = draft.alternatives.removeLast();
      draft.alternatives.add(
        _RawAlternative(
          label: last.label,
          text: _join(last.text, line),
          markedCorrect: last.markedCorrect,
        ),
      );
    }
  }
  finishCurrent();

  final questions = <BulkParsedQuestion>[];
  final errors = <String>[];
  final numbers = <int>{};
  for (final draft in drafts) {
    final parsed = _finishDraft(draft, answerKey);
    questions.add(parsed);
    if (parsed.error != null) {
      errors.add('Questão ${draft.number}: ${parsed.error}');
    }
    if (draft.number != null && !numbers.add(draft.number!)) {
      errors.add('Questão ${draft.number}: número duplicado.');
    }
  }
  if (questions.isEmpty) {
    errors.add('Nenhuma questão numerada foi encontrada.');
  }
  return BulkQuestionParseResult(
    questions: List.unmodifiable(questions),
    errors: List.unmodifiable(errors),
  );
}

final _questionPattern = RegExp(r'^\s*(\d{1,4})\s*[\.)]\s*(.*)$');
final _numberOnlyPattern = RegExp(r'^\s*(\d{1,4})\s*$');
final _numberWithSpacePattern = RegExp(r'^\s*(\d{1,4})\s+([A-Za-zÀ-ÿ].*)$');
final _answerKeyPattern = RegExp(
  r'^\s*(?:gabarito|respostas?|answer\s*key)\s*:?\s*(.*)$',
  caseSensitive: false,
);
final _alternativePattern = RegExp(
  r'^\s*\(?([A-Ea-e])(?:\)|\s*[\.:\)\-])\s*(.*)$',
);
final _compactAlternativePattern = RegExp(r'\(?([A-Ea-e])(?:\)|[\.:\)\-])\s*');

class _QuestionDraft {
  int? number;
  String statement;
  final List<_RawAlternative> alternatives = [];
  final int? sourcePage;

  _QuestionDraft({
    required this.number,
    required this.statement,
    required this.sourcePage,
  });
}

class _RawAlternative {
  final String label;
  final String text;
  final bool markedCorrect;

  const _RawAlternative({
    required this.label,
    required this.text,
    required this.markedCorrect,
  });
}

class _InlineQuestionSplit {
  final String statement;
  final List<_RawAlternative> alternatives;

  const _InlineQuestionSplit({
    required this.statement,
    required this.alternatives,
  });
}

_InlineQuestionSplit? _splitInlineAlternatives(String value) {
  final matches = _compactAlternativePattern.allMatches(value).toList();
  if (matches.length < 2 || matches.first.group(1)!.toUpperCase() != 'A') {
    return null;
  }
  final alternatives = <_RawAlternative>[];
  for (var index = 0; index < matches.length; index++) {
    final match = matches[index];
    final nextStart = index + 1 < matches.length
        ? matches[index + 1].start
        : value.length;
    final marked = _stripMarker(value.substring(match.end, nextStart).trim());
    alternatives.add(
      _RawAlternative(
        label: match.group(1)!.toUpperCase(),
        text: marked.text,
        markedCorrect: marked.marked,
      ),
    );
  }
  return _InlineQuestionSplit(
    statement: value.substring(0, matches.first.start).trim(),
    alternatives: alternatives,
  );
}

List<_RawAlternative> _extractAlternatives(String line) {
  final matches = _compactAlternativePattern.allMatches(line).toList();
  if (matches.length >= 2 && matches.first.group(1)!.toUpperCase() == 'A') {
    final alternatives = <_RawAlternative>[];
    for (var index = 0; index < matches.length; index++) {
      final match = matches[index];
      final nextStart = index + 1 < matches.length
          ? matches[index + 1].start
          : line.length;
      final rawText = line.substring(match.end, nextStart).trim();
      final marked = _stripMarker(rawText);
      alternatives.add(
        _RawAlternative(
          label: match.group(1)!.toUpperCase(),
          text: marked.text,
          markedCorrect: marked.marked,
        ),
      );
    }
    return alternatives;
  }

  final direct = _alternativePattern.firstMatch(line);
  if (direct != null) {
    final marked = _stripMarker(direct.group(2) ?? '');
    return [
      _RawAlternative(
        label: direct.group(1)!.toUpperCase(),
        text: marked.text,
        markedCorrect: marked.marked,
      ),
    ];
  }
  return const [];
}

_MarkerResult _stripMarker(String value) {
  var text = value.trim();
  var marked = false;
  final prefix = RegExp(r'^(?:\[x\]|x|\*)\s+', caseSensitive: false);
  final suffix = RegExp(r'\s+(?:\[x\]|x|\*)$\s*', caseSensitive: false);
  if (prefix.hasMatch(text)) {
    marked = true;
    text = text.replaceFirst(prefix, '');
  }
  if (suffix.hasMatch(text)) {
    marked = true;
    text = text.replaceFirst(suffix, '');
  }
  return _MarkerResult(text: text.trim(), marked: marked);
}

class _MarkerResult {
  final String text;
  final bool marked;

  const _MarkerResult({required this.text, required this.marked});
}

void _readAnswerKey(String value, Map<int, String> answerKey) {
  final pairPattern = RegExp(
    r'(\d{1,4})\s*(?:[-:\.)]|\s)\s*([A-E])',
    caseSensitive: false,
  );
  for (final match in pairPattern.allMatches(value)) {
    answerKey[int.parse(match.group(1)!)] = match.group(2)!.toUpperCase();
  }
}

BulkParsedQuestion _finishDraft(
  _QuestionDraft draft,
  Map<int, String> answerKey,
) {
  final alternatives = draft.alternatives
      .map(
        (alternative) => BulkQuestionAlternative(
          label: alternative.label,
          text: alternative.text,
          markedCorrect: alternative.markedCorrect,
        ),
      )
      .toList(growable: false);
  String? error;
  if (draft.statement.trim().isEmpty) {
    error = 'enunciado vazio.';
  } else if (alternatives.length < 2) {
    error = 'é necessário informar pelo menos duas alternativas.';
  } else if (alternatives.length > 5) {
    error = 'são permitidas no máximo cinco alternativas.';
  }
  final markedIndexes = alternatives
      .asMap()
      .entries
      .where((entry) => entry.value.markedCorrect)
      .map((entry) => entry.key)
      .toList(growable: false);
  final keyLabel = answerKey[draft.number];
  final keyIndex = keyLabel == null
      ? null
      : alternatives.indexWhere((alternative) => alternative.label == keyLabel);
  if (markedIndexes.length > 1) {
    error ??= 'mais de uma alternativa foi marcada como correta.';
  } else if (keyLabel != null && keyIndex == -1) {
    error ??= 'o gabarito $keyLabel não corresponde às alternativas.';
  } else if (markedIndexes.isNotEmpty &&
      keyIndex != null &&
      keyIndex != -1 &&
      markedIndexes.first != keyIndex) {
    error ??= 'a marcação da alternativa diverge do gabarito informado.';
  }
  final correctIndex = markedIndexes.length == 1
      ? markedIndexes.first
      : keyIndex != null && keyIndex >= 0
      ? keyIndex
      : null;
  if (correctIndex == null) {
    error ??= 'informe o gabarito ou marque uma alternativa com X, * ou [x].';
  }
  return BulkParsedQuestion(
    number: draft.number,
    statement: draft.statement.trim(),
    alternatives: List.unmodifiable(alternatives),
    correctAlternativeIndex: correctIndex,
    error: error,
    sourcePage: draft.sourcePage,
  );
}

String _join(String first, String second) {
  if (first.trim().isEmpty) return second.trim();
  if (second.trim().isEmpty) return first.trim();
  final separator = _looksStructured(first) || _looksStructured(second)
      ? '\n'
      : ' ';
  return '${first.trim()}$separator${second.trim()}';
}

bool _looksStructured(String value) {
  final normalized = value.trimLeft();
  return normalized.contains('|') ||
      normalized.contains('{') ||
      normalized.contains('}') ||
      normalized.contains(';') ||
      RegExp(
        r'^(?:SELECT|FROM|WHERE|JOIN|UNION|INSERT|UPDATE|DELETE|CREATE|ALTER|WITH|PUBLIC|PRIVATE|PROTECTED|CLASS|RETURN|VOID|INT|STRING)\b',
        caseSensitive: false,
      ).hasMatch(normalized);
}
