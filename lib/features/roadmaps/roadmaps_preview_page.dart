import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';
import 'data/study_track_repository.dart';
import 'presentation/study_tracks_controller.dart';

class RoadmapsPreviewPage extends StatefulWidget {
  final StudyTrackRepository? repository;

  const RoadmapsPreviewPage({super.key, this.repository});

  @override
  State<RoadmapsPreviewPage> createState() => _RoadmapsPreviewPageState();
}

class _RoadmapsPreviewPageState extends State<RoadmapsPreviewPage> {
  late final StudyTracksController _controller;

  @override
  void initState() {
    super.initState();
    _controller = StudyTracksController(
      repository: widget.repository ?? InMemoryStudyTrackRepository(),
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
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final data = await showDialog<_NewTrackData>(
      context: context,
      builder: (dialogContext) {
        String? validationError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova trilha'),
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
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      setDialogState(() {
                        validationError = 'Informe um título para a trilha.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _NewTrackData(
                        title: titleController.text,
                        description: descriptionController.text,
                      ),
                    );
                  },
                  child: const Text('Criar'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();

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
              child: ExampleListTile(
                title: track.title,
                detail: track.progressLabel,
              ),
            );
          }).toList(),
        );
    }
  }
}

class _NewTrackData {
  final String title;
  final String description;

  const _NewTrackData({required this.title, required this.description});
}
