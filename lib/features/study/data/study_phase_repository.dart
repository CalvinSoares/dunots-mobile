import '../domain/study_phase.dart';

abstract interface class StudyPhaseRepository {
  Future<List<StudyPhase>> getAll();
  Future<void> create(StudyPhase phase);
  Future<void> update(StudyPhase phase);
  Future<void> delete(String id);
  Future<void> reorder(List<String> orderedIds);
}

class InMemoryStudyPhaseRepository implements StudyPhaseRepository {
  final List<StudyPhase> _phases;

  InMemoryStudyPhaseRepository({List<StudyPhase>? phases})
    : _phases = List.of(phases ?? const []);

  @override
  Future<List<StudyPhase>> getAll() async => List.unmodifiable(
    [..._phases]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
  );

  @override
  Future<void> create(StudyPhase phase) async => _phases.add(phase);

  @override
  Future<void> update(StudyPhase phase) async {
    final index = _phases.indexWhere((item) => item.id == phase.id);
    if (index < 0) throw StateError('Fase de estudo não encontrada.');
    _phases[index] = phase;
  }

  @override
  Future<void> delete(String id) async =>
      _phases.removeWhere((phase) => phase.id == id);

  @override
  Future<void> reorder(List<String> orderedIds) async {
    final positions = {
      for (var index = 0; index < orderedIds.length; index++)
        orderedIds[index]: index,
    };
    for (var index = 0; index < _phases.length; index++) {
      final phase = _phases[index];
      final order = positions[phase.id];
      if (order != null) {
        _phases[index] = phase.copyWith(sortOrder: order);
      }
    }
  }
}
