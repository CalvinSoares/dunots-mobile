import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import 'data/study_node_repository.dart';
import 'data/study_track_repository.dart';
import 'domain/study_track.dart';
import 'presentation/study_tracks_controller.dart';
import 'presentation/study_track_list_item.dart';
import 'presentation/study_track_details_page.dart';

class RoadmapsPreviewPage extends StatefulWidget {
  final StudyTrackRepository? repository;
  final StudyNodeRepository? nodeRepository;

  const RoadmapsPreviewPage({super.key, this.repository, this.nodeRepository});

  @override
  State<RoadmapsPreviewPage> createState() => _RoadmapsPreviewPageState();
}

class _RoadmapsPreviewPageState extends State<RoadmapsPreviewPage> {
  late final StudyTracksController _controller;
  late final StudyNodeRepository _nodeRepository;

  @override
  void initState() {
    super.initState();
    _controller = StudyTracksController(
      repository: widget.repository ?? InMemoryStudyTrackRepository(),
    );
    _nodeRepository = widget.nodeRepository ?? InMemoryStudyNodeRepository();
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
          title: 'Trilhas de estudo',
          subtitle: 'Organize tópicos, subtópicos e materiais.',
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showCreateTrackDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nova trilha'),
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
    final data = await showDialog<_TrackFormData>(
      context: context,
      builder: (_) => const _TrackFormDialog(
        dialogTitle: 'Nova trilha',
        actionLabel: 'Criar',
      ),
    );

    if (data == null || !mounted) {
      return;
    }

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

  Future<void> _openTrack(StudyTrack track) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudyTrackDetailsPage(
          track: track,
          repository: _nodeRepository,
          trackRepository: _controller.repository,
        ),
      ),
    );

    if (mounted) {
      await _controller.load();
    }
  }

  Future<void> _showEditTrackDialog(
    BuildContext context,
    StudyTrack track,
  ) async {
    final data = await showDialog<_TrackFormData>(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Excluir trilha?'),
          content: Text('A trilha "${track.title}" será removida desta lista.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
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
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        );
      case StudyTracksStatus.empty:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Nenhuma trilha cadastrada ainda.'),
          ),
        );
      case StudyTracksStatus.error:
        return Center(
          child: Column(
            children: [
              Text(state.errorMessage ?? 'Ocorreu um erro.'),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _controller.load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
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

class _TrackFormData {
  final String title;
  final String description;

  const _TrackFormData({required this.title, required this.description});
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
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SingleChildScrollView(
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
