// lib/services/background_service.dart

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screen_state/screen_state.dart';
import '../firebase_options.dart';

const _uuid = Uuid();

// ── Notification channel ───────────────────────────────────────────────────
const AndroidNotificationChannel backgroundChannel = AndroidNotificationChannel(
  'eldercare_background',
  'ElderCare Background Service',
  description: 'Tracks phone activity to log check-ins automatically.',
  importance: Importance.low,
);

// ── Initialise background service ─────────────────────────────────────────
Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  await notificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(backgroundChannel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'eldercare_background',
      initialNotificationTitle: 'ElderCare SG',
      initialNotificationContent: 'Monitoring check-ins in background...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onServiceStart,
    ),
  );
}

// ── Background entry point ─────────────────────────────────────────────────
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) => service.setAsForegroundService());
    service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
  }
  service.on('stopService').listen((_) => service.stopSelf());

  final Screen _screen = Screen();

  _screen.screenStateStream?.listen((ScreenStateEvent event) async {
    final prefs = await SharedPreferences.getInstance();

    if (event == ScreenStateEvent.SCREEN_OFF) {
      await prefs.setBool('screen_was_off_persist', true);
    }
    else if (event == ScreenStateEvent.SCREEN_ON) {
      final wasOff = prefs.getBool('screen_was_off_persist') ?? false;

      // This identifies the physical UNLOCK/WAKE event
      if (wasOff) {
        await prefs.setBool('screen_was_off_persist', false);
        final elderlyId = prefs.getString('currentElderlyId');
        if (elderlyId != null) {
          // Use the specific record function for screen events
          await _recordBackgroundCheckIn(service, elderlyId, 'phoneUnlock');
        }
      }
    }
  });

  double _lastAccelMagnitude = 0;
  double _lastGyroMagnitude = 0;
  int _pickupCandidateCount = 0;
  int _stepCandidates = 0;
  double _stepThreshold = 12.0;
  bool _stepPeak = false;

  StreamSubscription<AccelerometerEvent>? accelSub;
  StreamSubscription<GyroscopeEvent>? gyroSub;

  try {
    accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval)
        .listen((event) async {
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (magnitude > _stepThreshold && !_stepPeak) {
        _stepPeak = true;
        _stepCandidates++;
        if (_stepCandidates >= 50) {
          _stepCandidates = 0;
          final elderlyId = (await SharedPreferences.getInstance()).getString('currentElderlyId');
          if (elderlyId != null) {
            await _recordBackgroundCheckIn(service, elderlyId, 'stepsActive', meta: {'steps': 50});
          }
        }
      } else if (magnitude < _stepThreshold - 2) {
        _stepPeak = false;
      }

      final delta = (magnitude - _lastAccelMagnitude).abs();
      if (delta > 8.0) {
        _pickupCandidateCount++;
      } else if (delta < 1.0 && _pickupCandidateCount > 0) {
        _pickupCandidateCount = (_pickupCandidateCount - 1).clamp(0, 100);
      }
      _lastAccelMagnitude = magnitude;
    });

    gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval)
        .listen((event) {
      _lastGyroMagnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    });
  } catch (_) {}

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (service is AndroidServiceInstance) {
      final isRunning = await service.isForegroundService();
      if (!isRunning) {
        timer.cancel();
        accelSub?.cancel();
        gyroSub?.cancel();
        return;
      }
    }

    if (_pickupCandidateCount >= 3 && _lastGyroMagnitude > 0.5) {
      final elderlyId = (await SharedPreferences.getInstance()).getString('currentElderlyId');
      if (elderlyId != null) {
        await _recordBackgroundCheckIn(service, elderlyId, 'phonePickup');
      }
      _pickupCandidateCount = 0;
    }

    await _checkInactivityWindow();
  });
}

// ── NEW: Missing Record Function ───────────────────────────────────────────
/// Corrects the "failing" issue by using a shorter cooldown (5 mins)
/// and ensuring background data is queued for the UI to consume.
Future<void> _recordBackgroundCheckIn(
    ServiceInstance service,
    String elderlyId,
    String type, {
      Map<String, dynamic>? meta,
    }) async {
  final prefs = await SharedPreferences.getInstance();

  // Rate-limit logic: Use 5 minutes so it doesn't "fail" during testing
  final lastKey = 'last_bg_checkin_$type';
  final lastTimeStr = prefs.getString(lastKey);

  if (lastTimeStr != null) {
    final lastTime = DateTime.parse(lastTimeStr);
    if (DateTime.now().difference(lastTime).inMinutes < 5) return;
  }

  await prefs.setString(lastKey, DateTime.now().toIso8601String());

  // Add to the queue that BackgroundServiceHelper.consumePendingCheckIns() reads
  final queue = prefs.getStringList('pendingUnlockCheckIns') ?? [];
  queue.add(jsonEncode({
    'id': _uuid.v4(),
    'elderlyId': elderlyId,
    'type': type,
    'timestamp': DateTime.now().toIso8601String(),
    'meta': meta,
  }));

  await prefs.setStringList('pendingUnlockCheckIns', queue);

  // Reset the inactivity window locally and update Firestore directly
  await _resetActivityWindow(type: type);
}

Future<void> _checkInactivityWindow() async {
  final prefs = await SharedPreferences.getInstance();
  final elderlyId = prefs.getString('currentElderlyId');
  if (elderlyId == null) return;

  final acStr = prefs.getString('activityChecks');
  if (acStr == null) return;
  final isAppForeground = prefs.getBool('isAppForeground') ?? false;

  try {
    final acMap = jsonDecode(acStr) as Map<String, dynamic>;
    if (!acMap.containsKey(elderlyId)) return;
    final ac = acMap[elderlyId] as Map<String, dynamic>;

    final enabled = ac['autoCheckInEnabled'] as bool? ?? true;
    if (!enabled) return;

    final nextCheckDueStr = ac['nextCheckDue'] as String?;
    if (nextCheckDueStr == null) return;
    final nextCheckDue = DateTime.parse(nextCheckDueStr);

    final startH = ac['sleepStartHour'] as int?;
    final endH = ac['sleepEndHour'] as int?;
    if (startH != null && endH != null) {
      if (_isInSleepWindow(startH, endH)) return;
    }

    final now = DateTime.now();
    if (now.isAfter(nextCheckDue)) {
      final notified = ac['elderlyNotified'] as bool? ?? false;
      if (!notified) {
        if (!isAppForeground) {
          final elderlyName = prefs.getString('currentElderlyName') ?? 'Elderly';
          await _showAreYouOkNotification(elderlyName);
          ac['elderlyNotified'] = true;
          await prefs.setString('activityChecks', jsonEncode(acMap));
          await _updateFirestoreSummary(elderlyId, elderlyNotified: true);
        }
      } else {
        final cgNotified = ac['caregiverNotified'] as bool? ?? false;
        if (!cgNotified) {
          if (now.difference(nextCheckDue).inMinutes >= 60) {
            ac['caregiverNotified'] = true;
            await prefs.setString('activityChecks', jsonEncode(acMap));
            await _updateFirestoreSummary(elderlyId, elderlyNotified: true, caregiverNotified: true);
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Background window error: $e');
  }
}

Future<void> _updateFirestoreSummary(String elderlyId,
    {bool elderlyNotified = false, bool caregiverNotified = false, bool reset = false, String? checkInType}) async {
  try {
    final docRef = FirebaseFirestore.instance.collection('checkin_summary').doc(elderlyId);
    if (reset) {
      final data = <String, dynamic>{
        'lastActivity': FieldValue.serverTimestamp(),
        'elderlyNotified': false,
        'caregiverNotified': false,
      };
      // Send the specific activity timestamp so caregivers see it immediately
      if (checkInType != null) {
        final nowIso = DateTime.now().toIso8601String();
        if (checkInType == 'phoneUnlock') data['lastPhoneUnlock'] = nowIso;
        if (checkInType == 'stepsActive') data['lastSteps'] = nowIso;
        if (checkInType == 'phonePickup') data['lastPickup'] = nowIso;
      }
      // Use set with merge in case the document doesn't exist yet
      await docRef.set(data, SetOptions(merge: true));
    } else {
      await docRef.update({
        'elderlyNotified': elderlyNotified,
        'caregiverNotified': caregiverNotified,
      });
    }
  } catch (_) {}
}

bool _isInSleepWindow(int start, int end) {
  final now = DateTime.now().hour;
  if (start <= end) return now >= start && now < end;
  return now >= start || now < end;
}

Future<void> _showAreYouOkNotification(String name) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidDetails = AndroidNotificationDetails(
    'eldercare_reminder', 'Activity Reminder',
    importance: Importance.high, priority: Priority.high,
  );
  await plugin.show(999, 'Are you OK, $name?', 'Please tap the app to let your family know.', const NotificationDetails(android: androidDetails));
}

Future<void> _resetActivityWindow({String? type}) async {
  final prefs = await SharedPreferences.getInstance();
  final elderlyId = prefs.getString('currentElderlyId');
  if (elderlyId == null) return;

  final acStr = prefs.getString('activityChecks');
  if (acStr != null) {
    try {
      final acMap = jsonDecode(acStr) as Map<String, dynamic>;
      if (acMap.containsKey(elderlyId)) {
        final ac = acMap[elderlyId] as Map<String, dynamic>;
        final intervalHours = ac['checkInIntervalHours'] as int? ?? 10;
        ac['nextCheckDue'] = DateTime.now().add(Duration(hours: intervalHours)).toIso8601String();
        ac['elderlyNotified'] = false;
        ac['caregiverNotified'] = false;
        await prefs.setString('activityChecks', jsonEncode(acMap));
        await _updateFirestoreSummary(elderlyId, reset: true, checkInType: type);
      }
    } catch (_) {}
  }
}

class BackgroundServiceHelper {
  static Future<void> startForElderly(String elderlyId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentElderlyId', elderlyId);
    await prefs.setString('currentElderlyName', name);
    final service = FlutterBackgroundService();
    if (!(await service.isRunning())) await service.startService();
  }

  static Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentElderlyId');
    FlutterBackgroundService().invoke('stopService');
  }

  static Future<List<Map<String, dynamic>>> consumePendingCheckIns() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pendingUnlockCheckIns') ?? [];
    if (queue.isEmpty) return [];
    await prefs.remove('pendingUnlockCheckIns');
    return queue.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
}