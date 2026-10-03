import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
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
            color: DunotsColors.emerald.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: DunotsColors.emerald,
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
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$count revisões de hoje',
      hint: onPressed == null
          ? 'Nenhuma ação disponível'
          : 'Ação disponível: abrir flashcards',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DunotsColors.amber.withValues(alpha: 0.10),
          border: Border.all(
            color: DunotsColors.amber.withValues(alpha: 0.42),
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
                Icon(
                  Icons.schedule_rounded,
                  color: DunotsColors.amber,
                  size: 19,
                ),
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
                color: DunotsColors.amber,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'flashcards cadastrados',
              style: TextStyle(color: DunotsColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('abrir flashcards'),
            ),
          ],
        ),
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
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: DunotsColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DunotsColors.border),
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
                style: const TextStyle(color: DunotsColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
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
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: title,
      hint: subtitle,
      child: ExcludeSemantics(
        child: Card(
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
                            color: DunotsColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DunotsColors.muted,
                  ),
                ],
              ),
            ),
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
    return Semantics(
      container: true,
      label: 'Trilha ${track.title}. ${track.progressLabel}',
      child: ExcludeSemantics(
        child: Card(
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
                  style: const TextStyle(
                    color: DunotsColors.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                LinearProgressIndicator(value: track.progress),
              ],
            ),
          ),
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
  final bool showHeader;

  const PreviewPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            StudyScreenHeader(icon: icon, title: title, subtitle: subtitle),
            const SizedBox(height: 24),
          ],
          child,
        ],
      ),
    );
  }
}

/// Cabeçalho curto para telas de conteúdo, com hierarquia previsível.
class StudyScreenHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const StudyScreenHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      label: subtitle == null || subtitle!.isEmpty
          ? title
          : '$title. $subtitle',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: DunotsColors.emerald, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: DunotsColors.muted),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action!],
        ],
      ),
    );
  }
}

/// Ação principal curta, com opção de ocupar a largura disponível.
class StudyPrimaryAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  const StudyPrimaryAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Destaque único para a ação que o estudante deve executar a seguir.
///
/// O componente evita que cada página invente uma combinação diferente de
/// ícone, botão e resumo, preservando uma hierarquia consistente no mobile.
class StudyFocusCard extends StatelessWidget {
  final String eyebrow;
  final IconData eyebrowIcon;
  final String title;
  final String detail;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onPressed;

  const StudyFocusCard({
    super.key,
    required this.eyebrow,
    required this.eyebrowIcon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.actionIcon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$eyebrow. $title. $detail',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DunotsColors.emerald.withValues(alpha: 0.12),
          border: Border.all(
            color: DunotsColors.emerald.withValues(alpha: 0.44),
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(eyebrowIcon, size: 16, color: DunotsColors.mint),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DunotsColors.mint,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: DunotsColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPressed,
                  icon: Icon(actionIcon),
                  label: Text(actionLabel, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudyMetric {
  final String value;
  final String label;
  final Color color;

  const StudyMetric({
    required this.value,
    required this.label,
    required this.color,
  });
}

/// Resumo de poucas métricas, sem transformar a tela em um dashboard.
class StudyMetricStrip extends StatelessWidget {
  final List<StudyMetric> metrics;

  const StudyMetricStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: metrics
          .map((metric) => '${metric.value} ${metric.label}')
          .join(', '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DunotsColors.panel,
          border: Border.all(color: DunotsColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: List.generate(metrics.length, (index) {
              final metric = metrics[index];
              return Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: index == 0
                        ? null
                        : const Border(
                            left: BorderSide(color: DunotsColors.border),
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        metric.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: metric.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DunotsColors.muted,
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Campo de busca padronizado para listas de estudo.
class StudySearchField extends StatelessWidget {
  final String hintText;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const StudySearchField({
    super.key,
    this.hintText = 'Buscar',
    this.query = '',
    required this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hintText,
        suffixIcon: query.isEmpty || onClear == null
            ? null
            : IconButton(
                tooltip: 'Limpar busca',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }
}

/// Ação compacta de filtro, com indicação visual de estado ativo.
class StudyFilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;
  final String tooltip;

  const StudyFilterButton({
    super.key,
    required this.active,
    required this.onPressed,
    this.tooltip = 'Filtrar',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? '$tooltip. Filtros ativos' : tooltip,
      hint: 'Abre os filtros avançados.',
      child: Badge(
        isLabelVisible: active,
        child: IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: const Icon(Icons.tune),
        ),
      ),
    );
  }
}

/// Menu contextual com área de toque compacta e ícone consistente.
class StudyContextMenu<T> extends StatelessWidget {
  final List<PopupMenuEntry<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T> onSelected;
  final String tooltip;

  const StudyContextMenu({
    super.key,
    required this.itemBuilder,
    required this.onSelected,
    this.tooltip = 'Mais ações',
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: const Icon(Icons.more_vert),
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
          Text(message, style: const TextStyle(color: DunotsColors.muted)),
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
          Icon(icon, color: DunotsColors.emerald, size: 32),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center),
          if (detail != null) ...[
            const SizedBox(height: 4),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: DunotsColors.muted),
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
  final VoidCallback? onTap;

  const ExampleListTile({
    super.key,
    required this.title,
    required this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const Icon(
                Icons.radio_button_unchecked,
                color: DunotsColors.emerald,
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
                        color: DunotsColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DunotsColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
