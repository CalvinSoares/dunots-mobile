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
          child: _buildContent(context),
        );
      },
    );
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
