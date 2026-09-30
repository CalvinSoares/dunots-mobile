import '../../features/questions/domain/question.dart';
import '../../features/questions/domain/quiz_exam.dart';
import 'sync_contract.dart';

/// Converte provas e questões para o formato compartilhado com desktop/web.
/// O app mobile mantém sua representação conveniente para a UI, mas o pacote
/// de sincronização usa os mesmos nomes e estruturas do modelo QuizQuestion.
abstract final class QuizExamSyncMapper {
  static SyncRecord toRecord(QuizExam exam) {
    return SyncRecord({
      'id': exam.id,
      'title': exam.title,
      'contestName': exam.contestName,
      'vacancy': exam.vacancy,
      if (exam.proofVersion != null) 'proofVersion': exam.proofVersion,
      if (exam.board != null) 'board': exam.board,
      if (exam.year != null) 'year': exam.year,
      if (exam.sourceName != null) 'sourceName': exam.sourceName,
      if (exam.answerKeyName != null) 'answerKeyName': exam.answerKeyName,
      'createdAt': exam.createdAt.toUtc().toIso8601String(),
      'updatedAt': exam.updatedAt.toUtc().toIso8601String(),
    });
  }

  static QuizExam fromRecord(SyncRecord record) {
    final values = record.values;
    final createdAt = _date(values['createdAt']);
    return QuizExam(
      id: record.id,
      title: _requiredString(values, 'title'),
      contestName: _requiredString(values, 'contestName'),
      vacancy: _requiredString(values, 'vacancy'),
      proofVersion: _optionalString(values['proofVersion']),
      board: _optionalString(values['board']),
      year: _optionalInt(values['year']),
      sourceName: _optionalString(values['sourceName']),
      answerKeyName: _optionalString(values['answerKeyName']),
      createdAt: createdAt,
      updatedAt: _date(values['updatedAt'], fallback: createdAt),
    );
  }
}

abstract final class QuestionSyncMapper {
  static SyncRecord toRecord(Question question) {
    final options = question.alternatives
        .asMap()
        .entries
        .map((entry) {
          return {
            'id': String.fromCharCode(65 + entry.key),
            'text': entry.value,
          };
        })
        .toList(growable: false);
    return SyncRecord({
      'id': question.id,
      if (question.examId != null) 'examId': question.examId,
      if (question.number != null) 'order': question.number,
      'statement': question.statement,
      'options': options,
      'correctOption': String.fromCharCode(
        65 + question.correctAlternativeIndex,
      ),
      if (question.explanation.isNotEmpty) 'explanation': question.explanation,
      if (question.notes.isNotEmpty) 'notes': question.notes,
      if (question.exam.isNotEmpty) 'examName': question.exam,
      'subject': question.subject,
      'topic': question.topic,
      if (question.sourceName != null) 'sourceName': question.sourceName,
      if (question.sourcePage != null) 'sourcePage': question.sourcePage,
      if (question.visualImage != null) 'visualImage': question.visualImage,
      if (question.visualImages.isNotEmpty)
        'visualImages': question.visualImages,
      'createdAt': question.createdAt.toUtc().toIso8601String(),
      'updatedAt': question.updatedAt.toUtc().toIso8601String(),
    });
  }

  static Question fromRecord(SyncRecord record) {
    final values = record.values;
    final rawOptions = values['options'];
    if (rawOptions is! List || rawOptions.isEmpty) {
      throw const FormatException(
        'A questão sincronizada não possui alternativas.',
      );
    }
    final alternatives = <String>[];
    for (final rawOption in rawOptions) {
      if (rawOption is! Map || rawOption['text'] is! String) {
        throw const FormatException('Uma alternativa sincronizada é inválida.');
      }
      alternatives.add(rawOption['text'] as String);
    }
    final correctOption = _requiredString(
      values,
      'correctOption',
    ).toUpperCase();
    final correctIndex = correctOption.codeUnitAt(0) - 'A'.codeUnitAt(0);
    if (correctIndex < 0 || correctIndex >= alternatives.length) {
      throw const FormatException('O gabarito sincronizado é inválido.');
    }
    final createdAt = _date(values['createdAt']);
    return Question(
      id: record.id,
      number: _optionalInt(values['order']),
      statement: _requiredString(values, 'statement'),
      alternatives: List.unmodifiable(alternatives),
      correctAlternativeIndex: correctIndex,
      explanation: _optionalString(values['explanation']) ?? '',
      contest: _optionalString(values['contestName']) ?? '',
      role: _optionalString(values['vacancy']) ?? '',
      topic: _optionalString(values['topic']) ?? '',
      exam: _optionalString(values['examName']) ?? '',
      examId: _optionalString(values['examId']),
      subject: _optionalString(values['subject']) ?? '',
      notes: _optionalString(values['notes']) ?? '',
      sourceName: _optionalString(values['sourceName']),
      sourcePage: _optionalInt(values['sourcePage']),
      visualImage: _optionalString(values['visualImage']),
      visualImages: List.unmodifiable(
        (values['visualImages'] is List
                ? values['visualImages'] as List
                : const <Object?>[])
            .whereType<String>(),
      ),
      createdAt: createdAt,
      updatedAt: _date(values['updatedAt'], fallback: createdAt),
    );
  }
}

String _requiredString(SyncJson values, String key) {
  final value = values[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('O campo $key é obrigatório.');
  }
  return value;
}

String? _optionalString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value : null;
}

int? _optionalInt(Object? value) {
  return value is int ? value : int.tryParse('$value');
}

DateTime _date(Object? value, {DateTime? fallback}) {
  final parsed = value is String ? DateTime.tryParse(value) : null;
  return parsed ??
      fallback ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
