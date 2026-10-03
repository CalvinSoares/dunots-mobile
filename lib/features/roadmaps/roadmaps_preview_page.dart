import 'package:flutter/material.dart';

import '../flashcards/data/flashcard_repository.dart';
import '../questions/data/question_repository.dart';
import '../quizzes/data/quiz_attempt_repository.dart';
import '../../shared/widgets/study_widgets.dart';
import '../../shared/widgets/dunots_modal.dart';
import 'data/study_material_catalog_repository.dart';
import 'data/study_node_repository.dart';
import 'data/study_material_repository.dart';
import 'data/study_track_repository.dart';
import 'data/study_document_repository.dart';
import 'data/study_document_import_service.dart';
import 'data/study_material_progress_repository.dart';
import 'domain/study_track.dart';
import 'domain/study_node.dart';
import 'presentation/study_tracks_controller.dart';
import 'presentation/study_track_list_item.dart';
import 'presentation/study_track_details_page.dart';
import 'study_track_bulk_import_dialog.dart';

class RoadmapsPreviewPage extends StatefulWidget {
  final bool showHeader;
  final StudyTrackRepository? repository;
  final StudyNodeRepository? nodeRepository;
  final StudyNodeMaterialRepository? materialLinkRepository;
  final FlashcardRepository? flashcardRepository;
  final QuestionRepository? questionRepository;
  final QuizAttemptRepository? attemptRepository;
  final StudyDocumentRepository? documentRepository;
  final StudyMaterialProgressRepository? materialProgressRepository;

  const RoadmapsPreviewPage({
    super.key,
    this.showHeader = true,
    this.repository,
    this.nodeRepository,
    this.materialLinkRepository,
    this.flashcardRepository,
    this.questionRepository,
    this.attemptRepository,
    this.documentRepository,
    this.materialProgressRepository,
  });

  @override
  State<RoadmapsPreviewPage> createState() => _RoadmapsPreviewPageState();
}

class _RoadmapsPreviewPageState extends State<RoadmapsPreviewPage> {
  late final StudyTracksController _controller;
  late final StudyNodeRepository _nodeRepository;
  late final StudyNodeMaterialRepository _materialLinkRepository;
  late final StudyMaterialRepository _materialRepository;

  @override
  void initState() {
    super.initState();
    _controller = StudyTracksController(
      repository: widget.repository ?? InMemoryStudyTrackRepository(),
    );
    _nodeRepository = widget.nodeRepository ?? InMemoryStudyNodeRepository();
    _materialLinkRepository =
        widget.materialLinkRepository ?? InMemoryStudyNodeMaterialRepository();
    _materialRepository = StudyMaterialCatalogRepository(
      flashcardRepository:
          widget.flashcardRepository ?? InMemoryFlashcardRepository(),
      questionRepository:
          widget.questionRepository ?? InMemoryQuestionRepository(),
      documentRepository: widget.documentRepository,
    );
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PreviewPage(
          icon: Icons.route_outlined,
          title: 'Minhas trilhas',
          subtitle: 'Continue de onde parou.',
          showHeader: widget.showHeader,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showCreateTrackDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nova trilha'),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Importar material',
                      onPressed: () => _importDocument(context),
                      icon: const Icon(Icons.upload_file_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildContent(context),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCreateTrackDialog(BuildContext context) async {
    final result = await showDunotsDrawer<_TrackCreationResult>(
      context: context,
      builder: (_) => const _TrackCreationDialog(),
    );

    if (result == null || !mounted) {
      return;
    }

    if (result.bulk != null) {
      await _createTrackFromBulk(result.bulk!);
      return;
    }

    final data = result.form!;
    try {
      await _controller.createTrack(
        title: data.title,
        description: data.description,
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _createTrackFromBulk(StudyTrackBulkFormData data) async {
    try {
      final track = await _controller.createTrack(
        title: data.title,
        description: data.description,
      );
      final nextOrderByParent = <String?, int>{};
      final stack = <_BulkNodeStackItem>[];
      final now = DateTime.now().toUtc();

      for (var index = 0; index < data.items.length; index++) {
        final item = data.items[index];
        while (stack.isNotEmpty && stack.last.depth >= item.depth) {
          stack.removeLast();
        }
        final parentId = stack.isEmpty ? null : stack.last.id;
        final sortOrder = nextOrderByParent[parentId] ?? 0;
        final node = StudyNode(
          id: 'node-${now.microsecondsSinceEpoch}-$index',
          trackId: track.id,
          parentId: parentId,
          title: item.title,
          description: item.description ?? '',
          sortOrder: sortOrder,
          priority: data.priority,
          createdAt: now,
          updatedAt: now,
        );
        await _nodeRepository.create(node);
        nextOrderByParent[parentId] = sortOrder + 1;
        stack.add(_BulkNodeStackItem(depth: item.depth, id: node.id));
      }

      await _controller.repository.update(
        track.copyWith(
          totalItems: data.items.length,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      await _controller.load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trilha criada com ${data.items.length} item(ns).'),
        ),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _openTrack(StudyTrack track) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyTrackDetailsPage(
          track: track,
          repository: _nodeRepository,
          trackRepository: _controller.repository,
          materialLinkRepository: _materialLinkRepository,
          materialRepository: _materialRepository,
          flashcardRepository: widget.flashcardRepository,
          questionRepository: widget.questionRepository,
          attemptRepository: widget.attemptRepository,
          documentRepository: widget.documentRepository,
          materialProgressRepository: widget.materialProgressRepository,
        ),
      ),
    );

    if (mounted) {
      await _controller.load();
    }
  }

  Future<void> _importDocument(BuildContext context) async {
    final repository = widget.documentRepository;
    if (repository == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Importação indisponível neste ambiente.'),
        ),
      );
      return;
    }
    try {
      final document = await const StudyDocumentImportService().pickAndImport(
        repository,
      );
      if (document == null || !context.mounted) return;
      {
        final catalog = _materialRepository;
        if (catalog is StudyMaterialCatalogRepository) catalog.invalidate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Material “${document.title}” importado.')),
        );
        setState(() {});
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível importar o material.')),
      );
    }
  }

  Future<void> _showEditTrackDialog(
    BuildContext context,
    StudyTrack track,
  ) async {
    final data = await showDunotsDrawer<_TrackFormData>(
      context: context,
      builder: (_) => _TrackFormDialog(
        dialogTitle: 'Editar trilha',
        actionLabel: 'Salvar',
        initialTitle: track.title,
        initialDescription: track.description,
      ),
    );

    if (data == null || !mounted) {
      return;
    }

    try {
      await _controller.updateTrack(
        track: track,
        title: data.title,
        description: data.description,
      );
    } on ArgumentError catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  Future<void> _confirmDeleteTrack(
    BuildContext context,
    StudyTrack track,
  ) async {
    final confirmed = await showDunotsDrawer<bool>(
      context: context,
      builder: (_) => DunotsConfirmDialog(
        title: 'Excluir trilha?',
        message: 'A trilha "${track.title}" será removida desta lista.',
        confirmLabel: 'Excluir',
        icon: Icons.delete_outline,
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _controller.deleteTrack(track.id);
  }

  Widget _buildContent(BuildContext context) {
    final state = _controller.state;

    switch (state.status) {
      case StudyTracksStatus.initial:
      case StudyTracksStatus.loading:
        return const StudyLoadingState(message: 'Carregando trilhas...');
      case StudyTracksStatus.empty:
        return const StudyEmptyState(
          title: 'Nenhuma trilha cadastrada ainda.',
          detail: 'Crie uma trilha para organizar seus estudos.',
          icon: Icons.route_outlined,
        );
      case StudyTracksStatus.error:
        return StudyErrorState(
          message:
              state.errorMessage ?? 'Ocorreu um erro ao carregar as trilhas.',
          onRetry: _controller.load,
        );
      case StudyTracksStatus.data:
        return Column(
          children: state.tracks.map((track) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StudyTrackListItem(
                track: track,
                onOpen: () => _openTrack(track),
                onEdit: () => _showEditTrackDialog(context, track),
                onDelete: () => _confirmDeleteTrack(context, track),
              ),
            );
          }).toList(),
        );
    }
  }
}

class _TrackCreationResult {
  final _TrackFormData? form;
  final StudyTrackBulkFormData? bulk;

  const _TrackCreationResult.form(this.form) : bulk = null;

  const _TrackCreationResult.bulk(this.bulk) : form = null;
}

class _TrackCreationDialog extends StatefulWidget {
  const _TrackCreationDialog();

  @override
  State<_TrackCreationDialog> createState() => _TrackCreationDialogState();
}

class _TrackCreationDialogState extends State<_TrackCreationDialog>
    with SingleTickerProviderStateMixin {
  late final TabController tabController;
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  final bulkFormKey = GlobalKey<StudyTrackBulkImportFormState>();
  String? validationError;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this)
      ..addListener(_handleTabChanged);
    titleController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    tabController
      ..removeListener(_handleTabChanged)
      ..dispose();
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBulk = tabController.index == 1;
    return DunotsModal(
      title: 'Nova trilha',
      subtitle: isBulk
          ? 'Cole vários tópicos e subtópicos de uma vez.'
          : 'Crie uma trilha para organizar seus estudos.',
      icon: Icons.route_outlined,
      // ignore: sort_child_properties_last
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'Nova trilha'),
              Tab(text: 'Em massa'),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isBulk
                ? StudyTrackBulkImportForm(
                    key: bulkFormKey,
                    onChanged: () => setState(() {}),
                    onSubmitted: _submitBulk,
                  )
                : _buildManualForm(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: isBulk
              ? bulkFormKey.currentState?.canSubmit == true
                    ? bulkFormKey.currentState!.submit
                    : null
              : _canSubmitManual
              ? _submitManual
              : null,
          child: const Text('Criar trilha'),
        ),
      ],
    );
  }

  Widget _buildManualForm() {
    return Column(
      key: const ValueKey('manual-track-form'),
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: titleController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() => validationError = null),
          decoration: const InputDecoration(
            labelText: 'Título *',
            hintText: 'Ex.: Análise de Sistemas',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descrição (opcional)',
            hintText: 'Explique o objetivo desta trilha',
          ),
        ),
        if (validationError != null) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              validationError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ],
    );
  }

  bool get _canSubmitManual => titleController.text.trim().isNotEmpty;

  void _submitManual() {
    if (!_canSubmitManual) {
      setState(() => validationError = 'Informe um título para a trilha.');
      return;
    }

    Navigator.of(context).pop(
      _TrackCreationResult.form(
        _TrackFormData(
          title: titleController.text,
          description: descriptionController.text,
        ),
      ),
    );
  }

  void _submitBulk(StudyTrackBulkFormData data) {
    Navigator.of(context).pop(_TrackCreationResult.bulk(data));
  }

  void _handleTabChanged() {
    if (mounted) setState(() {});
  }
}

class _TrackFormData {
  final String title;
  final String description;

  const _TrackFormData({required this.title, required this.description});
}

class _BulkNodeStackItem {
  final int depth;
  final String id;

  const _BulkNodeStackItem({required this.depth, required this.id});
}

class _TrackFormDialog extends StatefulWidget {
  final String dialogTitle;
  final String actionLabel;
  final String initialTitle;
  final String initialDescription;

  const _TrackFormDialog({
    required this.dialogTitle,
    required this.actionLabel,
    this.initialTitle = '',
    this.initialDescription = '',
  });

  @override
  State<_TrackFormDialog> createState() => _TrackFormDialogState();
}

class _TrackFormDialogState extends State<_TrackFormDialog> {
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  String? validationError;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: widget.dialogTitle,
      icon: Icons.route_outlined,
      // ignore: sort_child_properties_last
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Título',
              hintText: 'Ex.: Análise de Sistemas',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              hintText: 'Explique o objetivo desta trilha',
            ),
          ),
          if (validationError != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                validationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
      ],
    );
  }

  void _submit() {
    if (titleController.text.trim().isEmpty) {
      setState(() {
        validationError = 'Informe um título para a trilha.';
      });
      return;
    }

    Navigator.of(context).pop(
      _TrackFormData(
        title: titleController.text,
        description: descriptionController.text,
      ),
    );
  }
}
