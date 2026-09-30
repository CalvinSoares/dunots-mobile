import '../domain/challenge.dart';

abstract interface class ChallengeRepository {
  Future<List<Challenge>> getAll();
  Future<void> create(Challenge challenge);
  Future<void> update(Challenge challenge);
  Future<void> delete(String id);
}

class InMemoryChallengeRepository implements ChallengeRepository {
  final List<Challenge> _items;

  InMemoryChallengeRepository({List<Challenge>? items})
    : _items = List.of(items ?? const []);

  @override
  Future<List<Challenge>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> create(Challenge challenge) async => _items.add(challenge);

  @override
  Future<void> update(Challenge challenge) async {
    final index = _items.indexWhere((item) => item.id == challenge.id);
    if (index < 0) throw StateError('Desafio não encontrado.');
    _items[index] = challenge;
  }

  @override
  Future<void> delete(String id) async =>
      _items.removeWhere((item) => item.id == id);
}
