import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/core/srs/srs_scheduler.dart';

void main() {
  test('mantém os casos de SRS exportados do algoritmo desktop', () async {
    final cases = jsonDecode(
      await File('test/fixtures/desktop_challenge_srs_cases.json')
          .readAsString(),
    ) as List<dynamic>;

    for (final rawCase in cases.cast<Map<String, dynamic>>()) {
      final reviewedAt = DateTime.parse(rawCase['reviewedAt'] as String);
      final schedule = SrsScheduler.next(
        rating: rawCase['rating'] as String,
        reviewedAt: reviewedAt,
        interval: rawCase['interval'] as int,
        easeFactor: (rawCase['easeFactor'] as num).toDouble(),
        repetitions: rawCase['repetitions'] as int,
      );

      expect(
        schedule.interval,
        rawCase['nextInterval'],
        reason: rawCase['name'] as String,
      );
      expect(
        schedule.repetitions,
        rawCase['nextRepetitions'],
        reason: rawCase['name'] as String,
      );
      expect(
        schedule.easeFactor,
        rawCase['nextEaseFactor'],
        reason: rawCase['name'] as String,
      );
      expect(
        schedule.dueAt,
        DateTime.parse(rawCase['dueAt'] as String),
        reason: rawCase['name'] as String,
      );
    }
  });

  test('normaliza os rótulos exibidos pelo mobile para o contrato desktop', () {
    expect(SrsScheduler.normalizeRating('novamente'), 'again');
    expect(SrsScheduler.normalizeRating('difícil'), 'hard');
    expect(SrsScheduler.normalizeRating('bom'), 'medium');
    expect(SrsScheduler.normalizeRating('fácil'), 'easy');
  });
}
