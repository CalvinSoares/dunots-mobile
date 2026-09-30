import '../../../core/models/flashcard_review_preferences.dart';

abstract interface class FlashcardReviewPreferencesRepository {
  Future<FlashcardReviewPreferences> get();

  Future<void> save(FlashcardReviewPreferences preferences);
}

class InMemoryFlashcardReviewPreferencesRepository
    implements FlashcardReviewPreferencesRepository {
  FlashcardReviewPreferences _preferences;

  InMemoryFlashcardReviewPreferencesRepository({
    FlashcardReviewPreferences? preferences,
  }) : _preferences = preferences ?? const FlashcardReviewPreferences();

  @override
  Future<FlashcardReviewPreferences> get() async => _preferences;

  @override
  Future<void> save(FlashcardReviewPreferences preferences) async {
    _preferences = preferences;
  }
}
