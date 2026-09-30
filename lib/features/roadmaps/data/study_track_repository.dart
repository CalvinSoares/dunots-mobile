import '../domain/study_track.dart';

abstract interface class StudyTrackRepository {
  Future<List<StudyTrack>> getAll();

  Future<void> create(StudyTrack track);
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
}
