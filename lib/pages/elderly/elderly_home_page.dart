// lib/pages/elderly/elderly_home_page.dart
// Enhanced:
// - Category buttons (big, Tamil-safe, no overflow)
// - Daily Check-In = manual only
// - Messages button opens caregiver list, not direct chat
// - Background activity card HIDDEN from elderly
// - Larger fonts throughout
// - Daily wellbeing questionnaire button added
// - 5-hour activity check with sleep window

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../../services/activity_tracker_service.dart';
import '../../services/background_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sos_button.dart';
import '../../widgets/language_button.dart';
import '../chat/chat_page.dart';
import '../profile/profile_page.dart';
import 'elderly_family_group_page.dart';
import 'wellbeing_page.dart';

class ElderlyHomePage extends StatefulWidget {
  const ElderlyHomePage({super.key});

  @override
  State<ElderlyHomePage> createState() => _ElderlyHomePageState();
}

class _ElderlyHomePageState extends State<ElderlyHomePage>
    with WidgetsBindingObserver {
  bool _checkingIn = false;

  @override
  void initState() {
    super.initState();
    _setAppForeground(true);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startTracking());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ActivityTrackerService.dispose();
    super.dispose();
  }

  void _startTracking() {
    final ds = context.read<DataService>();
    final user = ds.currentUser;
    if (user == null || user.role != UserRole.elderly) return;
    // Start background service so it has the elderlyId for background tracking
    BackgroundServiceHelper.startService(user.id, user.name, true);
    ActivityTrackerService.startTracking(
      elderlyId: user.id,
      dataService: ds,
      onElderlyAlert: () => _showActivityAlert(),
    );
  }

  void _showActivityAlert() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.notification_important_rounded,
                color: AppTheme.warning, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n.activityCheckTitle,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(l10n.activityCheckMessage,
            style: const TextStyle(fontSize: 19, height: 1.5)),
        actions: [
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              await _manualCheckIn();
              final ds = context.read<DataService>();
              final user = ds.currentUser;
              if (user != null) await ds.markElderlyNotified(user.id);
            },
            icon: const Icon(Icons.check_circle_rounded, size: 28),
            label: Text(l10n.imOk, style: const TextStyle(fontSize: 20)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              minimumSize: const Size.fromHeight(60),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setAppForeground(true);
      // FIX: call a single async wrapper so both run sequentially, not concurrently.
      // Racing two async methods that both read/write SharedPreferences caused
      // the "reads sometimes, fails sometimes" behaviour.
      _onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _setAppForeground(false);
    }
  }

  Future<void> _setAppForeground(bool auto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAppForeground', auto);
  }

  Future<void> _onAppResumed() async {
    final ds = context.read<DataService>();
    final user = ds.currentUser;
    if (user != null && user.role == UserRole.elderly) {
      // Sync settings (interval/enabled) from Firestore in case an admin changed them
      await ds.syncOwnActivityCheck(user.id);
    }
    await _consumeBackgroundCheckIns();
  }


  /// Flushes any check-ins queued by the background service isolate
  /// into DataService so they show up in the UI and activity window.
  Future<void> _consumeBackgroundCheckIns() async {
    // FIX: mounted check before context.read
    if (!mounted) return;
    final ds = context.read<DataService>();
    final user = ds.currentUser;
    if (user == null || user.role != UserRole.elderly) return;
    final pending = await BackgroundServiceHelper.consumePendingCheckIns();
    for (final raw in pending) {
      final typeStr = raw['type'] as String? ?? 'phoneUnlock';
      CheckInType type;
      switch (typeStr) {
        case 'stepsActive':
          type = CheckInType.stepsActive;
          break;
        case 'phonePickup':
          type = CheckInType.phonePickup;
          break;
        default:
          type = CheckInType.phoneUnlock;
      }
      final meta = raw['meta'] as Map<String, dynamic>?;
      await ds.createCheckIn(
        elderlyId: user.id,
        type: type,
        meta: meta,
        timestamp: DateTime.parse(raw['timestamp']),
        id: raw['id'],
      );
    }
  }

  Future<void> _manualCheckIn() async {
    final ds = context.read<DataService>();
    final l10n = AppLocalizations.of(context);
    final user = ds.currentUser!;
    setState(() => _checkingIn = true);
    try {
      await ds.createCheckIn(elderlyId: user.id, type: CheckInType.manual);
      // Note: caregivers are alerted via their Firestore sync loop — no local
      // notification should fire on the elderly's own device for check-in.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.checkInSuccess,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  /// Shows a bottom sheet with a list of caregivers to message
  void _showCaregiversList(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.read<DataService>();
    final group = ds.getElderlyGroup();

    if (group == null || group.caregiverIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noCaregivers,
            style: const TextStyle(fontSize: 17))),
      );
      return;
    }

    final caregivers = group.caregiverIds
        .map((id) => ds.getUserById(id))
        .whereType<UserModel>()
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(l10n.selectCaregiver,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              ...caregivers.map((cg) {
                final displayName = ds.getNickname(cg.id) ?? cg.name;
                final unread = ds.getUnreadCount(cg.id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                    child: const Icon(Icons.volunteer_activism_rounded,
                        color: AppTheme.primary, size: 26),
                  ),
                  title: Text(displayName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  subtitle: Text(l10n.caregiver,
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.primary)),
                  trailing: unread > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                              color: AppTheme.sosRed,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text('$unread',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800)),
                        )
                      : const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.primary),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ChatPage(
                              otherUser: cg, groupId: group.id)),
                    );
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ds = context.watch<DataService>();
    final user = ds.currentUser!;
    final checkedInToday = ds.hasManualCheckedInToday(user.id);
    final latestManual = ds.getLatestManualCheckIn(user.id);
    final pendingInvites = ds.getPendingInvitesForCurrentUser();
    final activeSos = ds.getActiveSos(user.id);
    final totalUnread = ds.getTotalUnreadCount();
    final todayWellbeing = ds.getTodayWellbeing(user.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          const LanguageButton(),
          IconButton(
            icon: const Icon(Icons.person_rounded, size: 28),
            tooltip: l10n.myProfile,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
          ),
        ],
      ),
      floatingActionButton: const SosButton(),
      body: RefreshIndicator(
        onRefresh: () async => _consumeBackgroundCheckIns(),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // ── Welcome banner ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.waving_hand_rounded,
                        color: Colors.white, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.goodDay,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 18)),
                          Text(user.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          locale == 'zh'
                              ? '${DateTime.now().month}月${DateTime.now().day}日'
                              : DateFormat('d MMM').format(DateTime.now()),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Active SOS warning ──────────────────────────────────────
            if (activeSos != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.sosRedLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.sosRed, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_rounded,
                          color: AppTheme.sosRed, size: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.sosActive,
                                style: const TextStyle(
                                    color: AppTheme.sosRed,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            Text(activeSos.description,
                                style: const TextStyle(
                                    color: AppTheme.sosRed, fontSize: 17)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Daily Check-In Button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.dailyCheckIn,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(l10n.dailyCheckInDesc,
                      style: const TextStyle(
                          fontSize: 16, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  if (latestManual != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '${l10n.lastCheckIn}: ${locale == 'zh' ? '${latestManual.timestamp.month}月${latestManual.timestamp.day}日 ${DateFormat('HH:mm').format(latestManual.timestamp)}' : DateFormat('d MMM, h:mm a').format(latestManual.timestamp)}',
                        style: const TextStyle(
                            fontSize: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                  _checkingIn
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                          onPressed: _manualCheckIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: checkedInToday
                                ? AppTheme.success
                                : AppTheme.primary,
                            minimumSize: const Size.fromHeight(76),
                          ),
                          icon: Icon(
                            checkedInToday
                                ? Icons.check_circle_rounded
                                : Icons.touch_app_rounded,
                            size: 34,
                          ),
                          label: Text(
                            checkedInToday
                                ? l10n.checkedInToday
                                : l10n.tapToCheckIn,
                            style: const TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick Action Category Buttons ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.quickActions,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary)),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Row 1: Family Group | Messages
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryButton(
                          icon: Icons.group_rounded,
                          label: l10n.myFamilyGroup,
                          color: AppTheme.primary,
                          badge: pendingInvites.isNotEmpty
                              ? '${pendingInvites.length}'
                              : null,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ElderlyFamilyGroupPage())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CategoryButton(
                          icon: Icons.message_rounded,
                          label: l10n.messages,
                          color: const Color(0xFF1565C0),
                          badge: totalUnread > 0 ? '$totalUnread' : null,
                          onTap: () => _showCaregiversList(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 2: Wellbeing | SOS History
                  Row(
                    children: [
                      Expanded(
                        child: _CategoryButton(
                          icon: Icons.favorite_rounded,
                          label: l10n.wellbeingButton,
                          color: const Color(0xFFE91E63),
                          badge: todayWellbeing == null ? '!' : null,
                          badgeColor: AppTheme.warning,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WellbeingPage())),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CategoryButton(
                          icon: Icons.history_rounded,
                          label: l10n.sosHistory,
                          color: AppTheme.sosRed,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const _SosHistoryRoute())),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Row 3: Profile (full width)
                  _CategoryButton(
                    icon: Icons.person_rounded,
                    label: l10n.myProfile,
                    color: AppTheme.accent,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfilePage())),
                  ),
                ],
              ),
            ),

            // ── Pending invites banner ─────────────────────────────────
            if (pendingInvites.isNotEmpty) ...[
              const SizedBox(height: 14),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ElderlyFamilyGroupPage())),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppTheme.warning, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded,
                            color: AppTheme.warning, size: 30),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${pendingInvites.length} ${l10n.pendingInvites}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.warning),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.warning, size: 26),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

// ── Category Button ─────────────────────────────────────────────────────
class _CategoryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bColor = badgeColor ?? AppTheme.sosRed;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(icon, color: color, size: 38),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                      color: bColor, shape: BoxShape.circle),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── SOS History proxy ──────────────────────────────────────────────────
class _SosHistoryRoute extends StatelessWidget {
  const _SosHistoryRoute();

  @override
  Widget build(BuildContext context) {
    final ds = context.watch<DataService>();
    final user = ds.currentUser;
    if (user == null) return const Scaffold();
    return _SosHistoryProxy(elderlyId: user.id, elderlyName: user.name);
  }
}

class _SosHistoryProxy extends StatelessWidget {
  final String elderlyId;
  final String elderlyName;
  const _SosHistoryProxy(
      {required this.elderlyId, required this.elderlyName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final history = ds.getSosHistoryForElderly(elderlyId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sosHistory),
        actions: const [LanguageButton()],
      ),
      floatingActionButton: const SosButton(),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppTheme.success.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(l10n.noSosHistory,
                      style: const TextStyle(
                          fontSize: 20, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (ctx, i) {
                final sos = history[i];
                final isActive = sos.status == SosStatus.active;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Icon(
                      isActive
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      color: isActive ? AppTheme.sosRed : AppTheme.success,
                      size: 32,
                    ),
                    title: Text(sos.description,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      DateFormat('d MMM yyyy, h:mm a')
                          .format(sos.triggeredAt),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
