import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

import '../domain/study_document.dart';

class StudyDocumentViewerPage extends StatelessWidget {
  final StudyDocument document;

  const StudyDocumentViewerPage({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      // Além da navegação do sistema, reserve espaço para a ação flutuante:
      // o fim de textos e documentos não pode ficar escondido atrás dela.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 88),
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).pop(true),
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Marcar como estudado'),
      ),
    );
  }

  Widget _buildBody() {
    if (document.mimeType == 'application/pdf') {
      return pdfx.PdfViewPinch(
        controller: pdfx.PdfControllerPinch(
          document: pdfx.PdfDocument.openFile(document.filePath),
        ),
      );
    }
    if (document.mimeType.startsWith('text/')) {
      return FutureBuilder<String>(
        future: File(document.filePath).readAsString(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Não foi possível abrir o texto.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: SelectableText(snapshot.data ?? ''),
          );
        },
      );
    }
    if (document.mimeType.startsWith('image/')) {
      return InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(child: Image.file(File(document.filePath))),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Este tipo de arquivo foi importado, mas ainda não possui uma prévia integrada.\n\n${document.fileName}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
