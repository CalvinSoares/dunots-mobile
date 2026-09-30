import '../../../core/models/flashcard_session_summary.dart';

abstract interface class FlashcardSessionRepository {
  Future<void> create(FlashcardSessionSummary summary);

  Future<List<FlashcardSessionSummary>> getForDay(DateTime day);

  Future<List<FlashcardSessionSummary>> getRecent({int days = 7});
}

class InMemoryFlashcardSessionRepository implements FlashcardSessionRepository {
  final List<FlashcardSessionSummary> _sessions;

  InMemoryFlashcardSessionRepository({List<FlashcardSessionSummary>? sessions})
    : _sessions = List.of(sessions ?? const []);

  @override
  Future<void> create(FlashcardSessionSummary summary) async {
    _sessions.add(summary);
  }

  @override
  Future<List<FlashcardSessionSummary>> getForDay(DateTime day) async {
    return List.unmodifiable(
      _sessions.where((summary) => _isSameDay(summary.finishedAt, day)),
    );
  }

  @override
  Future<List<FlashcardSessionSummary>> getRecent({int days = 7}) async {
    final today = DateTime.now();
    final start = DateTime(
      today.year,
      today.month,
      today.day,
    ).subtract(Duration(days: days - 1));
    final end = start.add(Duration(days: days));
    final sessions = _sessions
        .where(
          (summary) =>
              !summary.finishedAt.isBefore(start) &&
              summary.finishedAt.isBefore(end),
        )
        .toList();
    sessions.sort(
      (first, second) => second.finishedAt.compareTo(first.finishedAt),
    );
    return List.unmodifiable(sessions);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}
