import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_node_material_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_document_repository.dart';
import 'package:dunots_mobile/features/roadmaps/data/sqlite_study_material_progress_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_node.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_material.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_document.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_nodes_controller.dart';

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
    final linkRepository = SqliteStudyNodeMaterialRepository(appDatabase);

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
    expect(savedNodes.last.status, StudyNodeStatus.completed);

    const link = StudyMaterialLink(
      nodeId: 'node-root',
      materialId: 'card-001',
      materialType: StudyMaterialType.flashcard,
    );
    await linkRepository.replaceForNode(root.id, const [link]);
    expect(await linkRepository.getForNode(root.id), [link]);

    await trackRepository.delete(track.id);

    expect(await trackRepository.getAll(), isEmpty);
    expect(await nodeRepository.getForTrack(track.id), isEmpty);
    expect(await linkRepository.getForNode(root.id), isEmpty);

    await appDatabase.close();
  });

  test('persiste documentos reais e progresso dos materiais', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final documentRepository = SqliteStudyDocumentRepository(appDatabase);
    final progressRepository = SqliteStudyMaterialProgressRepository(
      appDatabase,
    );
    final trackRepository = SqliteStudyTrackRepository(appDatabase);
    final nodeRepository = SqliteStudyNodeRepository(appDatabase);
    await trackRepository.create(
      const StudyTrack(
        id: 'track-progress',
        title: 'Trilha',
        description: '',
        completedItems: 0,
        totalItems: 1,
      ),
    );
    await nodeRepository.create(
      const StudyNode(
        id: 'node-progress',
        trackId: 'track-progress',
        parentId: null,
        title: 'Documentos',
        description: '',
        sortOrder: 0,
      ),
    );

    final importedAt = DateTime.utc(2026, 10, 1, 12);
    final document = StudyDocument(
      id: 'document-sqlite',
      title: 'Apostila de redes',
      description: 'Material importado.',
      fileName: 'redes.pdf',
      filePath: '/app/dunots/redes.pdf',
      mimeType: 'application/pdf',
      byteSize: 4096,
      importedAt: importedAt,
    );
    await documentRepository.create(document);
    expect((await documentRepository.getAll()).single.fileName, 'redes.pdf');

    const link = StudyMaterialLink(
      nodeId: 'node-progress',
      materialId: 'document-sqlite',
      materialType: StudyMaterialType.document,
    );
    expect(await progressRepository.isCompleted(link), isFalse);
    await progressRepository.markCompleted(link, completedAt: importedAt);
    expect(await progressRepository.isCompleted(link), isTrue);
    expect(
      (await progressRepository.getForNode('node-progress')).single.completedAt,
      importedAt,
    );

    await appDatabase.close();
  });

  test('promove subtópicos antes da exclusão em cascata do SQLite', () async {
    final appDatabase = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    final trackRepository = SqliteStudyTrackRepository(appDatabase);
    final nodeRepository = SqliteStudyNodeRepository(appDatabase);
    const track = StudyTrack(
      id: 'track-promote',
      title: 'Trilha',
      description: '',
      completedItems: 0,
      totalItems: 2,
    );
    await trackRepository.create(track);
    await nodeRepository.create(
      const StudyNode(
        id: 'node-parent',
        trackId: 'track-promote',
        parentId: null,
        title: 'Grupo',
        description: '',
        sortOrder: 0,
      ),
    );
    await nodeRepository.create(
      const StudyNode(
        id: 'node-to-delete',
        trackId: 'track-promote',
        parentId: 'node-parent',
        title: 'Tópico intermediário',
        description: '',
        sortOrder: 0,
      ),
    );
    await nodeRepository.create(
      const StudyNode(
        id: 'node-to-promote',
        trackId: 'track-promote',
        parentId: 'node-to-delete',
        title: 'Subtópico preservado',
        description: '',
        sortOrder: 0,
      ),
    );

    final controller = StudyNodesController(
      trackId: track.id,
      repository: nodeRepository,
    );
    await controller.load();
    await controller.deleteNode('node-to-delete', preserveChildren: true);

    final nodes = await nodeRepository.getForTrack(track.id);
    expect(
      nodes.map((node) => node.id),
      containsAll(<String>['node-parent', 'node-to-promote']),
    );
    expect(nodes.any((node) => node.id == 'node-to-delete'), isFalse);
    expect(
      nodes.firstWhere((node) => node.id == 'node-to-promote').parentId,
      'node-parent',
    );

    await appDatabase.close();
  });
}
