class Flashcard {
  final String id;
  final String front;
  final String back;
  final DateTime createdAt;

  const Flashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.createdAt,
  });
}
