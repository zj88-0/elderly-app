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
final List<StreamSubscription> _bgFirestoreSubs = [];

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
      // FIX: autoStart to false so caregivers are not monitored.
      // Actual tracking is kicked off explicitly in main.dart.
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'eldercare_background',
      initialNotificationTitle: 'ElderCare SG',
      initialNotificationContent: 'Monitoring check-ins in background...',
      foregroundServiceNotificationId: 888,
      // FIX: Declare the foreground service type so Android 14+ allows
      // sensor access while the service runs in the background.
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
      // FIX: Restart automatically if the OS kills the service (depends on Android config).
      autoStartOnBoot: true,
    ),
    // FIX: iOS requires both onForeground AND onBackground handlers.
    // Without onBackground the service stops as soon as the app is closed.
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onServiceStart,
      onBackground: onIosBackground,
    ),
  );
}

// ── iOS background handler (REQUIRED — app-closed survival on iOS) ─────────
// This function is called by the plugin in a separate Dart isolate when the
// iOS app moves to the background. It must return true to keep the service
// running. Without it the service is terminated on app close.
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// ── Background entry point ─────────────────────────────────────────────────
@pragma('vm:entry-point')
void onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  try {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {}

  if (service is AndroidServiceInstance) {
    service
        .on('setAsForeground')
        .listen((_) => service.setAsForegroundService());
    service
        .on('setAsBackground')
        .listen((_) => service.setAsBackgroundService());

    // FIX: Immediately promote to foreground so the OS cannot kill it when
    // the app is swiped away. The persistent notification is the trade-off
    // Android requires for uninterrupted background execution.
    service.setAsForegroundService();
  }
  service.on('stopService').listen((_) => service.stopSelf());
  service.on('updateListeners').listen((_) {
    _startFirestoreListeners();
  });

  // FIX: Re-initialise local notifications inside the background isolate.
  // The plugin runs in a separate Dart isolate and has its own plugin
  // registry; it must be initialised here or show() calls will silently fail.
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  await notificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
  );

  // Create all notification channels inside the isolate.
  final android = notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'eldercare_reminder', 'Activity Reminder',
      importance: Importance.high,
    ),
  );
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'eldercare_messages', 'Messages',
      description: 'In-app messages between group members.',
      importance: Importance.high,
    ),
  );
  await android?.createNotificationChannel(
    const AndroidNotificationChannel(
      'eldercare_sos', 'SOS Alerts',
      description: 'Critical SOS alerts.',
      importance: Importance.max,
    ),
  );

  // Start Firestore listeners in the background isolate so messages and SOS
  // notifications arrive even when the app is completely closed.
  await _startFirestoreListeners();

  final Screen _screen = Screen();

  _screen.screenStateStream?.listen((ScreenStateEvent event) async {
    final prefs = await SharedPreferences.getInstance();

    if (event == ScreenStateEvent.SCREEN_OFF) {
      await prefs.setBool('screen_was_off_persist', true);
    } else if (event == ScreenStateEvent.SCREEN_ON) {
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

  final isElderly = (await SharedPreferences.getInstance()).getBool('isElderlyUser') ?? false;

  if (isElderly) {
    try {
      accelSub =
          accelerometerEventStream(samplingPeriod: SensorInterval.normalInterval)
              .listen((event) async {
        final magnitude =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

        if (magnitude > _stepThreshold && !_stepPeak) {
          _stepPeak = true;
          _stepCandidates++;
          if (_stepCandidates >= 50) {
            _stepCandidates = 0;
            final elderlyId = (await SharedPreferences.getInstance())
                .getString('currentElderlyId');
            if (elderlyId != null) {
              await _recordBackgroundCheckIn(service, elderlyId, 'stepsActive',
                  meta: {'steps': 50});
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

      gyroSub =
          gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval)
              .listen((event) {
        _lastGyroMagnitude =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      });
    } catch (_) {}
  }

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

    if (isElderly) {
      if (_pickupCandidateCount >= 3 && _lastGyroMagnitude > 0.5) {
        final elderlyId =
            (await SharedPreferences.getInstance()).getString('currentElderlyId');
        if (elderlyId != null) {
          await _recordBackgroundCheckIn(service, elderlyId, 'phonePickup');
        }
        _pickupCandidateCount = 0;
      }

      await _checkInactivityWindow();
    }
  });
}

// ── Firestore listeners (run inside background isolate) ────────────────────
// Sets up message and SOS listeners so notifications fire when app is closed.
Future<void> _startFirestoreListeners() async {
  for (final sub in _bgFirestoreSubs) {
    sub.cancel();
  }
  _bgFirestoreSubs.clear();

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('currentUserId') ?? '';
  final userRole = prefs.getString('currentUserRole') ?? '';
  final groupsStr = prefs.getString('bgGroups') ?? '[]';
  final userNamesStr = prefs.getString('bgUserNames') ?? '{}';

  if (userId.isEmpty) return; // Not logged in yet — skip

  List<Map<String, dynamic>> groups = [];
  Map<String, String> userNames = {};
  try {
    final decodedGroups = jsonDecode(groupsStr) as List;
    for (var g in decodedGroups) {
      if (g is Map) groups.add(Map<String, dynamic>.from(g));
    }

    final decodedNames = jsonDecode(userNamesStr) as Map;
    for (var entry in decodedNames.entries) {
      userNames[entry.key.toString()] = entry.value.toString();
    }
  } catch (e) {
    return;
  }

  // Per-group unread counts tracked inside this isolate.
  final unreadCounts = <String, int>{}; // groupId -> last known count

  // ── Message notifications (all users — incoming messages only) ──────────
  for (final group in groups) {
    final groupId = group['id'] as String? ?? '';
    final members = List<String>.from(group['allMemberIds'] as List? ?? []);
    final otherId =
        members.firstWhere((id) => id != userId, orElse: () => '');
    if (groupId.isEmpty || otherId.isEmpty) continue;

    final msgSub = FirebaseFirestore.instance
        .collection('messages')
        .doc(groupId)
        .collection('unread')
        .doc(userId)
        .snapshots()
        .listen((snap) async {
      final newCount =
          snap.exists ? ((snap.data()?['count'] as int?) ?? 0) : 0;

      // First snapshot — seed baseline without notifying.
      if (!unreadCounts.containsKey(groupId)) {
        unreadCounts[groupId] = newCount;
        return;
      }

      final prevCount = unreadCounts[groupId] ?? 0;
      unreadCounts[groupId] = newCount;
      if (newCount <= prevCount) return; // count went down (read) — skip

      // Only fire from background service when main app is NOT in foreground.
      final freshPrefs = await SharedPreferences.getInstance();
      final isAppFg = freshPrefs.getBool('isAppForeground') ?? false;
      final heartbeat = freshPrefs.getInt('appHeartbeat') ?? 0;
      final msSinceHeartbeat = DateTime.now().millisecondsSinceEpoch - heartbeat;
      final isActuallyForeground = isAppFg && msSinceHeartbeat < 6000;
      
      if (isActuallyForeground) return; // Main app DataService handles it when foregrounded.

      // Fetch latest message to confirm sender is NOT this user.
      try {
        final msgSnap = await FirebaseFirestore.instance
            .collection('messages')
            .doc(groupId)
            .collection('msgs')
            .orderBy('sentAt', descending: true)
            .limit(1)
            .get();
        if (msgSnap.docs.isEmpty) return;
        final data = msgSnap.docs.first.data();
        final senderId = data['senderId'] as String? ?? '';
        if (senderId == userId) return; // Never notify sender.

        final senderName = userNames[senderId] ?? userNames[otherId] ?? 'Someone';
        final text = data['text'] as String? ?? 'New message';
        await _showBgMessageNotification(
            senderName: senderName, message: text);
      } catch (_) {}
    });
    _bgFirestoreSubs.add(msgSub);
  }

  // ── SOS notifications (caregiver only) ─────────────────────────────────
  if (userRole == 'caregiver') {
    final elderlyIds = groups
        .map((g) => g['elderlyId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (elderlyIds.isNotEmpty) {
      final knownSosIds = <String>{};
      bool isFirstLoad = true;

      final sosSub = FirebaseFirestore.instance
          .collection('sos')
          .where('elderlyId', whereIn: elderlyIds.take(30).toList())
          .snapshots()
          .listen((snap) async {
        for (final doc in snap.docs) {
          final sosId = doc.id;
          final status = doc.data()['status'] as String? ?? '';
          final elderlyId = doc.data()['elderlyId'] as String? ?? '';
          final description = doc.data()['description'] as String? ?? '';

          if (status == 'active' &&
              !isFirstLoad &&
              !knownSosIds.contains(sosId)) {
            final elderlyName = userNames[elderlyId] ?? 'Elderly member';
            await _showBgSosNotification(
                elderlyName: elderlyName, description: description);
          }
          knownSosIds.add(sosId);
        }
        isFirstLoad = false;
      });
      _bgFirestoreSubs.add(sosSub);
    }
  }
}

Future<void> _showBgMessageNotification({
  required String senderName,
  required String message,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'eldercare_messages', 'Messages',
    channelDescription: 'In-app messages between group members.',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true, presentBadge: true, presentSound: true,
  );
  await FlutterLocalNotificationsPlugin().show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Message from $senderName',
    message,
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}

Future<void> _showBgSosNotification({
  required String elderlyName,
  required String description,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'eldercare_sos', 'SOS Alerts',
    channelDescription: 'Critical SOS alerts from your elderly members.',
    importance: Importance.max,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails(
    presentAlert: true, presentBadge: true, presentSound: true,
  );
  await FlutterLocalNotificationsPlugin().show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'SOS from $elderlyName',
    description.isNotEmpty ? description : 'Your elderly member needs help!',
    const NotificationDetails(android: androidDetails, iOS: iosDetails),
  );
}

// ── Record Function ────────────────────────────────────────────────────────
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
          final elderlyName =
              prefs.getString('currentElderlyName') ?? 'Elderly';
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
            await _updateFirestoreSummary(elderlyId,
                elderlyNotified: true, caregiverNotified: true);
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Background window error: $e');
  }
}

Future<void> _updateFirestoreSummary(String elderlyId,
    {bool elderlyNotified = false,
    bool caregiverNotified = false,
    bool reset = false,
    String? checkInType}) async {
  try {
    final docRef =
        FirebaseFirestore.instance.collection('checkin_summary').doc(elderlyId);
    if (reset) {
      final data = <String, dynamic>{
        'lastActivity': FieldValue.serverTimestamp(),
        'elderlyNotified': false,
        'caregiverNotified': false,
      };
      if (checkInType != null) {
        final nowIso = DateTime.now().toIso8601String();
        if (checkInType == 'phoneUnlock') data['lastPhoneUnlock'] = nowIso;
        if (checkInType == 'stepsActive') data['lastSteps'] = nowIso;
        if (checkInType == 'phonePickup') data['lastPickup'] = nowIso;
      }
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
    'eldercare_reminder',
    'Activity Reminder',
    importance: Importance.high,
    priority: Priority.high,
  );
  await plugin.show(
    999,
    'Are you OK, $name?',
    'Please tap the app to let your family know.',
    const NotificationDetails(android: androidDetails),
  );
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
        ac['nextCheckDue'] = DateTime.now()
            .add(Duration(hours: intervalHours))
            .toIso8601String();
        ac['elderlyNotified'] = false;
        ac['caregiverNotified'] = false;
        await prefs.setString('activityChecks', jsonEncode(acMap));
        await _updateFirestoreSummary(elderlyId,
            reset: true, checkInType: type);
      }
    } catch (_) {}
  }
}

class BackgroundServiceHelper {
  static Future<void> startService(String userId, String name, bool isElderly) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentUserId', userId);
    await prefs.setString('currentUserRole', isElderly ? 'elderly' : 'caregiver');
    await prefs.setBool('isElderlyUser', isElderly);
    if (isElderly) {
      await prefs.setString('currentElderlyId', userId);
      await prefs.setString('currentElderlyName', name);
    }
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
