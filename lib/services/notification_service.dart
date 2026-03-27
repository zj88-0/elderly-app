// lib/services/notification_service.dart
// Enhanced with inactivity alert for caregivers.

import 'package:flutter/material.dart' show Color;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/data_service.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _sosChannel =
      AndroidNotificationChannel(
    'eldercare_sos',
    'SOS Alerts',
    description: 'Critical SOS alerts from your elderly members.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static const AndroidNotificationChannel _messagesChannel =
      AndroidNotificationChannel(
    'eldercare_messages',
    'Messages',
    description: 'In-app messages between group members.',
    importance: Importance.high,
    playSound: true,
  );

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);

    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_sosChannel);
    await android?.createNotificationChannel(_messagesChannel);
  }

  static Future<void> requestPermissions() async {
    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
      
      // Request battery optimization ignore so background tracking continues when phone is locked
      if (await Permission.ignoreBatteryOptimizations.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    }

    // Request permissions for iOS
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
  }

  static Future<void> showSosNotification({
    required String elderlyName,
    required String description,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'eldercare_sos',
      'SOS Alerts',
      channelDescription: 'Critical SOS alerts from your elderly members.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'SOS Alert',
      color: Color(0xFFD32F2F),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'SOS from $elderlyName',
      description.isNotEmpty ? description : 'Your elderly member needs help!',
      details,
    );
  }

  static Future<void> showCheckInNotification(String elderlyName) async {
    const androidDetails = AndroidNotificationDetails(
      'eldercare_checkin',
      'Check-in Alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Check-in',
      '$elderlyName has checked in.',
      details,
    );
  }

  static Future<void> showMessageNotification({
    required String senderName,
    required String message,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'eldercare_messages',
      'Messages',
      channelDescription: 'In-app messages between group members.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Message from $senderName',
      message,
      details,
    );
  }

  /// Notify caregivers when elderly shows no activity in 5-hour window
  static Future<void> showInactivityAlertForCaregivers({
    required String elderlyId,
    required DataService dataService,
  }) async {
    final elderly = dataService.getUserById(elderlyId);
    if (elderly == null) return;

    const androidDetails = AndroidNotificationDetails(
      'eldercare_inactivity',
      'Inactivity Alerts',
      channelDescription: 'Alert when elderly has no activity for 5 hours.',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFE65100),
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'No activity: ${elderly.name}',
      '${elderly.name} has shown no phone activity for 5+ hours. Please check on them.',
      details,
    );
  }

  /// Remind elderly to check in
  static Future<void> showElderlyInactivityReminder(String elderlyName) async {
    const androidDetails = AndroidNotificationDetails(
      'eldercare_reminder',
      'Activity Reminder',
      channelDescription: 'Reminder to check in.',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Are you OK, $elderlyName?',
      'Please tap the app to let your family know you are fine.',
      details,
    );
  }
}
