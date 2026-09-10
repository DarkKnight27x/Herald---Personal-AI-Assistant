import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'due_time.dart';
import 'herald_store.dart';

class HeraldNotifications {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> initialize() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    final preferences = await SharedPreferences.getInstance();
    const requestedKey = 'herald_notification_permission_requested';
    if (preferences.getBool(requestedKey) != true) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await preferences.setBool(requestedKey, true);
    }
    _ready = true;
  }

  Future<void> scheduleItem(HeraldItem item) async {
    try {
      final due = parseHeraldDue(item.due);
      if (due == null || !due.isAfter(DateTime.now())) return;
      await initialize();
      await _plugin.zonedSchedule(
        _id(item.id),
        _title(item.type),
        item.text,
        tz.TZDateTime.from(due, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'herald_reminders',
            'Herald reminders',
            channelDescription: 'Private, on-device Herald reminders',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  Future<void> cancel(String id) async {
    try {
      await initialize();
      await _plugin.cancel(_id(id));
    } catch (_) {}
  }

  Future<void> rescheduleOpen(Iterable<HeraldItem> items) async {
    await initialize();
    for (final item in items) {
      await scheduleItem(item);
    }
  }

  int _id(String id) {
    var hash = 0x811c9dc5;
    for (final code in id.codeUnits) {
      hash = (hash ^ code) * 0x01000193;
    }
    return hash & 0x7fffffff;
  }

  String _title(String type) => switch (type) {
        'deadline' => 'Deadline',
        'reminder' => 'Reminder',
        'meeting' => 'Meeting',
        'followup' => 'They promised this',
        _ => 'You committed to this',
      };
}

final heraldNotifications = HeraldNotifications();
