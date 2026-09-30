import 'package:flutter/foundation.dart';

import '../data/study_track_repository.dart';
import '../domain/study_track.dart';

enum StudyTracksStatus { initial, loading, data, empty, error }

class StudyTracksState {
  final StudyTracksStatus status;
  final List<StudyTrack> tracks;
  final String? errorMessage;

  const StudyTracksState({
    this.status = StudyTracksStatus.initial,
    this.tracks = const [],
    this.errorMessage,
  });

  StudyTracksState copyWith({
    StudyTracksStatus? status,
    List<StudyTrack>? tracks,
    String? errorMessage,
  }) {
    return StudyTracksState(
      status: status ?? this.status,
      tracks: tracks ?? this.tracks,
      errorMessage: errorMessage,
    );
  }
}

class StudyTracksController extends ChangeNotifier {
  final StudyTrackRepository repository;

  StudyTracksState _state = const StudyTracksState();

  StudyTracksController({required this.repository});

  StudyTracksState get state => _state;

  Future<void> load() async {
    _state = _state.copyWith(
      status: StudyTracksStatus.loading,
      errorMessage: null,
    );
    notifyListeners();

    try {
      final tracks = await repository.getAll();

      _state = _state.copyWith(
        status: tracks.isEmpty
            ? StudyTracksStatus.empty
            : StudyTracksStatus.data,
        tracks: tracks,
        errorMessage: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        status: StudyTracksStatus.error,
        errorMessage: 'Não foi possível carregar as trilhas.',
      );
    }

    notifyListeners();
  }
}
