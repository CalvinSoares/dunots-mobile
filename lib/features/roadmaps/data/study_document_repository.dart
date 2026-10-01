import '../domain/study_document.dart';

abstract interface class StudyDocumentRepository {
  Future<List<StudyDocument>> getAll();
  Future<void> create(StudyDocument document);
  Future<void> update(StudyDocument document);
  Future<void> delete(String id);
}

class InMemoryStudyDocumentRepository implements StudyDocumentRepository {
  final List<StudyDocument> _items;

  InMemoryStudyDocumentRepository({List<StudyDocument>? items})
    : _items = List.of(items ?? const []);

  @override
  Future<List<StudyDocument>> getAll() async => List.unmodifiable(_items);

  @override
  Future<void> create(StudyDocument document) async => _items.add(document);

  @override
  Future<void> update(StudyDocument document) async {
    final index = _items.indexWhere((item) => item.id == document.id);
    if (index < 0) throw StateError('Documento não encontrado.');
    _items[index] = document;
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((document) => document.id == id);
  }
}
