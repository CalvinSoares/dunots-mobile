import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dunots_mobile/core/database/app_database.dart';
import 'package:dunots_mobile/core/sync/sync_contract.dart';
import 'package:dunots_mobile/core/sync/sync_database_repository.dart';
import 'package:dunots_mobile/features/challenges/data/sqlite_challenge_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('preserva histórico de revisões exportado pelo desktop', () async {
    final database = await AppDatabase.open(
      databasePathOverride: inMemoryDatabasePath,
    );
    addTearDown(database.close);
    final syncRepository = SyncDatabaseRepository(database.database);
    final json = jsonDecode(
      await File('test/fixtures/desktop_challenge_reviews_v1.dunots.json')
          .readAsString(),
    );
    final package = SyncPackage.fromJson(json);
    final preview = await syncRepository.preview(package);
    final result = await syncRepository.apply(
      preview,
      defaultResolution: SyncConflictResolution.useReceived,
    );
    final challengeRepository = SqliteChallengeRepository(database);
    final challenge = (await challengeRepository.getAll()).single;
    final history = await challengeRepository.getReviewHistory(challenge.id);

    expect(result.added, 4);
    expect(challenge.interval, 4);
    expect(challenge.easeFactor, 2.65);
    expect(history, hasLength(3));
    expect(history.map((review) => review.rating), ['again', 'easy', 'medium']);
    expect(history.first.nextInterval, 0);
    expect(history.last.nextInterval, 1);
  });
}
