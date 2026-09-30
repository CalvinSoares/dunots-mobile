import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('persiste trilha, hierarquia e exclusão em cascata', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final trackRepository = SqliteStudyTrackRepository(appDatabase);
    final nodeRepository = SqliteStudyNodeRepository(appDatabase);

    const track = StudyTrack(
      id: 'track-sqlite',
      title: 'Trilha persistente',
      description: 'Teste SQLite.',
      completedItems: 2,
      totalItems: 5,
    );
    const root = StudyNode(
      id: 'node-root',
      trackId: 'track-sqlite',
      parentId: null,
      title: 'Redes',
      description: '',
      sortOrder: 0,
      notes: 'Revisar protocolos.',
      priority: StudyPriority.high,
    );
    const child = StudyNode(
      id: 'node-child',
      trackId: 'track-sqlite',
      parentId: 'node-root',
      title: 'Topologias',
      description: '',
      sortOrder: 0,
      isCompleted: true,
    );

    await trackRepository.create(track);
    await nodeRepository.create(root);
    await nodeRepository.create(child);

    expect((await trackRepository.getAll()).single.title, track.title);
    final savedNodes = await nodeRepository.getForTrack(track.id);
    expect(savedNodes, hasLength(2));
    expect(savedNodes.first.notes, 'Revisar protocolos.');
    expect(savedNodes.first.priority, StudyPriority.high);
    expect(savedNodes.last.isCompleted, isTrue);

    await trackRepository.delete(track.id);

    expect(await trackRepository.getAll(), isEmpty);
    expect(await nodeRepository.getForTrack(track.id), isEmpty);

    await appDatabase.close();
  });
}
