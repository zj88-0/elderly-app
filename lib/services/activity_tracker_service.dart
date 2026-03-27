// lib/services/activity_tracker_service.dart
//
// ── Phone Unlock ────────────────────────────────────────────────────────────
// Detected via WidgetsBindingObserver.didChangeAppLifecycleState (resumed).
// Rate-limited to once per 5 minutes. Background-queued unlocks consumed
// via consumePendingCheckIns() on every resume.
//
// ── Steps ──────────────────────────────────────────────────────────────────
// Hardware pedometer (50-step threshold) with accelerometer fallback.
//
// ── Phone Pickup ───────────────────────────────────────────────────────────
// Two signals must both fire within a 3-second window:
//   1. Tilt CHANGE — gravity vector changes by >15° (not absolute angle check).
//      Filter alpha 0.7 for fast response. _tiltRising flag removed (unused).
//   2. Sustained gyro rotation — rolling 600ms window average > 0.4 rad/s.
//      Individual spikes >6.0 rad/s are SKIPPED (not window-cleared).
// Cooldown: 10 seconds (for testability; raise to 60s in production).
//
// ── Session / 5-hour window ─────────────────────────────────────────────────
// After any check-in fires, tracking continues uninterrupted.
// The 5-hour inactivity window is managed by DataService/ActivityCheckModel.
// Sensors run continuously; signals are simply rate-limited via cooldowns
// so they don't flood the DB. When the 5-hour window resets (new activity),
// DataService.updateActivitySignal resets nextCheckDue automatically.

import 'dart:async';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/data_service.dart';
import '../models/checkin_model.dart';

class ActivityTrackerService with WidgetsBindingObserver {
  // Singleton instance required for WidgetsBindingObserver
  static final ActivityTrackerService _instance = ActivityTrackerService._internal();
  ActivityTrackerService._internal();

  static DataService? _ds;
  static String? _elderlyId;

  // ── Pedometer ──────────────────────────────────────────────────────────
  static StreamSubscription<StepCount>? _stepSub;
  static StreamSubscription<PedestrianStatus>? _pedestrianSub;

  // ── Accelerometer fallback for steps ──────────────────────────────────
  static StreamSubscription<AccelerometerEvent>? _accelStepSub;
  static int _accelStepCandidates = 0;
  static bool _accelStepPeak = false;
  static double _gravX = 0, _gravY = 0, _gravZ = 0;
  static const double _lpAlpha = 0.85;

  // ── Phone pickup — tilt change + sustained gyro ───────────────────────
  static StreamSubscription<AccelerometerEvent>? _accelPickupSub;
  static StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Gravity vector (low-pass filtered, alpha 0.7 for faster response)
  static double _pgX = 0, _pgY = 0, _pgZ = 0;
  static const double _pgAlpha = 0.7; // FIX: was 0.9 (too slow)

  // Tilt: track angle and detect CHANGE (not absolute threshold)
  static double _lastTiltAngle = -1; // -1 = not yet initialised

  // Gyro rolling window
  static final List<_GyroSample> _gyroWindow = [];
  static const Duration _gyroWindowDur = Duration(milliseconds: 600);
  static const double _gyroSustainedMin = 0.4;  // FIX: was 0.8 (too high)
  static const double _gyroSpikeIgnore  = 6.0;  // FIX: skip spike, don't clear window

  // Confirmation: both signals within 3s
  static DateTime? _tiltSignalTime;
  static DateTime? _gyroSignalTime;
  static const Duration _confirmWindow = Duration(seconds: 3); // FIX: was 2s

  // Cooldown: 10s for easy testing, raise to 60s for production
  static DateTime? _lastPickupTime;
  static const Duration _pickupCooldown = Duration(seconds: 10); // FIX: was 60s

  // ── 5-hour check timer ─────────────────────────────────────────────────
  static Timer? _checkTimer;
  static const int _stepsTarget = 50;

  // ── Step cooldown: prevent flooding DB with rapid step events ─────────
  static DateTime? _lastStepCheckIn;
  static const Duration _stepCooldown = Duration(minutes: 5);

  // ────────────────────────────────────────────────────────────────────────
  static void startTracking({
    required String elderlyId,
    required DataService dataService,
    required VoidCallback onElderlyAlert,
  }) {
    _ds = dataService;
    _elderlyId = elderlyId;

    // Register observer to sync background data (like unlocks) when app opens
    WidgetsBinding.instance.addObserver(_instance);

    _startPedometerTracking(elderlyId, dataService);
    _startPickupTracking(elderlyId, dataService);

    _checkTimer = Timer.periodic(const Duration(minutes: 10), (_) async {
      await _runWindowCheck(
        elderlyId: elderlyId,
        dataService: dataService,
        onElderlyAlert: onElderlyAlert,
      );
    });
  }

  /// Lifecycle: trigger queue consumption on app resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ds?.handleAppResume();
      final elderlyId = _elderlyId;
      if (_ds != null && elderlyId != null) {
        _ds!.createCheckIn(
          elderlyId: elderlyId,
          type: CheckInType.phoneUnlock,
          meta: {'source': 'app_resume'},
        );
      }
    }
  }

  // ── Pedometer ─────────────────────────────────────────────────────────
  static void _startPedometerTracking(
      String elderlyId, DataService dataService) {
    try {
      _stepSub = Pedometer.stepCountStream.listen(
            (StepCount event) async {
          final prefs = await SharedPreferences.getInstance();
          int savedBaseline = prefs.getInt('step_baseline') ?? 0;

          if (savedBaseline == 0) {
            await prefs.setInt('step_baseline', event.steps);
            return;
          }
          final delta = event.steps - savedBaseline;

          if (delta >= _stepsTarget && delta < 5000) {
            final now = DateTime.now();
            if (_lastStepCheckIn != null &&
                now.difference(_lastStepCheckIn!) < _stepCooldown) {
              await prefs.setInt('step_baseline', event.steps);
              return;
            }
            await prefs.setInt('step_baseline', event.steps);
            _lastStepCheckIn = now;
            await dataService.createCheckIn(
              elderlyId: elderlyId,
              type: CheckInType.stepsActive,
              meta: {'steps': delta, 'source': 'pedometer'},
            );
          } else if (delta < 0) {
            await prefs.setInt('step_baseline', event.steps);
          }
        },
        onError: (_) => _startAccelStepFallback(elderlyId, dataService),
      );
      _pedestrianSub = Pedometer.pedestrianStatusStream.listen(
            (_) {},
        onError: (_) {},
      );
    } catch (_) {
      _startAccelStepFallback(elderlyId, dataService);
    }
  }

  static void _startAccelStepFallback(
      String elderlyId, DataService dataService) {
    try {
      _accelStepSub = accelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval)
          .listen((event) async {
        _gravX = _lpAlpha * _gravX + (1 - _lpAlpha) * event.x;
        _gravY = _lpAlpha * _gravY + (1 - _lpAlpha) * event.y;
        _gravZ = _lpAlpha * _gravZ + (1 - _lpAlpha) * event.z;
        final linX = event.x - _gravX;
        final linY = event.y - _gravY;
        final linZ = event.z - _gravZ;
        final linearMag = sqrt(linX * linX + linY * linY + linZ * linZ);
        if (linearMag > 2.0 && !_accelStepPeak) {
          _accelStepPeak = true;
          _accelStepCandidates++;
          if (_accelStepCandidates >= _stepsTarget) {
            final now = DateTime.now();
            if (_lastStepCheckIn == null ||
                now.difference(_lastStepCheckIn!) >= _stepCooldown) {
              _accelStepCandidates = 0;
              _lastStepCheckIn = now;
              await dataService.createCheckIn(
                elderlyId: elderlyId,
                type: CheckInType.stepsActive,
                meta: {'steps': _stepsTarget, 'source': 'accelerometer'},
              );
            } else {
              _accelStepCandidates = 0;
            }
          }
        } else if (linearMag < 0.8) {
          _accelStepPeak = false;
        }
      });
    } catch (_) {}
  }

  // ── Phone pickup ──────────────────────────────────────────────────────
  static void _startPickupTracking(
      String elderlyId, DataService dataService) {
    try {
      _accelPickupSub = accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval)
          .listen((event) async {
        _pgX = _pgAlpha * _pgX + (1 - _pgAlpha) * event.x;
        _pgY = _pgAlpha * _pgY + (1 - _pgAlpha) * event.y;
        _pgZ = _pgAlpha * _pgZ + (1 - _pgAlpha) * event.z;

        final gravMag = sqrt(_pgX * _pgX + _pgY * _pgY + _pgZ * _pgZ);
        if (gravMag < 3.0) return;

        final cosAngle = (_pgZ / gravMag).clamp(-1.0, 1.0);
        final tiltDeg = acos(cosAngle) * 180 / pi;

        if (_lastTiltAngle < 0) {
          _lastTiltAngle = tiltDeg;
          return;
        }

        final tiltDelta = tiltDeg - _lastTiltAngle;
        if (tiltDelta > 15) {
          _tiltSignalTime = DateTime.now();
          await _checkPickupConfirmation(elderlyId, dataService);
        }

        _lastTiltAngle = tiltDeg;
      });

      _gyroSub = gyroscopeEventStream(
          samplingPeriod: SensorInterval.uiInterval)
          .listen((event) async {
        final rotMag =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

        if (rotMag > _gyroSpikeIgnore) return;

        final now = DateTime.now();
        _gyroWindow.add(_GyroSample(time: now, magnitude: rotMag));

        _gyroWindow.removeWhere(
                (s) => now.difference(s.time) > _gyroWindowDur);

        if (_gyroWindow.isEmpty) return;

        final avgRot = _gyroWindow
            .map((s) => s.magnitude)
            .reduce((a, b) => a + b) /
            _gyroWindow.length;

        if (avgRot > _gyroSustainedMin) {
          _gyroSignalTime = now;
          await _checkPickupConfirmation(elderlyId, dataService);
        }
      });
    } catch (_) {
      // Sensors not available
    }
  }

  static Future<void> _checkPickupConfirmation(
      String elderlyId, DataService dataService) async {
    if (_tiltSignalTime == null || _gyroSignalTime == null) return;

    final gap = (_tiltSignalTime!.difference(_gyroSignalTime!)).abs();
    if (gap > _confirmWindow) return;

    if (_lastPickupTime != null &&
        DateTime.now().difference(_lastPickupTime!) < _pickupCooldown) {
      return;
    }

    _tiltSignalTime = null;
    _gyroSignalTime = null;
    _lastPickupTime = DateTime.now();
    _gyroWindow.clear();
    _lastTiltAngle = -1;

    await dataService.createCheckIn(
      elderlyId: elderlyId,
      type: CheckInType.phonePickup,
    );
  }

  // ── 5-hour window check ────────────────────────────────────────────────
  static Future<void> _runWindowCheck({
    required String elderlyId,
    required DataService dataService,
    required VoidCallback onElderlyAlert,
  }) async {
    final ac = dataService.getActivityCheck(elderlyId);
    if (ac == null) return;
    if (ac.isInSleepWindow()) return;
    if (ac.hasActivityInWindow()) return;

    if (!ac.elderlyNotified) {
      await dataService.markElderlyNotified(elderlyId);
      onElderlyAlert();
    } else if (!ac.caregiverNotified) {
      await dataService.runActivityCheck(elderlyId);
    }
  }

  static void dispose() {
    WidgetsBinding.instance.removeObserver(_instance);
    _ds = null;
    _elderlyId = null;
    _stepSub?.cancel();
    _pedestrianSub?.cancel();
    _accelStepSub?.cancel();
    _accelPickupSub?.cancel();
    _gyroSub?.cancel();
    _checkTimer?.cancel();
    _stepSub = null;
    _pedestrianSub = null;
    _accelStepSub = null;
    _accelPickupSub = null;
    _gyroSub = null;
    _checkTimer = null;
    _accelStepCandidates = 0;
    _accelStepPeak = false;
    _gravX = 0; _gravY = 0; _gravZ = 0;
    _pgX = 0; _pgY = 0; _pgZ = 0;
    _lastTiltAngle = -1;
    _gyroWindow.clear();
    _tiltSignalTime = null;
    _gyroSignalTime = null;
    _lastPickupTime = null;
    _lastStepCheckIn = null;
  }
}

// Rolling window sample for gyroscope
class _GyroSample {
  final DateTime time;
  final double magnitude;
  const _GyroSample({required this.time, required this.magnitude});
}