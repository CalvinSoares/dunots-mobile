import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/roadmaps/data/study_track_repository.dart';
import 'package:dunots_mobile/features/roadmaps/domain/study_track.dart';
import 'package:dunots_mobile/features/roadmaps/presentation/study_tracks_controller.dart';

class FailingStudyTrackRepository implements StudyTrackRepository {
  @override
  Future<List<StudyTrack>> getAll() {
    throw StateError('Falha simulada');
  }

  @override
  Future<void> create(StudyTrack track) {
    throw StateError('Falha simulada');
  }
}

void main() {
  test('carrega trilhas e entra no estado de dados', () async {
    final controller = StudyTracksController(
      repository: InMemoryStudyTrackRepository(),
    );

    await controller.load();

    expect(controller.state.status, StudyTracksStatus.data);
    expect(controller.state.tracks, hasLength(2));
    expect(controller.state.tracks.first.title, 'Análise de Sistemas');

    controller.dispose();
  });

  test(
    'entra no estado vazio quando o repositorio não possui trilhas',
    () async {
      final controller = StudyTracksController(
        repository: InMemoryStudyTrackRepository(tracks: const []),
      );

      await controller.load();

      expect(controller.state.status, StudyTracksStatus.empty);
      expect(controller.state.tracks, isEmpty);

      controller.dispose();
    },
  );

  test('entra no estado de erro quando o repositorio falha', () async {
    final controller = StudyTracksController(
      repository: FailingStudyTrackRepository(),
    );

    await controller.load();

    expect(controller.state.status, StudyTracksStatus.error);
    expect(controller.state.errorMessage, isNotNull);

    controller.dispose();
  });

  test('cria uma trilha e atualiza a lista', () async {
    final controller = StudyTracksController(
      repository: InMemoryStudyTrackRepository(tracks: const []),
    );

    await controller.load();
    await controller.createTrack(
      title: 'Redes de Computadores',
      description: 'Trilha de fundamentos de redes.',
    );

    expect(controller.state.status, StudyTracksStatus.data);
    expect(controller.state.tracks, hasLength(1));
    expect(controller.state.tracks.single.title, 'Redes de Computadores');
    expect(
      controller.state.tracks.single.description,
      'Trilha de fundamentos de redes.',
    );

    controller.dispose();
  });

  test('não cria uma trilha sem título', () async {
    final controller = StudyTracksController(
      repository: InMemoryStudyTrackRepository(tracks: const []),
    );

    expect(
      () => controller.createTrack(title: '  ', description: ''),
      throwsArgumentError,
    );

    controller.dispose();
  });
}
