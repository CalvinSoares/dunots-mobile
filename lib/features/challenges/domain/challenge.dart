enum ChallengeDifficulty { easy, medium, hard }

class Challenge {
  final String id;
  final String title;
  final String problemId;
  final String variantName;
  final String strategy;
  final String url;
  final ChallengeDifficulty difficulty;
  final List<String> tags;
  final String complexity;
  final String timeComplexity;
  final String spaceComplexity;
  final String tradeoffs;
  final List<String> diagramIds;
  final String solution;
  final String notes;
  final DateTime? solvedAt;
  final DateTime? dueAt;
  final int interval;
  final double easeFactor;
  final int repetitions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Challenge({
    required this.id,
    required this.title,
    this.problemId = '',
    this.variantName = '',
    this.strategy = '',
    this.url = '',
    this.difficulty = ChallengeDifficulty.medium,
    this.tags = const [],
    this.complexity = '',
    this.timeComplexity = '',
    this.spaceComplexity = '',
    this.tradeoffs = '',
    this.diagramIds = const [],
    this.solution = '',
    this.notes = '',
    this.solvedAt,
    this.dueAt,
    this.interval = 0,
    this.easeFactor = 2.5,
    this.repetitions = 0,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  Challenge copyWith({
    String? title,
    String? problemId,
    String? variantName,
    String? strategy,
    String? url,
    ChallengeDifficulty? difficulty,
    List<String>? tags,
    String? complexity,
    String? timeComplexity,
    String? spaceComplexity,
    String? tradeoffs,
    List<String>? diagramIds,
    String? solution,
    String? notes,
    DateTime? solvedAt,
    DateTime? dueAt,
    int? interval,
    double? easeFactor,
    int? repetitions,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id,
      title: title ?? this.title,
      problemId: problemId ?? this.problemId,
      variantName: variantName ?? this.variantName,
      strategy: strategy ?? this.strategy,
      url: url ?? this.url,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      complexity: complexity ?? this.complexity,
      timeComplexity: timeComplexity ?? this.timeComplexity,
      spaceComplexity: spaceComplexity ?? this.spaceComplexity,
      tradeoffs: tradeoffs ?? this.tradeoffs,
      diagramIds: diagramIds ?? this.diagramIds,
      solution: solution ?? this.solution,
      notes: notes ?? this.notes,
      solvedAt: solvedAt ?? this.solvedAt,
      dueAt: dueAt ?? this.dueAt,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      repetitions: repetitions ?? this.repetitions,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isDueAt(DateTime now) => dueAt == null || !dueAt!.isAfter(now);
}
