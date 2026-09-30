import 'package:flutter/material.dart';

import '../../features/roadmaps/domain/study_track.dart';

class DunotsBrand extends StatelessWidget {
  const DunotsBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7168).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: Color(0xFFFF7168),
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'dunots',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  final int count;
  final VoidCallback? onPressed;

  const ReviewCard({super.key, required this.count, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7168).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFFFF7168).withValues(alpha: 0.55),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFFFF7168), size: 19),
              SizedBox(width: 8),
              Text(
                'revisões de hoje',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFF7168),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'flashcards cadastrados',
            style: TextStyle(color: Color(0xFFB6B7AD)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('abrir flashcards'),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A504B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB6B7AD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFB6B7AD),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6B7AD)),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressListTile extends StatelessWidget {
  final StudyTrack track;

  const ProgressListTile({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              track.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              track.progressLabel,
              style: const TextStyle(color: Color(0xFFB6B7AD), fontSize: 12),
            ),
            const SizedBox(height: 9),
            LinearProgressIndicator(value: track.progress),
          ],
        ),
      ),
    );
  }
}

class PreviewPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const PreviewPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF7168)),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(color: Color(0xFFB6B7AD))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class StudyLoadingState extends StatelessWidget {
  final String message;

  const StudyLoadingState({super.key, this.message = 'Carregando...'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFFB6B7AD))),
        ],
      ),
    );
  }
}

class StudyErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const StudyErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            color: Theme.of(context).colorScheme.error,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ],
      ),
    );
  }
}

class StudyEmptyState extends StatelessWidget {
  final String title;
  final String? detail;
  final IconData icon;

  const StudyEmptyState({
    super.key,
    required this.title,
    this.detail,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF78B8FF), size: 32),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB6B7AD)),
            ),
          ],
        ],
      ),
    );
  }
}

class ExampleListTile extends StatelessWidget {
  final String title;
  final String detail;

  const ExampleListTile({super.key, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4A504B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_unchecked,
            color: Color(0xFF78B8FF),
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFB6B7AD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6B7AD)),
        ],
      ),
    );
  }
}
