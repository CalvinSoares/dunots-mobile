import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/features/questions/data/sqlite_question_repository.dart';
import 'package:dunots_mobile/features/questions/domain/question.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persiste questão e alternativas no SQLite', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SqliteQuestionRepository(appDatabase);
    final question = Question(
      id: 'question-sqlite',
      number: 23,
      statement: 'Qual topologia usa um concentrador central?',
      alternatives: const ['Anel', 'Estrela', 'Malha'],
      correctAlternativeIndex: 1,
      explanation: 'A estrela usa um ponto central.',
      contest: 'Transpetro',
      role: 'Análise de Sistemas',
      topic: 'Redes',
      exam: 'Prova 6',
      examId: 'exam-6',
      subject: 'Redes de Computadores',
      notes: 'Revisar subnetting.',
      sourceName: 'analise-de-sistema-infraestrutura.pdf',
      sourcePage: 39,
      visualImage: 'diagram-1',
      visualImages: const ['diagram-1', 'diagram-2'],
      createdAt: DateTime(2026, 9, 30),
    );

    await repository.create(question);
    final saved = (await repository.getAll()).single;

    expect(saved.id, question.id);
    expect(saved.number, question.number);
    expect(saved.alternatives, question.alternatives);
    expect(saved.correctAlternativeIndex, question.correctAlternativeIndex);
    expect(saved.topic, 'Redes');
    expect(saved.exam, 'Prova 6');
    expect(saved.examId, 'exam-6');
    expect(saved.subject, 'Redes de Computadores');
    expect(saved.notes, 'Revisar subnetting.');
    expect(saved.sourceName, 'analise-de-sistema-infraestrutura.pdf');
    expect(saved.sourcePage, 39);
    expect(saved.visualImage, 'diagram-1');
    expect(saved.visualImages, ['diagram-1', 'diagram-2']);
    expect(saved.createdAt, question.createdAt);
    expect(saved.updatedAt, question.updatedAt);

    await repository.update(question.copyWith(statement: 'Atualizada'));
    expect((await repository.getAll()).single.statement, 'Atualizada');

    await repository.delete(question.id);
    expect(await repository.getAll(), isEmpty);

    await appDatabase.close();
  });
}
