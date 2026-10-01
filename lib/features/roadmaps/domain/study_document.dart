class StudyDocument {
  final String id;
  final String title;
  final String description;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int byteSize;
  final DateTime importedAt;
  final DateTime updatedAt;

  const StudyDocument({
    required this.id,
    required this.title,
    this.description = '',
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.byteSize,
    required this.importedAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? importedAt;

  String get subtitle {
    final size = byteSize < 1024
        ? '$byteSize B'
        : byteSize < 1024 * 1024
        ? '${(byteSize / 1024).toStringAsFixed(1)} KB'
        : '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return 'Documento · $size';
  }

  StudyDocument copyWith({
    String? title,
    String? description,
    String? fileName,
    String? filePath,
    String? mimeType,
    int? byteSize,
    DateTime? updatedAt,
  }) {
    return StudyDocument(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      importedAt: importedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
