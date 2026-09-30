import '../domain/study_diagram.dart';

abstract interface class DiagramRepository {
  Future<List<StudyDiagram>> getAll();
  Future<void> create(StudyDiagram diagram);
  Future<void> update(StudyDiagram diagram);
  Future<void> delete(String id);
}

class InMemoryDiagramRepository implements DiagramRepository {
  final List<StudyDiagram> _items;
  InMemoryDiagramRepository({List<StudyDiagram>? items})
    : _items = List.of(items ?? const []);
  @override
  Future<List<StudyDiagram>> getAll() async => List.unmodifiable(_items);
  @override
  Future<void> create(StudyDiagram diagram) async => _items.add(diagram);
  @override
  Future<void> update(StudyDiagram diagram) async {
    final i = _items.indexWhere((item) => item.id == diagram.id);
    if (i < 0) throw StateError('Fluxograma não encontrado.');
    _items[i] = diagram;
  }

  @override
  Future<void> delete(String id) async =>
      _items.removeWhere((item) => item.id == id);
}
