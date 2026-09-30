class FlashcardReviewPreferences {
  final int dailyLimit;
  final int dailyGoal;
  final String sort;
  final bool preferRecommended;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;

  const FlashcardReviewPreferences({
    this.dailyLimit = 20,
    this.dailyGoal = 20,
    this.sort = 'due',
    this.preferRecommended = false,
    this.reminderEnabled = true,
    this.reminderHour = 0,
    this.reminderMinute = 0,
  });

  FlashcardReviewPreferences copyWith({
    int? dailyLimit,
    int? dailyGoal,
    String? sort,
    bool? preferRecommended,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) {
    return FlashcardReviewPreferences(
      dailyLimit: dailyLimit ?? this.dailyLimit,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      sort: sort ?? this.sort,
      preferRecommended: preferRecommended ?? this.preferRecommended,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
    );
  }
}
