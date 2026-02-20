import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notifications.initialize(initSettings);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> showOldFilesNotification({required int fileCount, required String totalSize}) async {
    const androidDetails = AndroidNotificationDetails(
      'old_files_channel',
      'Old Files Notifications',
      channelDescription: 'Notifications about old files',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifications.show(
      0,
      'Old Files Found',
      'You have $fileCount files older than 6 months ($totalSize)',
      details,
    );
  }
}
