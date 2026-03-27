// lib/pages/caregiver/elderly_detail_page.dart
//
// Changes from previous version:
//   - Added a "Configure Check-In" button (admin-only) that navigates to
//     CheckInConfigPage — a dedicated full page for all settings.
//   - Removed the old inline _showAutoCheckInDialog and _showSleepWindowDialog
//     dialogs (all that logic now lives in CheckInConfigPage).
//   - Sleep window and interval are shown as read-only summary rows so the
//     admin can see current values at a glance before tapping Configure.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';
import '../chat/chat_page.dart';
import '../elderly/wellbeing_page.dart';
import '../sos/sos_history_page.dart';
import 'checkin_config_page.dart';

class ElderlyDetailPage extends StatefulWidget {
  final UserModel elderly;
  final String groupId;

  const ElderlyDetailPage({
    super.key,
    required this.elderly,
    required this.groupId,
  });

  @override
  State<ElderlyDetailPage> createState() => _ElderlyDetailPageState();
}

class _ElderlyDetailPageState extends State<ElderlyDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ds = context.read<DataService>();
      ds.subscribeToElderlyCheckIns(widget.elderly.id);
      // Also sync the latest settings from Firestore so the summary is fresh
      ds.syncOwnActivityCheck(widget.elderly.id);
    });
  }

  @override
  void dispose() {
    context.read<DataService>().unsubscribeFromElderlyCheckIns();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ds = context.watch<DataService>();
    final group = ds.getGroupById(widget.groupId);

    final latestPhoneUnlock = ds.getLatestPhoneUnlockCheckIn(widget.elderly.id);
    final latestManual      = ds.getLatestManualCheckIn(widget.elderly.id);
    final latestSteps       = ds.getLatestStepsCheckIn(widget.elderly.id);
    final latestPickup      = ds.getLatestPhonePickupCheckIn(widget.elderly.id);
    final activeSos         = ds.getActiveSos(widget.elderly.id);
    final sosHistory        = ds.getSosHistoryForElderly(widget.elderly.id);
    final todayCheckIns     = ds.getTodayCheckIns(widget.elderly.id);
    final ac                = ds.getOrCreateActivityCheck(widget.elderly.id);

    bool isRecent(DateTime? dt) =>
        dt != null && DateTime.now().difference(dt).inHours < 5;

    final displayName =
        ds.getNickname(widget.elderly.id) ?? widget.elderly.name;

    String fmt(DateTime dt) => locale == 'zh'
        ? '${dt.year}年${dt.month}月${dt.day}日 ${DateFormat('HH:mm').format(dt)}'
        : DateFormat('d MMM yyyy, h:mm a').format(dt);

    String fmtHour(int h) =>
        DateFormat('h:00 a').format(DateTime(2000, 1, 1, h));

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, size: 24),
            tooltip: l10n.editName,
            onPressed: () => _showEditNicknameDialog(context, ds, displayName),
          ),
          const LanguageButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile card ────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppTheme.accent.withOpacity(0.2),
                    child: const Icon(Icons.elderly_rounded,
                        color: AppTheme.accent, size: 38),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800)),
                        if (ds.getNickname(widget.elderly.id) != null)
                          Text('(${widget.elderly.name})',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary)),
                        if (widget.elderly.phoneNumber != null &&
                            widget.elderly.phoneNumber!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_rounded,
                                    size: 14,
                                    color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(widget.elderly.phoneNumber!,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary)),
                              ],
                            ),
                          ),
                        if (group != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.group_rounded,
                                  size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                              Text(group.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primary)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Active SOS alert ─────────────────────────────────────────────
          if (activeSos != null)
            Card(
              color: AppTheme.sosRedLight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppTheme.sosRed, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.sosActive,
                              style: const TextStyle(
                                  color: AppTheme.sosRed,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800)),
                          Text(activeSos.description,
                              style: const TextStyle(
                                  color: AppTheme.sosRed, fontSize: 15)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => ds.resolveSos(activeSos.id),
                      child: Text(l10n.resolve,
                          style: const TextStyle(
                              color: AppTheme.sosRed,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ── 4-type Check-in Status ───────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l10n.checkInStatus,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      // Live indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: AppTheme.success,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 4),
                            Text(l10n.liveLabel,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.success,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _CheckStatusRow(
                    icon: Icons.touch_app_rounded,
                    label: l10n.manualCheckIn,
                    active: ds.hasManualCheckedInToday(widget.elderly.id),
                    lastTime: latestManual?.timestamp,
                    fmt: fmt,
                  ),
                  _CheckStatusRow(
                    icon: Icons.lock_open_rounded,
                    label: l10n.phoneUnlockCheck,
                    active: isRecent(latestPhoneUnlock?.timestamp),
                    lastTime: latestPhoneUnlock?.timestamp,
                    fmt: fmt,
                  ),
                  _CheckStatusRow(
                    icon: Icons.directions_walk_rounded,
                    label: l10n.stepsCheck,
                    active: isRecent(latestSteps?.timestamp),
                    lastTime: latestSteps?.timestamp,
                    fmt: fmt,
                    extra: latestSteps?.meta != null
                        ? '50+ ${l10n.steps}'
                        : null,
                  ),
                  _CheckStatusRow(
                    icon: Icons.phone_in_talk_rounded,
                    label: l10n.phonePickupCheck,
                    active: isRecent(latestPickup?.timestamp),
                    lastTime: latestPickup?.timestamp,
                    fmt: fmt,
                  ),
                  const SizedBox(height: 8),
                  _DetailRow(
                    icon: Icons.today_rounded,
                    label: l10n.todayCheckIns,
                    value: '${todayCheckIns.length}',
                    color: AppTheme.primary,
                  ),
                  _DetailRow(
                    icon: Icons.timer_rounded,
                    label: l10n.alertInterval,
                    value: ac.autoCheckInEnabled
                        ? '${ac.checkInIntervalHours} ${l10n.hours}'
                        : l10n.disabled,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Current settings summary ──────────────────────────────────
          ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.currentConfiguration,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Auto signals summary
                    _SummaryRow(
                      icon: Icons.sensors_rounded,
                      label: l10n.autoTracking,
                      value: ac.autoCheckInEnabled ? l10n.enabled : l10n.disabled,
                      valueColor: ac.autoCheckInEnabled
                          ? AppTheme.success
                          : AppTheme.textSecondary,
                    ),
                    if (ac.autoCheckInEnabled) ...[
                      _SummaryRow(
                        icon: Icons.timer_rounded,
                        label: l10n.alertWindow,
                        value: '${ac.checkInIntervalHours} ${l10n.hours}',
                        valueColor: AppTheme.primary,
                      ),
                      _SummaryRow(
                        icon: Icons.info_outline_rounded,
                        label: l10n.trackingLabel,
                        value: [
                          if (ac.trackPhoneUnlock) l10n.phoneUnlockLabel,
                          if (ac.trackStepsActive) l10n.stepsCheck,
                          if (ac.trackPhonePickup) l10n.phonePickupCheck,
                        ].join(' · '),
                        valueColor: AppTheme.primary,
                      ),
                    ],
                    _SummaryRow(
                      icon: Icons.bedtime_rounded,
                      label: l10n.sleepWindowSection,
                      value: ac.sleepStartHour != null
                          ? '${fmtHour(ac.sleepStartHour!)} → ${fmtHour(ac.sleepEndHour!)}'
                          : l10n.notSet,
                      valueColor: ac.sleepStartHour != null
                          ? AppTheme.accent
                          : AppTheme.textSecondary,
                    ),

                    const SizedBox(height: 14),

                    // ── Configure button ──────────────────────────────────
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CheckInConfigPage(elderly: widget.elderly),
                        ),
                      ),
                      icon: const Icon(Icons.settings_rounded, size: 20),
                      label: Text(
                        l10n.configureCheckIn,
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── SOS History card ─────────────────────────────────────────────
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SosHistoryPage(
                    elderlyId: widget.elderly.id,
                    elderlyName: displayName,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.sosRedLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppTheme.sosRed, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.sosHistory,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text('${sosHistory.length} ${l10n.sosAlerts}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.sosRed, size: 28),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Wellbeing card ───────────────────────────────────────────────
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WellbeingViewPage(
                    elderlyId: widget.elderly.id,
                    elderlyName: displayName,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.favorite_rounded,
                          color: Color(0xFFE91E63), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dailyWellbeing,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                          Text(l10n.wellbeingSubtitle,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFE91E63), size: 28),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Message button ───────────────────────────────────────────────
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                      otherUser: widget.elderly, groupId: widget.groupId),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.message_rounded,
                          color: AppTheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(l10n.sendMessage,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.primary, size: 28),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showEditNicknameDialog(
      BuildContext context, DataService ds, String currentDisplay) {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(
        text: currentDisplay == widget.elderly.name ? '' : currentDisplay);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.editName,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            labelText: '${l10n.newName} (${widget.elderly.name})',
            hintText: widget.elderly.name,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ds.setNickname(widget.elderly.id, null);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child:
                Text(l10n.cancel, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              await ds.setNickname(
                  widget.elderly.id, name.isEmpty ? null : name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.save, style: const TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text('$label: ',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor)),
          ),
        ],
      ),
    );
  }
}

class _CheckStatusRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final DateTime? lastTime;
  final String Function(DateTime) fmt;
  final String? extra;

  const _CheckStatusRow({
    required this.icon,
    required this.label,
    required this.active,
    required this.fmt,
    this.lastTime,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.success : AppTheme.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color)),
                if (lastTime != null)
                  Text(fmt(lastTime!),
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                if (extra != null)
                  Text(extra!,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                if (lastTime == null)
                  const Text('–',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              active ? '✓ OK' : '–',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.w600)),
          Expanded(
            child:
                Text(value, style: TextStyle(fontSize: 14, color: color)),
          ),
        ],
      ),
    );
  }
}
