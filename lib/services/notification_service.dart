import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../shared/models/models.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const windows = WindowsInitializationSettings(
      appName: 'Monk',
      appUserModelId: 'com.prpapp.prp',
      guid: 'b7c3e1f2-d4a5-4890-b12c-def456789abc',
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        windows: windows,
      ),
    );
    _initialized = true;
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedule notifications for all blocks in a schedule mode
  // Web is not supported by flutter_local_notifications.
  Future<void> scheduleBlockNotifications(
    List<ScheduleBlock> blocks,
    String timezone,
  ) async {
    // Cancel existing schedule notifications (IDs 1000-1999)
    for (var i = 1000; i < 2000; i++) {
      await _plugin.cancel(id: i);
    }

    final location = tz.getLocation(timezone);
    final now = tz.TZDateTime.now(location);

    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      if (!block.notifyOnStart) continue;

      final parts = block.time.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);

      var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, h, m);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        id: 1000 + i,
        title: '⏰ ${block.label}',
        body: block.note ?? _categoryLabel(block.categoryKey),
        scheduledDate: scheduled,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'schedule_blocks',
            'Schedule Blocks',
            channelDescription: 'Daily schedule block reminders',
            importance: Importance.high,
            priority: Priority.high,
            color: _categoryColor(block.categoryKey),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
          windows: const WindowsNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> showInstant({
    required String title,
    required String body,
    int id = 0,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'general', 'General',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  String _categoryLabel(String key) {
    return switch (key) {
      'deen'    => 'Deen activity',
      'learn'   => 'Learning time',
      'project' => 'Project work',
      'health'  => 'Health activity',
      'work'    => 'Work block',
      'fast'    => 'Fasting check-in',
      'com'     => 'Commute block',
      _         => 'Schedule block',
    };
  }

  Color _categoryColor(String key) {
    return switch (key) {
      'deen'    => const Color(0xFF54C478),
      'learn'   => const Color(0xFF6A8EF0),
      'project' => const Color(0xFFAA70EE),
      'health'  => const Color(0xFFD07848),
      'work'    => const Color(0xFFC09840),
      _         => const Color(0xFFC8A050),
    };
  }
}
