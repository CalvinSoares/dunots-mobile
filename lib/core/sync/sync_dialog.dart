import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'sync_database_repository.dart';
import 'sync_network_client.dart';

class SyncDialog extends StatefulWidget {
  final SyncDatabaseRepository repository;
  final SyncMergePreview? initialPreview;

  const SyncDialog({super.key, required this.repository, this.initialPreview});

  @override
  State<SyncDialog> createState() => _SyncDialogState();
}

class _SyncDialogState extends State<SyncDialog>
    with SingleTickerProviderStateMixin {
  late final TabController tabs;
  SyncMergePreview? preview;
  final Map<String, SyncConflictResolution> resolutions = {};
  SyncConflictResolution defaultResolution = SyncConflictResolution.keepLocal;
  bool busy = false;
  String? message;
  bool success = false;
  List<SyncBackup> backups = const [];
  late final SyncNetworkClient networkClient;
  SyncNetworkSession? networkSession;
  final pairingCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
    preview = widget.initialPreview;
    networkClient = SyncNetworkClient();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshBackups();
    });
  }

  @override
  void dispose() {
    tabs.dispose();
    pairingCodeController.dispose();
    networkClient.close();
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
                Tab(text: 'Backups'),
                Tab(text: 'Rede local'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 410,
              child: TabBarView(
                controller: tabs,
                children: [
                  _buildExportTab(),
                  _buildImportTab(),
                  _buildBackupsTab(),
                  _buildNetworkTab(),
                ],
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
              'Conflitos encontrados — escolha por registro',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...currentPreview.conflicts.map(_buildConflictTile),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => _apply(false),
                  child: const Text('Aplicar: manter locais'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => _apply(true),
                  child: const Text('Aplicar: usar recebidos'),
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

  Widget _buildBackupsTab() {
    return ListView(
      children: [
        const _SyncInfoCard(
          icon: Icons.restore_outlined,
          title: 'Restaurar um ponto anterior',
          detail: 'Cada mesclagem cria um backup automático. Restaurar também cria um novo backup de segurança antes de substituir os dados atuais.',
        ),
        const SizedBox(height: 14),
        if (backups.isEmpty)
          const Center(child: Text('Nenhum backup disponível.'))
        else
          ...backups.map(
            (backup) => Card(
              child: ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(backup.id),
                subtitle: Text(_formatDate(backup.createdAt)),
                trailing: OutlinedButton(
                  onPressed: busy ? null : () => _restore(backup),
                  child: const Text('Restaurar'),
                ),
              ),
            ),
          ),
        if (message != null && tabs.index == 2) ...[
          const SizedBox(height: 14),
          _SyncStatus(message: message!, success: success),
        ],
      ],
    );
  }

  Widget _buildNetworkTab() {
    return ListView(
      children: [
        const _SyncInfoCard(
          icon: Icons.wifi_tethering_outlined,
          title: 'Parear pela rede local',
          detail: 'Cole o código copiado pelo Dunots Desktop. O código contém endereço, token temporário e expiração; o payload é protegido com AES-GCM.',
        ),
        const SizedBox(height: 14),
        TextField(
          controller: pairingCodeController,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Código de pareamento',
            hintText: '{"address":"http://...","token":"..."}',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : _receiveNetwork,
          icon: const Icon(Icons.download_outlined),
          label: const Text('Receber do outro dispositivo'),
        ),
        if (networkSession != null) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sessão pareada',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Revise a prévia na aba Importar. Depois de aplicar, envie o estado deste mobile de volta uma única vez.',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => tabs.animateTo(1),
                        child: const Text('Abrir prévia'),
                      ),
                      FilledButton.icon(
                        onPressed: busy ? null : _sendNetworkBack,
                        icon: const Icon(Icons.upload_outlined),
                        label: const Text('Enviar meus dados de volta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
        if (message != null && tabs.index == 3) ...[
          const SizedBox(height: 14),
          _SyncStatus(message: message!, success: success),
        ],
      ],
    );
  }

  Future<void> _receiveNetwork() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final pairing = SyncPairingCode.decode(pairingCodeController.text);
      final session = await networkClient.receiveFromDesktop(pairing);
      final result = await widget.repository.preview(session.package);
      if (!mounted) return;
      setState(() {
        networkSession = session;
        preview = result;
        resolutions.clear();
        defaultResolution = SyncConflictResolution.keepLocal;
        busy = false;
        success = true;
        message =
            'Pacote recebido pela rede. Revise a prévia antes de aplicar.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        success = false;
        message = 'Não foi possível parear: $error';
      });
    }
  }

  Future<void> _sendNetworkBack() async {
    final session = networkSession;
    if (session == null) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await session.sendBack(await widget.repository.exportPackage());
      if (!mounted) return;
      setState(() {
        networkSession = null;
        busy = false;
        success = true;
        message = 'Dados enviados de volta. A sessão foi encerrada.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        success = false;
        message = 'Não foi possível enviar os dados: $error';
      });
    }
  }

  Future<void> _refreshBackups() async {
    try {
      final value = await widget.repository.listBackups();
      if (mounted) setState(() => backups = value);
    } catch (_) {
      // O estado vazio continua sendo válido se a tabela ainda não estiver
      // disponível em uma instalação muito antiga.
    }
  }

  Future<void> _restore(SyncBackup backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurar backup?'),
        content: Text(
          'Os dados atuais serão substituídos pelo snapshot ${backup.id}. '
          'Um backup de segurança será criado antes da restauração.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await widget.repository.restoreBackup(backup.id);
      if (!mounted) return;
      await _refreshBackups();
      if (!mounted) return;
      setState(() {
        busy = false;
        success = true;
        message =
            'Backup restaurado. Backup de segurança criado: ${result.safetyBackupId}.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        busy = false;
        success = false;
        message = 'Não foi possível restaurar o backup: $error';
      });
    }
  }

  String _formatDate(DateTime value) {
    return value.toLocal().toIso8601String();
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
        resolutions.clear();
        defaultResolution = SyncConflictResolution.keepLocal;
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

  Widget _buildConflictTile(SyncConflict conflict) {
    final selected = resolutions[conflict.key] ?? defaultResolution;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${conflict.collection} · ${conflict.recordId}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              'Local: ${_recordDate(conflict.local)}\n'
              'Recebido: ${_recordDate(conflict.received)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            DropdownButton<SyncConflictResolution>(
              value: selected,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: SyncConflictResolution.keepLocal,
                  child: Text('Manter este registro local'),
                ),
                DropdownMenuItem(
                  value: SyncConflictResolution.useReceived,
                  child: Text('Usar este registro recebido'),
                ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => resolutions[conflict.key] = value);
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _apply(bool useReceived) async {
    final currentPreview = preview;
    if (currentPreview == null) return;
    defaultResolution = useReceived
        ? SyncConflictResolution.useReceived
        : SyncConflictResolution.keepLocal;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final result = await widget.repository.apply(
        currentPreview,
        defaultResolution: defaultResolution,
        resolutions: Map.unmodifiable(resolutions),
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
