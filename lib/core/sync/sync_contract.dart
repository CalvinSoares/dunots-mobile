typedef SyncJson = Map<String, dynamic>;

/// Coleções estáveis do contrato `dunots-sync` v1.
abstract final class SyncCollections {
  static const all = <String>[
    flashcards,
    leetcodeProblems,
    challengeReviews,
    articles,
    snippets,
    studyPhases,
    diagrams,
    quizExams,
    quizQuestions,
    quizAttempts,
    studyRoadmaps,
    roadmapNodes,
    roadmapLinks,
    syncTombstones,
  ];

  static const flashcards = 'flashcards';
  static const leetcodeProblems = 'leetcode_problems';
  static const challengeReviews = 'challenge_reviews';
  static const articles = 'articles';
  static const snippets = 'snippets';
  static const studyPhases = 'study_phases';
  static const diagrams = 'diagrams';
  static const quizExams = 'quiz_exams';
  static const quizQuestions = 'quiz_questions';
  static const quizAttempts = 'quiz_attempts';
  static const studyRoadmaps = 'study_roadmaps';
  static const roadmapNodes = 'roadmap_nodes';
  static const roadmapLinks = 'roadmap_links';
  static const syncTombstones = 'sync_tombstones';
}

class SyncIdentity {
  final String deviceId;
  final String deviceName;

  const SyncIdentity({required this.deviceId, required this.deviceName});

  factory SyncIdentity.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException(
        'A origem do pacote de sincronização é inválida.',
      );
    }

    final json = Map<String, dynamic>.from(value);
    final deviceId = json['deviceId'];
    final deviceName = json['deviceName'];
    if (deviceId is! String ||
        deviceId.isEmpty ||
        deviceName is! String ||
        deviceName.isEmpty) {
      throw const FormatException('A identidade do dispositivo é inválida.');
    }

    return SyncIdentity(deviceId: deviceId, deviceName: deviceName);
  }

  SyncJson toJson() => {'deviceId': deviceId, 'deviceName': deviceName};
}

/// Registro genérico do contrato. Os campos específicos permanecem extensíveis
/// para que uma plataforma não perca dados que ainda não existem na outra.
class SyncRecord {
  final SyncJson values;

  SyncRecord(SyncJson values) : values = Map<String, dynamic>.from(values);

  String get id => values['id'] as String;

  SyncJson toJson() => Map<String, dynamic>.from(values);
}

class SyncPackage {
  static const format = 'dunots-sync';
  static const version = 1;

  final DateTime exportedAt;
  final SyncIdentity source;
  final Map<String, List<SyncRecord>> collections;

  SyncPackage({
    required this.exportedAt,
    required this.source,
    required Map<String, List<SyncRecord>> collections,
  }) : collections = _copyCollections(collections);

  factory SyncPackage.empty({
    required DateTime exportedAt,
    required SyncIdentity source,
  }) {
    return SyncPackage(
      exportedAt: exportedAt,
      source: source,
      collections: {
        for (final collection in SyncCollections.all)
          collection: <SyncRecord>[],
      },
    );
  }

  factory SyncPackage.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('O arquivo não contém um pacote válido.');
    }

    final json = Map<String, dynamic>.from(value);
    if (json['format'] != format || json['version'] != version) {
      throw const FormatException(
        'Este arquivo não é um pacote de sincronização Dunots compatível.',
      );
    }

    final exportedAtValue = json['exportedAt'];
    final collectionsValue = json['collections'];
    if (exportedAtValue is! String || collectionsValue is! Map) {
      throw const FormatException('O pacote de sincronização está incompleto.');
    }

    final exportedAt = DateTime.tryParse(exportedAtValue);
    if (exportedAt == null) {
      throw const FormatException('A data de exportação do pacote é inválida.');
    }

    final rawCollections = Map<String, dynamic>.from(collectionsValue);
    final collections = <String, List<SyncRecord>>{
      for (final collection in SyncCollections.all) collection: <SyncRecord>[],
    };

    for (final collection in SyncCollections.all) {
      final rawRecords = rawCollections[collection];
      if (rawRecords == null) continue;
      if (rawRecords is! List) {
        throw FormatException('A coleção $collection está inválida.');
      }

      collections[collection] = rawRecords
          .whereType<Map>()
          .map((record) => Map<String, dynamic>.from(record))
          .where(
            (record) =>
                record['id'] is String && (record['id'] as String).isNotEmpty,
          )
          .map(SyncRecord.new)
          .toList(growable: false);
    }

    return SyncPackage(
      exportedAt: exportedAt,
      source: SyncIdentity.fromJson(json['source']),
      collections: collections,
    );
  }

  List<SyncRecord> recordsFor(String collection) {
    return List.unmodifiable(collections[collection] ?? const <SyncRecord>[]);
  }

  SyncJson toJson() => {
    'format': format,
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'source': source.toJson(),
    'collections': {
      for (final collection in SyncCollections.all)
        collection: (collections[collection] ?? const <SyncRecord>[])
            .map((record) => record.toJson())
            .toList(growable: false),
    },
  };

  static Map<String, List<SyncRecord>> _copyCollections(
    Map<String, List<SyncRecord>> source,
  ) {
    return {
      for (final collection in SyncCollections.all)
        collection: List.unmodifiable(
          source[collection] ?? const <SyncRecord>[],
        ),
    };
  }
}
