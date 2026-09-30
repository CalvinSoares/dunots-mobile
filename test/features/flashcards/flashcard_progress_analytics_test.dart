import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/models/flashcard_session_summary.dart';
import 'package:dunots_mobile/features/flashcards/flashcard_progress_analytics.dart';

void main() {
  test('calcula dias, semanas e comparativo do período', () {
    final reference = DateTime(2026, 9, 30, 18);
    final sessions = [
      _session('today', DateTime(2026, 9, 30), 8, 2, 4, 2),
      _session('monday', DateTime(2026, 9, 28), 4, 0, 2, 2),
      _session('previous', DateTime(2026, 9, 22), 10, 5, 3, 2),
    ];

    final report = buildFlashcardProgressReport(
      sessions,
      reference: reference,
      windowDays: 7,
    );

    expect(report.days, hasLength(7));
    expect(report.days.last.cards, 8);
    expect(report.currentWeek.cards, 12);
    expect(report.currentWeek.activeDays, 2);
    expect(report.previousWeek.cards, 10);
    expect(report.currentPeriod.cards, 12);
    expect(report.previousPeriod.cards, 10);
    expect(report.currentPeriod.changeFrom(report.previousPeriod), 0.2);
  });

  test('retorna comparação indeterminada quando não há período anterior', () {
    final current = FlashcardPeriodSummary(
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 8),
      cards: 4,
      sessions: 1,
      difficult: 0,
      good: 2,
      easy: 2,
      activeDays: 1,
    );
    final previous = FlashcardPeriodSummary(
      start: DateTime(2026, 8, 25),
      end: DateTime(2026, 9, 1),
      cards: 0,
      sessions: 0,
      difficult: 0,
      good: 0,
      easy: 0,
      activeDays: 0,
    );

    expect(current.changeFrom(previous), isNull);
  });
}

FlashcardSessionSummary _session(
  String id,
  DateTime finishedAt,
  int cards,
  int difficult,
  int good,
  int easy,
) {
  return FlashcardSessionSummary(
    id: id,
    startedAt: finishedAt.subtract(const Duration(minutes: 10)),
    finishedAt: finishedAt,
    cardCount: cards,
    difficultCount: difficult,
    goodCount: good,
    easyCount: easy,
  );
}
