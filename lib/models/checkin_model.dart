// lib/models/checkin_model.dart

enum CheckInType { manual, phoneUnlock, stepsActive, phonePickup }

class CheckInModel {
  final String id;
  final String elderlyId;
  final CheckInType type;
  final DateTime timestamp;
  final Map<String, dynamic>? meta;

  CheckInModel({
    required this.id,
    required this.elderlyId,
    required this.type,
    DateTime? timestamp,
    this.meta,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'elderlyId': elderlyId,
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'meta': meta,
      };

  factory CheckInModel.fromJson(Map<String, dynamic> json) => CheckInModel(
        id: json['id'],
        elderlyId: json['elderlyId'],
        type: CheckInType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => CheckInType.manual,
        ),
        timestamp: DateTime.parse(json['timestamp']),
        meta: json['meta'] != null
            ? Map<String, dynamic>.from(json['meta'])
            : null,
      );
}

// ─── SosModel ──────────────────────────────────────────────────────────────

enum SosStatus { active, resolved }

class SosModel {
  final String id;
  final String elderlyId;
  String description;
  SosStatus status;
  final DateTime triggeredAt;
  DateTime? resolvedAt;

  SosModel({
    required this.id,
    required this.elderlyId,
    required this.description,
    this.status = SosStatus.active,
    DateTime? triggeredAt,
    this.resolvedAt,
  }) : triggeredAt = triggeredAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'elderlyId': elderlyId,
        'description': description,
        'status': status.name,
        'triggeredAt': triggeredAt.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  factory SosModel.fromJson(Map<String, dynamic> json) => SosModel(
        id: json['id'],
        elderlyId: json['elderlyId'],
        description: json['description'],
        status: SosStatus.values.firstWhere((s) => s.name == json['status']),
        triggeredAt: DateTime.parse(json['triggeredAt']),
        resolvedAt: json['resolvedAt'] != null
            ? DateTime.parse(json['resolvedAt'])
            : null,
      );
}

// ─── ActivityCheckModel ─────────────────────────────────────────────────────

class ActivityCheckModel {
  final String elderlyId;
  DateTime? lastPhoneUnlock;
  DateTime? lastStepsActive;
  DateTime? lastPhonePickup;
  DateTime? nextCheckDue;
  bool elderlyNotified;
  bool caregiverNotified;
  int? sleepStartHour;
  int? sleepEndHour;

  // New configurable settings
  int checkInIntervalHours;
  bool autoCheckInEnabled;

  // Per-type tracking toggles (admin-configurable)
  bool trackPhoneUnlock;
  bool trackStepsActive;
  bool trackPhonePickup;

  ActivityCheckModel({
    required this.elderlyId,
    this.lastPhoneUnlock,
    this.lastStepsActive,
    this.lastPhonePickup,
    this.nextCheckDue,
    this.elderlyNotified = false,
    this.caregiverNotified = false,
    this.sleepStartHour,
    this.sleepEndHour,
    this.checkInIntervalHours = 10,
    this.autoCheckInEnabled = true,
    this.trackPhoneUnlock = true,
    this.trackStepsActive = true,
    this.trackPhonePickup = true,
  });

  Map<String, dynamic> toJson() => {
        'elderlyId': elderlyId,
        'lastPhoneUnlock': lastPhoneUnlock?.toIso8601String(),
        'lastStepsActive': lastStepsActive?.toIso8601String(),
        'lastPhonePickup': lastPhonePickup?.toIso8601String(),
        'nextCheckDue': nextCheckDue?.toIso8601String(),
        'elderlyNotified': elderlyNotified,
        'caregiverNotified': caregiverNotified,
        'sleepStartHour': sleepStartHour,
        'sleepEndHour': sleepEndHour,
        'checkInIntervalHours': checkInIntervalHours,
        'autoCheckInEnabled': autoCheckInEnabled,
        'trackPhoneUnlock': trackPhoneUnlock,
        'trackStepsActive': trackStepsActive,
        'trackPhonePickup': trackPhonePickup,
      };

  factory ActivityCheckModel.fromJson(Map<String, dynamic> json) =>
      ActivityCheckModel(
        elderlyId: json['elderlyId'],
        lastPhoneUnlock: json['lastPhoneUnlock'] != null
            ? DateTime.parse(json['lastPhoneUnlock'])
            : null,
        lastStepsActive: json['lastStepsActive'] != null
            ? DateTime.parse(json['lastStepsActive'])
            : null,
        lastPhonePickup: json['lastPhonePickup'] != null
            ? DateTime.parse(json['lastPhonePickup'])
            : null,
        nextCheckDue: json['nextCheckDue'] != null
            ? DateTime.parse(json['nextCheckDue'])
            : null,
        elderlyNotified: json['elderlyNotified'] ?? false,
        caregiverNotified: json['caregiverNotified'] ?? false,
        sleepStartHour: json['sleepStartHour'],
        sleepEndHour: json['sleepEndHour'],
        checkInIntervalHours: json['checkInIntervalHours'] ?? 10,
        autoCheckInEnabled: json['autoCheckInEnabled'] ?? true,
        trackPhoneUnlock: json['trackPhoneUnlock'] ?? true,
        trackStepsActive: json['trackStepsActive'] ?? true,
        trackPhonePickup: json['trackPhonePickup'] ?? true,
      );

  bool isInSleepWindow() {
    if (sleepStartHour == null || sleepEndHour == null) return false;
    final h = DateTime.now().hour;
    if (sleepStartHour! <= sleepEndHour!) {
      return h >= sleepStartHour! && h < sleepEndHour!;
    } else {
      return h >= sleepStartHour! || h < sleepEndHour!;
    }
  }

  bool hasActivityInWindow() {
    if (!autoCheckInEnabled) return true; // Treat as OK if disabled
    final cutoff = DateTime.now().subtract(Duration(hours: checkInIntervalHours));
    if (trackPhoneUnlock && lastPhoneUnlock != null && lastPhoneUnlock!.isAfter(cutoff)) return true;
    if (trackStepsActive && lastStepsActive != null && lastStepsActive!.isAfter(cutoff)) return true;
    if (trackPhonePickup && lastPhonePickup != null && lastPhonePickup!.isAfter(cutoff)) return true;
    return false;
  }
}
