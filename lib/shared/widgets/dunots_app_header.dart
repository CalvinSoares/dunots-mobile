import 'package:flutter/material.dart';

import '../../app/dunots_theme.dart';
import '../../core/models/flashcard_review_preferences.dart';
import '../../core/notifications/local_notification_service.dart';
import '../../features/flashcards/data/flashcard_repository.dart';
import '../../features/flashcards/data/flashcard_review_preferences_repository.dart';
import '../../features/flashcards/data/flashcard_session_repository.dart';
import 'dunots_modal.dart';

class DunotsAppHeader extends StatefulWidget {
  final IconData icon;
  final String title;
  final FlashcardRepository? flashcardRepository;
  final FlashcardSessionRepository? flashcardSessionRepository;
  final FlashcardReviewPreferencesRepository?
  flashcardReviewPreferencesRepository;
  final LocalNotificationService? localNotificationService;
  final VoidCallback? onOpenFlashcards;
  final VoidCallback? onOpenSync;

  const DunotsAppHeader({
    super.key,
    this.icon = Icons.today_outlined,
    this.title = 'Hoje',
    this.flashcardRepository,
    this.flashcardSessionRepository,
    this.flashcardReviewPreferencesRepository,
    this.localNotificationService,
    this.onOpenFlashcards,
    this.onOpenSync,
  });

  @override
  State<DunotsAppHeader> createState() => DunotsAppHeaderState();
}

class DunotsAppHeaderState extends State<DunotsAppHeader> {
  late Future<_ReminderSnapshot> _snapshotFuture;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  void refresh() {
    if (mounted) setState(() => _snapshotFuture = _loadSnapshot());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReminderSnapshot>(
      future: _snapshotFuture,
      builder: (context, snapshot) {
        final reminder = snapshot.data;
        final dueCount = reminder?.dueCount ?? 0;
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 6),
            child: Semantics(
              container: true,
              header: true,
              label: 'Página ${widget.title}. Notificações',
              child: Row(
                children: [
                  Icon(widget.icon, color: DunotsColors.emerald, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (widget.onOpenSync != null)
                    Semantics(
                      button: true,
                      label: 'Sincronizar dados',
                      child: IconButton(
                        tooltip: 'Sincronizar dados',
                        onPressed: widget.onOpenSync,
                        icon: const Icon(Icons.sync_outlined),
                      ),
                    ),
                  _NotificationButton(
                    dueCount: dueCount,
                    onPressed: reminder == null
                        ? null
                        : () => _openReminderCenter(reminder),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<_ReminderSnapshot> _loadSnapshot() async {
    final cards =
        await (widget.flashcardRepository ?? InMemoryFlashcardRepository())
            .getAll();
    final sessions =
        await (widget.flashcardSessionRepository ??
                InMemoryFlashcardSessionRepository())
            .getForDay(DateTime.now());
    final preferences =
        await (widget.flashcardReviewPreferencesRepository ??
                InMemoryFlashcardReviewPreferencesRepository())
            .get();
    final completedToday = sessions.fold<int>(
      0,
      (total, session) => total + session.cardCount,
    );
    final now = DateTime.now();
    return _ReminderSnapshot(
      dueCount: cards.where((card) => card.isDueAt(now)).length,
      completedToday: completedToday,
      preferences: preferences,
    );
  }

  Future<void> _openReminderCenter(_ReminderSnapshot snapshot) async {
    await showDunotsDrawer<void>(
      context: context,
      builder: (_) => _ReminderCenterDialog(
        snapshot: snapshot,
        onOpenFlashcards: widget.onOpenFlashcards,
        onSavePreferences: _savePreferences,
      ),
    );
    refresh();
  }

  Future<void> _savePreferences(FlashcardReviewPreferences preferences) async {
    final repository = widget.flashcardReviewPreferencesRepository;
    if (repository != null) await repository.save(preferences);
    if (preferences.reminderEnabled) {
      await (widget.localNotificationService ??
              const NoopLocalNotificationService())
          .requestPermission();
    }
  }
}

class _NotificationButton extends StatelessWidget {
  final int dueCount;
  final VoidCallback? onPressed;

  const _NotificationButton({required this.dueCount, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: dueCount == 0
          ? 'Notificações. Nenhuma revisão pendente.'
          : 'Notificações. $dueCount revisão(ões) pendente(s).',
      child: IconButton(
        tooltip: dueCount == 0 ? 'Notificações' : 'Notificações pendentes',
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_none_outlined),
            if (dueCount > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: DunotsColors.amber,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCenterDialog extends StatefulWidget {
  final _ReminderSnapshot snapshot;
  final VoidCallback? onOpenFlashcards;
  final Future<void> Function(FlashcardReviewPreferences) onSavePreferences;

  const _ReminderCenterDialog({
    required this.snapshot,
    required this.onOpenFlashcards,
    required this.onSavePreferences,
  });

  @override
  State<_ReminderCenterDialog> createState() => _ReminderCenterDialogState();
}

class _ReminderCenterDialogState extends State<_ReminderCenterDialog> {
  late FlashcardReviewPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.snapshot.preferences;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_preferences.dailyGoal - widget.snapshot.completedToday)
        .clamp(0, _preferences.dailyGoal);
    final schedule = _formatTime(
      _preferences.reminderHour,
      _preferences.reminderMinute,
    );
    return DunotsModal(
      title: 'Notificações',
      subtitle: 'Acompanhe o que precisa da sua atenção.',
      icon: Icons.notifications_none_outlined,
      // ignore: sort_child_properties_last
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color:
                (widget.snapshot.dueCount > 0
                        ? DunotsColors.amber
                        : DunotsColors.mint)
                    .withValues(alpha: 0.10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    widget.snapshot.dueCount > 0
                        ? Icons.notification_important_outlined
                        : Icons.check_circle_outline,
                    color: widget.snapshot.dueCount > 0
                        ? DunotsColors.amber
                        : DunotsColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.snapshot.dueCount > 0
                              ? 'Revisões pendentes'
                              : 'Tudo em dia',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.snapshot.dueCount > 0
                              ? '${widget.snapshot.dueCount} card(s) aguardam revisão.'
                              : 'Nenhum card aguarda revisão agora.',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.snapshot.completedToday} revisados hoje · faltam $remaining para a meta',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule_outlined),
            title: const Text('Lembrete diário'),
            subtitle: Text(
              _preferences.reminderEnabled
                  ? 'Ativo todos os dias às $schedule'
                  : 'Desativado',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _configureReminder,
          ),
          if (widget.snapshot.dueCount > 0) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenFlashcards?.call();
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Revisar agora'),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Future<void> _configureReminder() async {
    final updated = await showDunotsDrawer<FlashcardReviewPreferences>(
      context: context,
      builder: (_) => _ReminderSettingsDialog(preferences: _preferences),
    );
    if (updated == null || !mounted) return;
    await widget.onSavePreferences(updated);
    if (mounted) setState(() => _preferences = updated);
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

class _ReminderSettingsDialog extends StatefulWidget {
  final FlashcardReviewPreferences preferences;

  const _ReminderSettingsDialog({required this.preferences});

  @override
  State<_ReminderSettingsDialog> createState() =>
      _ReminderSettingsDialogState();
}

class _ReminderSettingsDialogState extends State<_ReminderSettingsDialog> {
  late bool _enabled;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _enabled = widget.preferences.reminderEnabled;
    _time = TimeOfDay(
      hour: widget.preferences.reminderHour,
      minute: widget.preferences.reminderMinute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DunotsModal(
      title: 'Lembrete diário',
      subtitle: 'Escolha quando o Dunots deve lembrar você de revisar.',
      icon: Icons.schedule_outlined,
      // ignore: sort_child_properties_last
      child: DunotsFormColumn(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Receber lembrete'),
            subtitle: const Text(
              'Mostrar uma notificação no horário escolhido',
            ),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time_outlined),
            title: const Text('Horário da revisão'),
            subtitle: Text(_time.format(context)),
            enabled: _enabled,
            onTap: _enabled ? _pickTime : null,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.preferences.copyWith(
              reminderEnabled: _enabled,
              reminderHour: _time.hour,
              reminderMinute: _time.minute,
            ),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }
}

class _ReminderSnapshot {
  final int dueCount;
  final int completedToday;
  final FlashcardReviewPreferences preferences;

  const _ReminderSnapshot({
    required this.dueCount,
    required this.completedToday,
    required this.preferences,
  });
}
