// lib/pages/caregiver/caregiver_home_page.dart
//
// FIX: Status pills now use the configured checkInIntervalHours from
// ActivityCheckModel (synced from Firestore) instead of hardcoded 2h/5h
// windows. Manual check-in always uses a same-day (24hr) window.
// syncElderlySummaries() is called on initState so the home page reflects
// the latest data from Firestore immediately on open.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/language_button.dart';
import '../../services/notification_service.dart';
import '../chat/chat_page.dart';
import '../profile/profile_page.dart';
import '../sos/sos_history_page.dart';
import 'caregiver_family_group_page.dart';
import 'elderly_detail_page.dart';

class CaregiverHomePage extends StatefulWidget {
  const CaregiverHomePage({super.key});

  @override
  State<CaregiverHomePage> createState() => _CaregiverHomePageState();
}

class _CaregiverHomePageState extends State<CaregiverHomePage> {
  final Set<String> _notifiedElderlyIds = {};
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    // Sync from Firestore immediately on open
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkInactivityAlerts());
    // Periodically check for inactivity alerts
    _checkTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkInactivityAlerts());
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkInactivityAlerts() async {
    if (!mounted) return;
    final ds = context.read<DataService>();

    // Fetch latest summaries from Firestore so we have up-to-date alert flags
    await ds.syncElderlySummaries();

    final groups = ds.getCaregiverGroups();

    for (final group in groups) {
      final elderlyId = group.elderlyId;
      final ac = ds.getActivityCheck(elderlyId);

      if (ac != null && ac.caregiverNotified) {
        if (!_notifiedElderlyIds.contains(elderlyId)) {
          NotificationService.showInactivityAlertForCaregivers(
            elderlyId: elderlyId,
            dataService: ds,
          );
          _notifiedElderlyIds.add(elderlyId);
        }
      } else if (ac != null && !ac.caregiverNotified) {
        _notifiedElderlyIds.remove(elderlyId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final user = ds.currentUser!;
    final groups = ds.getCaregiverGroups();
    final sosAlerts = ds.getCaregiverSosAlerts();
    final activeAlerts =
        sosAlerts.where((s) => s.status.name == 'active').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          const LanguageButton(),
          IconButton(
            icon: const Icon(Icons.person_rounded, size: 28),
            tooltip: l10n.myProfile,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ── Welcome banner ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${l10n.goodDay} ${user.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${l10n.caringFor} ${groups.length} ${l10n.groups}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Active SOS banner ──────────────────────────────────────────
          if (activeAlerts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.sosRedLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.sosRed, width: 2.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_rounded,
                            color: AppTheme.sosRed, size: 30),
                        const SizedBox(width: 8),
                        Text(
                          l10n.activeSOSCount(activeAlerts.length),
                          style: const TextStyle(
                            color: AppTheme.sosRed,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...activeAlerts.take(3).map((sos) {
                      final elderly = ds.getUserById(sos.elderlyId);
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.circle,
                                color: AppTheme.sosRed, size: 10),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${elderly?.name ?? "Unknown"}: ${sos.description}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.sosRed,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ds.resolveSos(sos.id),
                              child: Text(l10n.resolve,
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.sosRed,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Elderly status cards ───────────────────────────────────────
          if (groups.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.elderlyStatus,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...groups.expand((group) {
              final elderly = ds.getUserById(group.elderlyId);
              if (elderly == null) return <Widget>[];

              // FIX: Use the configured interval from ActivityCheckModel,
              // not hardcoded 2h/5h windows.
              final status = ds.getActivityStatusForElderly(elderly.id);

              final latestPhoneUnlock =
                  ds.getLatestPhoneUnlockCheckIn(elderly.id);
              final latestManual = ds.getLatestManualCheckIn(elderly.id);
              final activeSos = ds.getActiveSos(elderly.id);
              final isAdminOfThisGroup = ds.isAdminOfGroup(group.id);

              return [
                _ElderlyStatusCard(
                  elderly: elderly,
                  groupName: group.name,
                  groupId: group.id,
                  phoneActive: status.phoneUnlock,
                  manualCheckedInToday: status.manual,
                  stepsActive: status.steps,
                  pickupActive: status.pickup,
                  latestPhoneUnlock: latestPhoneUnlock,
                  latestManual: latestManual,
                  activeSos: activeSos,
                  isAdmin: isAdminOfThisGroup,
                  onResolveSos: activeSos != null
                      ? () => ds.resolveSos(activeSos.id)
                      : null,
                ),
              ];
            }),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Icon(Icons.group_off_rounded,
                          size: 56, color: AppTheme.textSecondary),
                      const SizedBox(height: 14),
                      Text(
                        l10n.noGroups,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noGroupsDesc,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── SOS history summary card ───────────────────────────────────
          if (sosAlerts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.sosHistory,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...groups.where((g) {
              final ids = sosAlerts.map((s) => s.elderlyId).toSet();
              return ids.contains(g.elderlyId);
            }).map((group) {
              final elderly = ds.getUserById(group.elderlyId);
              if (elderly == null) return const SizedBox.shrink();
              final elderlyAlerts = sosAlerts
                  .where((s) => s.elderlyId == elderly.id)
                  .toList();
              final activeCount = elderlyAlerts
                  .where((s) => s.status == SosStatus.active)
                  .length;
              final displayName = ds.getNickname(elderly.id) ?? elderly.name;
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SosHistoryPage(
                        elderlyId: elderly.id,
                        elderlyName: displayName,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: activeCount > 0
                                ? AppTheme.sosRedLight
                                : AppTheme.successLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            activeCount > 0
                                ? Icons.warning_rounded
                                : Icons.history_rounded,
                            color: activeCount > 0
                                ? AppTheme.sosRed
                                : AppTheme.success,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${elderlyAlerts.length} ${l10n.sosAlerts}'
                                '${activeCount > 0 ? ' · $activeCount ${l10n.active}' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: activeCount > 0
                                      ? AppTheme.sosRed
                                      : AppTheme.textSecondary,
                                  fontWeight: activeCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.primary, size: 28),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],

          const SizedBox(height: 20),

          // ── Manage groups card ─────────────────────────────────────────
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CaregiverFamilyGroupPage()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.group_rounded,
                          color: AppTheme.primary, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.manageGroups,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            l10n.manageGroupsDesc,
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.primary, size: 32),
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
}

// ── Elderly status card ────────────────────────────────────────────────────
class _ElderlyStatusCard extends StatelessWidget {
  final UserModel elderly;
  final String groupName;
  final String groupId;
  final bool phoneActive;
  final bool manualCheckedInToday;
  final bool stepsActive;
  final bool pickupActive;
  final CheckInModel? latestPhoneUnlock;
  final CheckInModel? latestManual;
  final SosModel? activeSos;
  final bool isAdmin;
  final VoidCallback? onResolveSos;

  const _ElderlyStatusCard({
    required this.elderly,
    required this.groupName,
    required this.groupId,
    required this.phoneActive,
    required this.manualCheckedInToday,
    required this.stepsActive,
    required this.pickupActive,
    required this.latestPhoneUnlock,
    required this.latestManual,
    required this.activeSos,
    required this.isAdmin,
    this.onResolveSos,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final unread = ds.getUnreadCount(elderly.id);
    final displayName = ds.getNickname(elderly.id) ?? elderly.name;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.accent.withOpacity(0.2),
                  child: const Icon(Icons.elderly_rounded,
                      color: AppTheme.accent, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(l10n.adminLabel,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Detail page icon
                IconButton(
                  icon: const Icon(Icons.info_rounded,
                      color: AppTheme.primary, size: 26),
                  tooltip: 'View Details',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ElderlyDetailPage(
                        elderly: elderly,
                        groupId: groupId,
                      ),
                    ),
                  ),
                ),
                // Message icon with unread badge
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        otherUser: elderly,
                        groupId: groupId,
                      ),
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.message_rounded,
                            color: AppTheme.primary, size: 24),
                      ),
                      if (unread > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppTheme.sosRed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),

            // ── Four-type check-in status ─────────────────────────────────
            _FourStatusGrid(
              phoneActive: phoneActive,
              manualCheckedInToday: manualCheckedInToday,
              stepsActive: stepsActive,
              pickupActive: pickupActive,
            ),

            // ── Separate timestamps ───────────────────────────────────────
            const SizedBox(height: 10),
            if (latestPhoneUnlock != null)
              _TimestampRow(
                icon: Icons.phone_android_rounded,
                label: l10n.lastSeen,
                time: latestPhoneUnlock!.timestamp,
                color: phoneActive
                    ? AppTheme.success
                    : AppTheme.textSecondary,
              ),
            if (latestManual != null)
              _TimestampRow(
                icon: Icons.touch_app_rounded,
                label: l10n.lastCheckIn,
                time: latestManual!.timestamp,
                color: manualCheckedInToday
                    ? AppTheme.success
                    : AppTheme.textSecondary,
              ),
            if (latestPhoneUnlock == null && latestManual == null)
              Text(
                l10n.noActivity,
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),

            // ── Active SOS ────────────────────────────────────────────────
            if (activeSos != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sosRedLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppTheme.sosRed, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeSos!.description,
                        style: const TextStyle(
                          color: AppTheme.sosRed,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onResolveSos != null)
                      TextButton(
                        onPressed: onResolveSos,
                        child: Text(l10n.resolve,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.sosRed,
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Timestamp row ─────────────────────────────────────────────────────────
class _TimestampRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime time;
  final Color color;

  const _TimestampRow({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final timeStr = locale == 'zh'
        ? '${time.month}月${time.day}日 ${DateFormat('HH:mm').format(time)}'
        : DateFormat('d MMM, h:mm a').format(time);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $timeStr',
            style: TextStyle(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Four-status grid ───────────────────────────────────────────────────────
class _FourStatusGrid extends StatelessWidget {
  final bool phoneActive;
  final bool manualCheckedInToday;
  final bool stepsActive;
  final bool pickupActive;

  const _FourStatusGrid({
    required this.phoneActive,
    required this.manualCheckedInToday,
    required this.stepsActive,
    required this.pickupActive,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatusPill(
              icon: Icons.lock_open_rounded,
              label: l10n.phoneUnlockCheck,
              active: phoneActive,
              activeColor: AppTheme.success,
              inactiveColor: AppTheme.textSecondary,
            )),
            const SizedBox(width: 8),
            Expanded(child: _StatusPill(
              icon: Icons.touch_app_rounded,
              label: manualCheckedInToday ? l10n.checkedIn : l10n.notCheckedIn,
              active: manualCheckedInToday,
              activeColor: AppTheme.success,
              inactiveColor: AppTheme.warning,
            )),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _StatusPill(
              icon: Icons.directions_walk_rounded,
              label: l10n.stepsCheck,
              active: stepsActive,
              activeColor: AppTheme.success,
              inactiveColor: AppTheme.textSecondary,
            )),
            const SizedBox(width: 8),
            Expanded(child: _StatusPill(
              icon: Icons.phone_in_talk_rounded,
              label: l10n.phonePickupCheck,
              active: pickupActive,
              activeColor: AppTheme.success,
              inactiveColor: AppTheme.textSecondary,
            )),
          ],
        ),
      ],
    );
  }
}
