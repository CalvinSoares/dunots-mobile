import 'package:flutter_test/flutter_test.dart';

import 'package:dunots_mobile/features/flashcards/flashcard_demo_data.dart';

void main() {
  test('possui flashcards de demonstração', () {
    expect(demoFlashcards, isNotEmpty);
    expect(demoFlashcards.length, 2);
    expect(demoFlashcards.first.front, 'O que é independência de dados?');
  });
}
