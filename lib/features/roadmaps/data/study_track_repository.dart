import '../domain/study_track.dart';

abstract interface class StudyTrackRepository {
  Future<List<StudyTrack>> getAll();

  Future<void> create(StudyTrack track);

  Future<void> update(StudyTrack track);

  Future<void> delete(String id);
}

class InMemoryStudyTrackRepository implements StudyTrackRepository {
  final List<StudyTrack> _tracks;

  InMemoryStudyTrackRepository({List<StudyTrack>? tracks})
    : _tracks = List.of(
        tracks ??
            const [
              StudyTrack(
                id: 'track-001',
                title: 'Análise de Sistemas',
                description: 'Fundamentos para provas de TI.',
                completedItems: 12,
                totalItems: 38,
              ),
              StudyTrack(
                id: 'track-002',
                title: 'Infraestrutura de Redes',
                description: 'Redes, protocolos e segurança.',
                completedItems: 5,
                totalItems: 24,
              ),
            ],
      );

  @override
  Future<List<StudyTrack>> getAll() async {
    return List.unmodifiable(_tracks);
  }

  @override
  Future<void> create(StudyTrack track) async {
    _tracks.add(track);
  }

  @override
  Future<void> update(StudyTrack track) async {
    final index = _tracks.indexWhere((item) => item.id == track.id);

    if (index == -1) {
      throw StateError('Trilha não encontrada.');
    }

    _tracks[index] = track;
  }

  @override
  Future<void> delete(String id) async {
    _tracks.removeWhere((track) => track.id == id);
  }
}
