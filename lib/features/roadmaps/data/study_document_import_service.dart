import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../domain/study_document.dart';
import 'study_document_repository.dart';

class StudyDocumentImportService {
  const StudyDocumentImportService();

  Future<StudyDocument?> pickAndImport(
    StudyDocumentRepository repository,
  ) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'txt',
        'md',
        'csv',
        'png',
        'jpg',
        'jpeg',
        'webp',
      ],
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();

    final now = DateTime.now().toUtc();
    final id = 'document-${now.microsecondsSinceEpoch}';
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final storageDirectory = Directory(
      path.join(documentsDirectory.path, 'dunots', 'study_documents'),
    );
    await storageDirectory.create(recursive: true);

    final extension = picked.extension?.trim().toLowerCase();
    final safeExtension = extension == null || extension.isEmpty
        ? ''
        : '.$extension';
    final storedPath = path.join(storageDirectory.path, '$id$safeExtension');
    await File(storedPath).writeAsBytes(bytes, flush: true);

    final document = StudyDocument(
      id: id,
      title: path.basenameWithoutExtension(picked.name),
      fileName: picked.name,
      filePath: storedPath,
      mimeType: _mimeType(extension),
      byteSize: bytes.length,
      importedAt: now,
    );
    await repository.create(document);
    return document;
  }

  String _mimeType(String? extension) => switch (extension) {
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'md' => 'text/markdown',
    'csv' => 'text/csv',
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    _ => 'application/octet-stream',
  };
}
