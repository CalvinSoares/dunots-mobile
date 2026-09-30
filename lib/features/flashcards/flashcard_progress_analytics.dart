import '../../core/models/flashcard_session_summary.dart';

class FlashcardDaySummary {
  final DateTime day;
  final int cards;
  final int sessions;
  final int difficult;
  final int good;
  final int easy;

  const FlashcardDaySummary({
    required this.day,
    required this.cards,
    required this.sessions,
    required this.difficult,
    required this.good,
    required this.easy,
  });

  int get answered => difficult + good + easy;

  double get retentionRate => answered == 0 ? 0 : (good + easy) / answered;
}

class FlashcardPeriodSummary {
  final DateTime start;
  final DateTime end;
  final int cards;
  final int sessions;
  final int difficult;
  final int good;
  final int easy;
  final int activeDays;

  const FlashcardPeriodSummary({
    required this.start,
    required this.end,
    required this.cards,
    required this.sessions,
    required this.difficult,
    required this.good,
    required this.easy,
    required this.activeDays,
  });

  int get answered => difficult + good + easy;

  double get averagePerSession => sessions == 0 ? 0 : cards / sessions;

  double get retentionRate => answered == 0 ? 0 : (good + easy) / answered;

  double? changeFrom(FlashcardPeriodSummary previous) {
    if (previous.cards == 0) return cards == 0 ? 0 : null;
    return (cards - previous.cards) / previous.cards;
  }
}

class FlashcardWeekSummary extends FlashcardPeriodSummary {
  const FlashcardWeekSummary({
    required super.start,
    required super.end,
    required super.cards,
    required super.sessions,
    required super.difficult,
    required super.good,
    required super.easy,
    required super.activeDays,
  });
}

class FlashcardProgressReport {
  final List<FlashcardDaySummary> days;
  final List<FlashcardWeekSummary> weeks;
  final FlashcardPeriodSummary currentPeriod;
  final FlashcardPeriodSummary previousPeriod;
  final FlashcardWeekSummary currentWeek;
  final FlashcardWeekSummary previousWeek;

  const FlashcardProgressReport({
    required this.days,
    required this.weeks,
    required this.currentPeriod,
    required this.previousPeriod,
    required this.currentWeek,
    required this.previousWeek,
  });
}

FlashcardProgressReport buildFlashcardProgressReport(
  List<FlashcardSessionSummary> sessions, {
  required DateTime reference,
  required int windowDays,
}) {
  final today = _day(reference);
  final currentEnd = today.add(const Duration(days: 1));
  final currentStart = today.subtract(Duration(days: windowDays - 1));
  final previousStart = currentStart.subtract(Duration(days: windowDays));

  final days = List<FlashcardDaySummary>.generate(windowDays, (index) {
    final day = currentStart.add(Duration(days: index));
    return _daySummary(sessions, day);
  });

  final currentWeekStart = _startOfWeek(today);
  final currentWeek = _weekSummary(sessions, currentWeekStart);
  final previousWeek = _weekSummary(
    sessions,
    currentWeekStart.subtract(const Duration(days: 7)),
  );
  final weeks = List<FlashcardWeekSummary>.generate(4, (index) {
    final start = currentWeekStart.subtract(Duration(days: (3 - index) * 7));
    return _weekSummary(sessions, start);
  });

  return FlashcardProgressReport(
    days: days,
    weeks: weeks,
    currentPeriod: _periodSummary(sessions, currentStart, currentEnd),
    previousPeriod: _periodSummary(sessions, previousStart, currentStart),
    currentWeek: currentWeek,
    previousWeek: previousWeek,
  );
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime _startOfWeek(DateTime value) {
  final day = _day(value);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

FlashcardDaySummary _daySummary(
  List<FlashcardSessionSummary> sessions,
  DateTime day,
) {
  final daySessions = sessions.where((session) {
    final finished = _day(session.finishedAt);
    return finished == day;
  });
  return FlashcardDaySummary(
    day: day,
    cards: daySessions.fold(0, (sum, session) => sum + session.cardCount),
    sessions: daySessions.length,
    difficult: daySessions.fold(
      0,
      (sum, session) => sum + session.difficultCount,
    ),
    good: daySessions.fold(0, (sum, session) => sum + session.goodCount),
    easy: daySessions.fold(0, (sum, session) => sum + session.easyCount),
  );
}

FlashcardWeekSummary _weekSummary(
  List<FlashcardSessionSummary> sessions,
  DateTime start,
) {
  final end = start.add(const Duration(days: 7));
  final period = _periodSummary(sessions, start, end);
  return FlashcardWeekSummary(
    start: period.start,
    end: period.end,
    cards: period.cards,
    sessions: period.sessions,
    difficult: period.difficult,
    good: period.good,
    easy: period.easy,
    activeDays: period.activeDays,
  );
}

FlashcardPeriodSummary _periodSummary(
  List<FlashcardSessionSummary> sessions,
  DateTime start,
  DateTime end,
) {
  final selected = sessions.where(
    (session) =>
        !session.finishedAt.isBefore(start) && session.finishedAt.isBefore(end),
  );
  final activeDays = selected
      .map((session) => _day(session.finishedAt))
      .toSet();
  return FlashcardPeriodSummary(
    start: start,
    end: end,
    cards: selected.fold(0, (sum, session) => sum + session.cardCount),
    sessions: selected.length,
    difficult: selected.fold(0, (sum, session) => sum + session.difficultCount),
    good: selected.fold(0, (sum, session) => sum + session.goodCount),
    easy: selected.fold(0, (sum, session) => sum + session.easyCount),
    activeDays: activeDays.length,
  );
}
