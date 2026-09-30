import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/flashcard_review_preferences.dart';

abstract interface class LocalNotificationService {
  Future<void> initialize();

  Future<void> syncDailyFlashcardReminder({
    required FlashcardReviewPreferences preferences,
    required int completedToday,
    required int dueCount,
  });

  Future<bool> requestPermission();
}

class NoopLocalNotificationService implements LocalNotificationService {
  const NoopLocalNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> syncDailyFlashcardReminder({
    required FlashcardReviewPreferences preferences,
    required int completedToday,
    required int dueCount,
  }) async {}
}

class FlutterLocalNotificationService implements LocalNotificationService {
  static const _notificationId = 4101;
  static const _channelId = 'flashcard_review_reminders';
  static const _channelName = 'Revisão de flashcards';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_launcher'),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<void> syncDailyFlashcardReminder({
    required FlashcardReviewPreferences preferences,
    required int completedToday,
    required int dueCount,
  }) async {
    await initialize();
    if (kIsWeb) return;

    if (!preferences.reminderEnabled ||
        completedToday >= preferences.dailyGoal) {
      await _plugin.cancel(id: _notificationId);
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      preferences.reminderHour,
      preferences.reminderMinute,
    );
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Lembretes para revisar flashcards no Dunots.',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_launcher',
      ),
    );
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: 'Hora de revisar seus flashcards',
      body: dueCount > 0
          ? '$dueCount card(s) aguardam revisão.'
          : 'Ainda faltam cards para sua meta de hoje.',
      scheduledDate: next,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
