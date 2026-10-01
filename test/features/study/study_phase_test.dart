import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/models/flashcard.dart';
import 'package:dunots_mobile/features/challenges/domain/challenge.dart';
import 'package:dunots_mobile/features/study/data/study_phase_repository.dart';
import 'package:dunots_mobile/features/study/data/sqlite_study_phase_repository.dart';
import 'package:dunots_mobile/features/study/domain/study_phase.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final now = DateTime(2026, 9, 30);

  test('calcula progresso a partir dos itens associados', () {
    final phase = StudyPhase(
      id: 'phase-1',
      title: 'Redes',
      flashcardIds: const ['card-done', 'card-pending'],
      challengeIds: const ['challenge-done'],
      createdAt: now,
      updatedAt: now,
    );
    final cards = [
      Flashcard(
        id: 'card-done',
        front: 'VLAN',
        back: 'Rede lógica',
        createdAt: now,
        lastReviewedAt: now,
      ),
      Flashcard(
        id: 'card-pending',
        front: 'OSI',
        back: '7 camadas',
        createdAt: now,
      ),
    ];
    final challenges = [
      Challenge(
        id: 'challenge-done',
        title: 'Two Sum',
        solvedAt: now,
        createdAt: now,
      ),
    ];

    expect(phase.totalItems, 3);
    expect(phase.completedItems(flashcards: cards, challenges: challenges), 2);
    expect(
      phase.progress(flashcards: cards, challenges: challenges),
      closeTo(2 / 3, 0.001),
    );
  });

  test('reordena fases sem perder seus dados', () async {
    final repository = InMemoryStudyPhaseRepository(
      phases: [
        StudyPhase(
          id: 'a',
          title: 'A',
          sortOrder: 0,
          createdAt: now,
          updatedAt: now,
        ),
        StudyPhase(
          id: 'b',
          title: 'B',
          sortOrder: 1,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    await repository.reorder(['b', 'a']);
    final phases = await repository.getAll();

    expect(phases.map((phase) => phase.id), ['b', 'a']);
    expect(phases.map((phase) => phase.sortOrder), [0, 1]);
  });

  test('persiste fase, vínculos e ordem no SQLite', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final repository = SqliteStudyPhaseRepository(database);
    final phase = StudyPhase(
      id: 'sqlite-phase',
      title: 'Banco de dados',
      description: 'Revisão de SQL',
      flashcardIds: const ['card-1'],
      challengeIds: const ['challenge-1'],
      sortOrder: 4,
      createdAt: now,
      updatedAt: now,
    );

    await repository.create(phase);
    final saved = (await repository.getAll()).single;

    expect(saved.title, phase.title);
    expect(saved.flashcardIds, ['card-1']);
    expect(saved.challengeIds, ['challenge-1']);
    expect(saved.sortOrder, 4);
    await database.close();
  });
}
