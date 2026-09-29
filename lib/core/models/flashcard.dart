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

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    DateTime? createdAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
