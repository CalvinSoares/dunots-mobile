import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'sync_database_repository.dart';

class SyncDialog extends StatefulWidget {
  final SyncDatabaseRepository repository;

  const SyncDialog({super.key, required this.repository});

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  SyncMergePreview? preview;
  bool busy = false;
  String? message;
  bool success = false;

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.sync),
          SizedBox(width: 10),
          Text('Sincronizar dados'),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: tabs,
              tabs: const [
                Tab(text: 'Exportar'),
                Tab(text: 'Importar'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 410,
              child: TabBarView(
                controller: tabs,
                children: [_buildExportTab(), _buildImportTab()],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildExportTab() {
    return ListView(
      children: [
        const _SyncInfoCard(
          icon: Icons.upload_file_outlined,
          title: 'Levar seus dados para outro dispositivo',
          detail: 'Gere um pacote .dunots com flashcards, provas, questões, simulados e trilhas disponíveis neste mobile.',
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy ? null : _export,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt),
          label: Text(busy ? 'Gerando pacote...' : 'Exportar pacote .dunots'),
        ),
        if (message != null && tabs.index == 0) ...[
          const SizedBox(height: 14),
          _SyncStatus(message: message!, success: success),
        ],
      ],
    );
  }

  Widget _buildImportTab() {
    final currentPreview = preview;
    return ListView(
      children: [
        const _SyncInfoCard(
          icon: Icons.download_outlined,
          title: 'Mesclar um pacote recebido',
          detail: 'Escolha um arquivo .dunots. O Dunots mostra o que será adicionado, removido ou colocado em conflito antes de alterar o banco local.',
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: busy ? null : _pickPackage,
          icon: const Icon(Icons.folder_open_outlined),
          label: const Text('Selecionar pacote .dunots'),
        ),
        if (currentPreview != null) ...[
          const SizedBox(height: 14),
          _PreviewSummary(preview: currentPreview),
          if (currentPreview.conflicts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Conflitos encontrados',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...currentPreview.conflicts
                .take(4)
                .map(
                  (conflict) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.compare_arrows),
                    title: Text(
                      '${conflict.collection} · ${conflict.recordId}',
                    ),
                    subtitle: Text(
                      'Local: ${_recordDate(conflict.local)}\nRecebido: ${_recordDate(conflict.received)}',
                    ),
                  ),
                ),
            if (currentPreview.conflicts.length > 4)
              Text('+ ${currentPreview.conflicts.length - 4} conflito(s)'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _apply(false),
                  child: const Text('Manter locais'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => _apply(true),
                  child: const Text('Usar recebidos'),
                ),
              ),
            ],
          ),
        ],
        if (message != null && tabs.index == 1) ...[
          const SizedBox(height: 14),
          _SyncStatus(message: message!, success: success),
        ],
      ],
    );
  }

  Future<void> _export() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final bytes = await widget.repository.exportBytes();
      final uri = await FilePicker.saveFile(
        fileName: 'dunots-sync-${DateTime.now().millisecondsSinceEpoch}.dunots',
        bytes: bytes,
        mimeType: 'application/vnd.dunots.sync+json',
        type: FileType.custom,
        allowedExtensions: ['dunots'],
      );
      if (!mounted) return;
      setState(() {
        busy = false;
        success = uri != null;
        message = uri == null
            ? 'Exportação cancelada.'
            : 'Pacote salvo em ${uri.toString()}';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        success = false;
        message = 'Não foi possível exportar: $error';
      });
    }
  }

  Future<void> _pickPackage() async {
    setState(() {
      busy = true;
      message = null;
      preview = null;
    });
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['dunots'],
      );
      if (file == null) {
        if (mounted) setState(() => busy = false);
        return;
      }
      final package = widget.repository.decodePackage(await file.readAsBytes());
      final result = await widget.repository.preview(package);
      if (!mounted) return;
      setState(() {
        busy = false;
        preview = result;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        success = false;
        message = 'Não foi possível ler o pacote: $error';
      });
    }
  }

  Future<void> _apply(bool useReceived) async {
    final currentPreview = preview;
    if (currentPreview == null) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await widget.repository.apply(
        currentPreview,
        defaultResolution: useReceived
            ? SyncConflictResolution.useReceived
            : SyncConflictResolution.keepLocal,
      );
      if (!mounted) return;
      setState(() {
        busy = false;
        success = true;
        message =
            'Sincronização concluída: ${result.added} adicionada(s), ${result.updated} atualizada(s), ${result.deleted} excluída(s), ${result.keptLocal} mantida(s) localmente.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        success = false;
        message = 'Não foi possível aplicar a mesclagem: $error';
      });
    }
  }

  String _recordDate(dynamic record) {
    return record.values['updatedAt']?.toString() ?? 'sem data';
  }
}

class _SyncInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _SyncInfoCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(detail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewSummary extends StatelessWidget {
  final SyncMergePreview preview;

  const _PreviewSummary({required this.preview});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('${preview.additions} novas')),
        Chip(label: Text('${preview.unchanged} iguais')),
        Chip(label: Text('${preview.conflicts.length} conflitos')),
        Chip(label: Text('${preview.deletions} exclusões')),
        if (preview.unsupportedCollections.isNotEmpty)
          Chip(
            label: Text(
              '${preview.unsupportedCollections.length} não disponíveis',
            ),
          ),
      ],
    );
  }
}

class _SyncStatus extends StatelessWidget {
  final String message;
  final bool success;

  const _SyncStatus({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
