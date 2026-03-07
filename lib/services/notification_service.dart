import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../screens/practice/presentation/screens/practice_screen.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;
  static const int _inactivityId = 1002;
  static const int _weeklyReportId = 1003;
  static const int _instantId = 1004;

  Future<void> initializeNotifications() async {
    if (kIsWeb) {
      return;
    }
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: null,
      macOS: null,
    );
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == 'practice') {
          final nav = navigatorKey.currentState;
          if (nav != null) {
            nav.push(MaterialPageRoute(builder: (_) => const PracticeScreen()));
          }
        }
      },
    );
    await _ensureChannels();
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return true;
    }
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl != null) {
      final enabled = await androidImpl.areNotificationsEnabled();
      if (enabled == true) {
        return true;
      }
      try {
        final granted = await androidImpl.requestNotificationsPermission();
        return granted ?? false;
      } catch (_) {
        return enabled ?? false;
      }
    }
    return true;
  }

  Future<void> requestNotificationPermission() async {
    await requestPermission();
  }

  Future<void> _ensureChannels() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidImpl == null) return;
    final channels = <AndroidNotificationChannel>[
      const AndroidNotificationChannel(
        'daily_reminders_channel',
        'Daily Reminders',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'decay_alerts_channel',
        'Skill Decay Alerts',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'inactivity_channel',
        'Inactivity Reminders',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'weekly_reports_channel',
        'Weekly Reports',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'instant_channel',
        'Instant Alerts',
        importance: Importance.high,
      ),
    ];
    for (final ch in channels) {
      await androidImpl.createNotificationChannel(ch);
    }
  }

  Future<void> showInstantNotification(
    String title,
    String message, {
    String? payload,
  }) async {
    if (kIsWeb) {
      return;
    }
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      _instantId,
      title,
      message,
      details,
      payload: payload ?? 'practice',
    );
  }

  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {
    if (kIsWeb) {
      return;
    }
    final scheduled = _nextInstanceOfTime(hour, minute);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_reminders_channel',
        'Daily Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _zonedScheduleSafe(
      id: _dailyReminderId,
      title: 'Daily Practice Reminder',
      body: 'Your brain is waiting. Practice one of your skills today.',
      scheduled: scheduled,
      details: details,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'practice',
    );
  }

  Future<void> cancelDailyReminder() async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> scheduleDecayAlert(
    String skillName, {
    int hour = 9,
    int minute = 0,
  }) async {
    if (kIsWeb) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final when = now.add(const Duration(days: 3));
    final scheduled = _atLocal(when.year, when.month, when.day, hour, minute);
    final id = 2000 + (skillName.hashCode.abs() % 1000000);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'decay_alerts_channel',
        'Skill Decay Alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _zonedScheduleSafe(
      id: id,
      title: 'Skill Decay Alert',
      body:
          'Your $skillName skill is starting to fade. A quick practice will refresh it.',
      scheduled: scheduled,
      details: details,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'practice',
    );
  }

  Future<void> scheduleInactivityReminder({
    int days = 4,
    int hour = 10,
    int minute = 0,
  }) async {
    if (kIsWeb) {
      return;
    }
    final now = tz.TZDateTime.now(tz.local);
    final target = now.add(Duration(days: days));
    final scheduled = _atLocal(
      target.year,
      target.month,
      target.day,
      hour,
      minute,
    );
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'inactivity_channel',
        'Inactivity Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final messages = [
      'Your skills are ghosting you 👻',
      'Your brain is asking for an update.',
      'System warning: Human has stopped learning.',
    ];
    final message = messages[Random().nextInt(messages.length)];
    await _zonedScheduleSafe(
      id: _inactivityId,
      title: 'We miss you',
      body: message,
      scheduled: scheduled,
      details: details,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      payload: 'practice',
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastOpen', DateTime.now().toIso8601String());
  }

  Future<void> resetInactivityTimer() async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancel(_inactivityId);
    await scheduleInactivityReminder();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastOpen', DateTime.now().toIso8601String());
  }

  Future<void> scheduleWeeklyReport({int hour = 20, int minute = 0}) async {
    if (kIsWeb) {
      return;
    }
    final scheduled = _nextSundayAt(hour, minute);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'weekly_reports_channel',
        'Weekly Reports',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _zonedScheduleSafe(
      id: _weeklyReportId,
      title: 'Weekly Learning Report',
      body: 'This week you practiced {X} skills. Keep the streak alive.',
      scheduled: scheduled,
      details: details,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'practice',
    );
  }

  Future<void> _zonedScheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduled,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') {
        rethrow;
      }

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextSundayAt(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    while (scheduled.weekday != DateTime.sunday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
        tz.local,
        scheduled.year,
        scheduled.month,
        scheduled.day,
        hour,
        minute,
      );
    }
    return scheduled;
  }

  tz.TZDateTime _atLocal(int year, int month, int day, int hour, int minute) {
    return tz.TZDateTime(tz.local, year, month, day, hour, minute);
  }
}
