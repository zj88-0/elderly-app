// lib/pages/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../auth/login_page.dart';
import '../../services/background_service.dart';
import '../../widgets/language_button.dart';
import '../../widgets/sos_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _editMode = false;
  bool _loading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _changePassword = false;
  bool _clearingData = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<DataService>().currentUser!;
    _nameCtrl = TextEditingController(text: user.name);
    _emailCtrl = TextEditingController(text: user.email);
    _phoneCtrl = TextEditingController(text: user.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<DataService>().updateCurrentUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        password: _changePassword ? _newPassCtrl.text : null,
      );
      if (!mounted) return;
      setState(() {
        _editMode = false;
        _changePassword = false;
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.profileUpdated,
            style: const TextStyle(fontSize: 17)),
        backgroundColor: AppTheme.success,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e', style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.sosRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _cancelEdit() {
    final user = context.read<DataService>().currentUser!;
    setState(() {
      _editMode = false;
      _changePassword = false;
      _nameCtrl.text = user.name;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phoneNumber ?? '';
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
    });
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOut, style: const TextStyle(fontSize: 22)),
        content: Text(l10n.logOutConfirm, style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel, style: const TextStyle(fontSize: 18))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.logOut, style: const TextStyle(fontSize: 18))),
        ],
      ),
    );
    if (confirmed != true) return;
    final ds = context.read<DataService>();
    if (ds.currentUser?.role == UserRole.elderly) {
      await BackgroundServiceHelper.stop();
    }
    await ds.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }

  Future<void> _clearTrackingData() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppTheme.warning, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n.clearTrackingData,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
        content: Text(l10n.clearTrackingDataConfirm,
            style: const TextStyle(fontSize: 16, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel, style: const TextStyle(fontSize: 17)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              minimumSize: const Size(0, 46),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.clearTrackingData,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _clearingData = true);
    try {
      await context.read<DataService>().clearTrackingDataForCurrentUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.clearTrackingDataDone,
              style: const TextStyle(fontSize: 17)),
          backgroundColor: AppTheme.warning,
        ));
      }
    } finally {
      if (mounted) setState(() => _clearingData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ds = context.watch<DataService>();
    final user = ds.currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());
    final isElderly = user.role == UserRole.elderly;

    // ── Tracking data for summary ──────────────────────────────────────
    final today = DateTime.now();
    final todayCheckIns = ds.getTodayCheckIns(user.id);
    final manualToday = todayCheckIns
        .where((c) => c.type == CheckInType.manual)
        .length;
    final unlockToday = todayCheckIns
        .where((c) => c.type == CheckInType.phoneUnlock)
        .length;
    final stepsToday = todayCheckIns
        .where((c) => c.type == CheckInType.stepsActive)
        .length;
    final pickupToday = todayCheckIns
        .where((c) => c.type == CheckInType.phonePickup)
        .length;
    final sosToday = ds.getSosHistoryForElderly(user.id)
        .where((s) =>
            s.triggeredAt.year == today.year &&
            s.triggeredAt.month == today.month &&
            s.triggeredAt.day == today.day)
        .length;
    final wellbeingToday = ds.getTodayWellbeing(user.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myProfile),
        actions: [
          const LanguageButton(),
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 26),
              tooltip: l10n.editProfile,
              onPressed: () => setState(() => _editMode = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Avatar ────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isElderly
                        ? AppTheme.accent.withOpacity(0.15)
                        : AppTheme.primaryLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isElderly ? AppTheme.accent : AppTheme.primary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    isElderly
                        ? Icons.elderly_rounded
                        : Icons.volunteer_activism_rounded,
                    size: 54,
                    color: isElderly ? AppTheme.accent : AppTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isElderly
                        ? AppTheme.accent.withOpacity(0.15)
                        : AppTheme.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isElderly ? l10n.elderly : l10n.caregiver,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isElderly ? AppTheme.accent : AppTheme.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Name ──────────────────────────────────────────────────
              _FieldLabel(label: l10n.fullName),
              TextFormField(
                controller: _nameCtrl,
                enabled: _editMode,
                style: const TextStyle(fontSize: 18),
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.fullName,
                  prefixIcon: const Icon(Icons.person_rounded,
                      color: AppTheme.primary, size: 26),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fullName : null,
              ),
              const SizedBox(height: 16),

              // ── Email ─────────────────────────────────────────────────
              _FieldLabel(label: l10n.email),
              TextFormField(
                controller: _emailCtrl,
                enabled: _editMode,
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_rounded,
                      color: AppTheme.primary, size: 26),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.email;
                  if (!v.contains('@')) return l10n.email;
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Phone ─────────────────────────────────────────────────
              _FieldLabel(label: l10n.phoneNumber),
              TextFormField(
                controller: _phoneCtrl,
                enabled: _editMode,
                style: const TextStyle(fontSize: 18),
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumber,
                  prefixIcon: const Icon(Icons.phone_rounded,
                      color: AppTheme.primary, size: 26),
                ),
              ),

              // ── Change password ───────────────────────────────────────
              if (_editMode) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _changePassword,
                      onChanged: (v) =>
                          setState(() => _changePassword = v ?? false),
                      activeColor: AppTheme.primary,
                    ),
                    Text(l10n.changePassword,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (_changePassword) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _newPassCtrl,
                    obscureText: _obscureNew,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      prefixIcon: const Icon(Icons.lock_rounded,
                          color: AppTheme.primary, size: 26),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (v) {
                      if (!_changePassword) return null;
                      if (v == null || v.isEmpty) return l10n.newPassword;
                      if (v.length < 6) return l10n.newPassword;
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppTheme.primary, size: 26),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (!_changePassword) return null;
                      if (v != _newPassCtrl.text) return l10n.confirmPassword;
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 28),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_rounded, size: 24),
                        label: Text(l10n.saveChanges,
                            style: const TextStyle(fontSize: 19)),
                      ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _cancelEdit,
                  child: Text(l10n.cancel,
                      style: const TextStyle(fontSize: 19)),
                ),
              ],

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ── SOS Button (for elderly users) ────────────────────────
              if (isElderly)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [SosButton()],
                ),
              if (isElderly) const SizedBox(height: 10),

              // ── Logout ─────────────────────────────────────────────────
              OutlinedButton.icon(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.sosRed,
                  side: const BorderSide(color: AppTheme.sosRed, width: 2),
                  minimumSize: const Size.fromHeight(56),
                ),
                icon: const Icon(Icons.logout_rounded, size: 26),
                label: Text(l10n.logOut,
                    style: const TextStyle(fontSize: 19)),
              ),

              const SizedBox(height: 32),

              // ── Daily Tracking Data & Dev Tools (elderly only) ─────────
              if (isElderly) ...[
              const Divider(),
              const SizedBox(height: 20),

              // ══════════════════════════════════════════════════════════
              // ── Daily Tracking Data ────────────────────────────────────
              // ══════════════════════════════════════════════════════════
              Row(
                children: [
                  const Icon(Icons.monitor_heart_rounded,
                      color: AppTheme.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(l10n.dailyTrackingData,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                locale == 'zh'
                    ? '${today.year}年${today.month}月${today.day}日'
                    : DateFormat('d MMMM yyyy').format(today),
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Check-in counts grid
              _TrackingGrid(children: [
                _TrackingTile(
                  icon: Icons.touch_app_rounded,
                  label: l10n.manualCheckInCount,
                  value: '$manualToday',
                  color: AppTheme.primary,
                  active: manualToday > 0,
                ),
                _TrackingTile(
                  icon: Icons.lock_open_rounded,
                  label: l10n.phoneUnlockCount,
                  value: '$unlockToday',
                  color: const Color(0xFF1565C0),
                  active: unlockToday > 0,
                ),
                _TrackingTile(
                  icon: Icons.directions_walk_rounded,
                  label: l10n.stepsCount,
                  value: '$stepsToday',
                  color: const Color(0xFF2E7D32),
                  active: stepsToday > 0,
                ),
                _TrackingTile(
                  icon: Icons.phone_in_talk_rounded,
                  label: l10n.pickupCount,
                  value: '$pickupToday',
                  color: const Color(0xFF6A1B9A),
                  active: pickupToday > 0,
                ),
              ]),

              const SizedBox(height: 12),

              // Wellbeing + SOS row
              Row(
                children: [
                  Expanded(
                    child: _TrackingTile(
                      icon: Icons.favorite_rounded,
                      label: l10n.wellbeingScore,
                      value: wellbeingToday != null
                          ? '${wellbeingToday.averageScore.toStringAsFixed(1)}/5'
                          : l10n.notDoneToday,
                      color: const Color(0xFFE91E63),
                      active: wellbeingToday != null,
                      smallValue: wellbeingToday == null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrackingTile(
                      icon: Icons.warning_rounded,
                      label: l10n.sosCount,
                      value: '$sosToday',
                      color: AppTheme.sosRed,
                      active: sosToday == 0,
                      invertActive: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Total today summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2), width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today_rounded,
                        color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(l10n.checkInsToday,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: todayCheckIns.isNotEmpty
                            ? AppTheme.primary
                            : AppTheme.textSecondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${todayCheckIns.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: todayCheckIns.isNotEmpty
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 16),

              // ══════════════════════════════════════════════════════════
              // ── Developer / Testing Section ───────────────────────────
              // ══════════════════════════════════════════════════════════
              Row(
                children: [
                  const Icon(Icons.bug_report_rounded,
                      color: AppTheme.warning, size: 22),
                  const SizedBox(width: 8),
                  Text(l10n.devTesting,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.warning)),
                ],
              ),
              const SizedBox(height: 12),

              _clearingData
                  ? const Center(child: CircularProgressIndicator())
                  : OutlinedButton.icon(
                      onPressed: _clearTrackingData,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.warning,
                        side: const BorderSide(
                            color: AppTheme.warning, width: 2),
                        minimumSize: const Size.fromHeight(52),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 24),
                      label: Text(l10n.clearTrackingData,
                          style: const TextStyle(fontSize: 17)),
                    ),

              const SizedBox(height: 40),
              ], // end if (isElderly)

            ],
          ),
        ),
      ),
    );
  }
}

// ── Tracking grid — 2-column wrap ─────────────────────────────────────────
class _TrackingGrid extends StatelessWidget {
  final List<Widget> children;
  const _TrackingGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      rows.add(Row(
        children: [
          Expanded(child: children[i]),
          const SizedBox(width: 12),
          Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox.shrink()),
        ],
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

// ── Tracking tile ──────────────────────────────────────────────────────────
class _TrackingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool active;
  final bool smallValue;
  // invertActive: for SOS, green=0 (no SOS is good), red=any
  final bool invertActive;

  const _TrackingTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    this.smallValue = false,
    this.invertActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = invertActive
        ? (active ? AppTheme.success : AppTheme.sosRed)
        : (active ? color : AppTheme.textSecondary);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: effectiveColor.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: effectiveColor, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: smallValue ? 14 : 26,
              fontWeight: FontWeight.w900,
              color: effectiveColor,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Field label ────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          )),
    );
  }
}
