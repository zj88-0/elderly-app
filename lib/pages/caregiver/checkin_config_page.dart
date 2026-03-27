// lib/pages/caregiver/checkin_config_page.dart
//
// Dedicated page for configuring an elderly user's auto check-in settings.
// Opened from ElderlyDetailPage via the "Configure" button (admin only).
//
// Sections
//   1. Auto Check-In Signals  — enable/disable the 3 automatic signals
//      (Phone Unlock, Steps, Phone Pickup). Manual check-in is always-on
//      and shown read-only so the admin understands it is not configurable.
//   2. Alert Window           — slider 2 h – 12 h (default 10 h).
//      The whole auto section is gated behind a master enable toggle.
//   3. Sleep Window           — start/end hour dropdowns (or "Not set").
//      Clearing sets both to null.
//
// All changes are saved to Firestore via DataService and the elderly device
// picks them up on next app resume via syncOwnActivityCheck.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';

class CheckInConfigPage extends StatefulWidget {
  final UserModel elderly;

  const CheckInConfigPage({super.key, required this.elderly});

  @override
  State<CheckInConfigPage> createState() => _CheckInConfigPageState();
}

class _CheckInConfigPageState extends State<CheckInConfigPage> {
  // ── Local draft state (only committed on Save) ──────────────────────────
  bool _autoEnabled = true;
  int  _intervalHours = 10;
  bool _trackUnlock  = true;
  bool _trackSteps   = true;
  bool _trackPickup  = true;

  // Sleep window — null means "not set"
  int? _sleepStart;
  int? _sleepEnd;

  bool _saving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Load current values from DataService (already synced from Firestore)
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrent());
  }

  void _loadCurrent() {
    final ds = context.read<DataService>();
    final ac = ds.getOrCreateActivityCheck(widget.elderly.id);
      setState(() {
        _autoEnabled   = ac.autoCheckInEnabled;
        _intervalHours = ac.checkInIntervalHours;
        _trackUnlock   = ac.trackPhoneUnlock;
        _trackSteps    = ac.trackStepsActive;
        _trackPickup   = ac.trackPhonePickup;
        _sleepStart    = ac.sleepStartHour;
        _sleepEnd      = ac.sleepEndHour;
      });
    setState(() => _loaded = true);
  }

  // ── Save both settings + sleep window ────────────────────────────────────
  Future<void> _save() async {
    // Validate sleep window: if one is set, both must be set
    if ((_sleepStart == null) != (_sleepEnd == null)) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.sleepValidationError),
        backgroundColor: AppTheme.sosRed,
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      final ds = context.read<DataService>();

      // Save auto check-in settings
      await ds.setCheckInTypeSettings(
        elderlyId:       widget.elderly.id,
        enabled:         _autoEnabled,
        intervalHours:   _intervalHours,
        trackPhoneUnlock: _trackUnlock,
        trackStepsActive: _trackSteps,
        trackPhonePickup: _trackPickup,
      );

      // Save sleep window
      await ds.setSleepWindow(
        elderlyId: widget.elderly.id,
        startHour: _sleepStart,
        endHour:   _sleepEnd,
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.settingsSaved),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.saveFailed(e.toString())),
          backgroundColor: AppTheme.sosRed,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmtHour(int h) =>
      DateFormat('h:00 a').format(DateTime(2000, 1, 1, h));

  // Dropdown items for 24-hour clock
  List<DropdownMenuItem<int>> get _hourItems => List.generate(24, (i) => i)
      .map((h) => DropdownMenuItem(value: h, child: Text(_fmtHour(h))))
      .toList();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final displayName =
        context.watch<DataService>().getNickname(widget.elderly.id) ??
            widget.elderly.name;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.configureTitle(displayName)),
        actions: const [LanguageButton()],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                const SizedBox(height: 16),

                // ── Section 1: Manual check-in (read-only) ────────────────
                _SectionHeader(
                  icon: Icons.touch_app_rounded,
                  title: l10n.manualCheckInSection,
                  color: AppTheme.primary,
                ),
                _ReadOnlyCard(
                  icon: Icons.touch_app_rounded,
                  title: l10n.manualCheckInSection,
                  subtitle: l10n.manualCheckInAlwaysOn,
                  trailing: _Pill(label: l10n.alwaysOn, color: AppTheme.success),
                ),

                const SizedBox(height: 20),

                // ── Section 2: Auto check-in master toggle ────────────────
                _SectionHeader(
                  icon: Icons.sensors_rounded,
                  title: l10n.automaticSignals,
                  color: AppTheme.primary,
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n.enableAutoTracking,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      subtitle: Text(
                        l10n.autoTrackingSubtitle,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _autoEnabled,
                      activeColor: AppTheme.primary,
                      onChanged: (v) => setState(() => _autoEnabled = v),
                    ),
                  ),
                ),

                // ── Signal toggles (only visible when auto is enabled) ─────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _autoEnabled
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            _SignalToggleCard(
                              icon: Icons.lock_open_rounded,
                              title: l10n.phoneUnlockLabel,
                              subtitle: l10n.phoneUnlockSubtitle,
                              value: _trackUnlock,
                              onChanged: (v) =>
                                  setState(() => _trackUnlock = v),
                            ),
                            const SizedBox(height: 8),
                            _SignalToggleCard(
                              icon: Icons.directions_walk_rounded,
                              title: l10n.stepsWalking,
                              subtitle: l10n.stepsWalkingSubtitle,
                              value: _trackSteps,
                              onChanged: (v) =>
                                  setState(() => _trackSteps = v),
                            ),
                            const SizedBox(height: 8),
                            _SignalToggleCard(
                              icon: Icons.phone_in_talk_rounded,
                              title: l10n.phonePickupLabel,
                              subtitle: l10n.phonePickupSubtitle,
                              value: _trackPickup,
                              onChanged: (v) =>
                                  setState(() => _trackPickup = v),
                            ),

                            const SizedBox(height: 20),

                            // ── Alert window slider ───────────────────────
                            _SectionHeader(
                              icon: Icons.timer_rounded,
                              title: l10n.alertWindowSection,
                              color: AppTheme.primary,
                            ),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_rounded,
                                            color: AppTheme.primary,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.alertAfterHours(_intervalHours),
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary
                                                .withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$_intervalHours h',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      l10n.alertWindowDesc,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary),
                                    ),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppTheme.primary,
                                        thumbColor: AppTheme.primary,
                                        overlayColor: AppTheme.primary
                                            .withOpacity(0.15),
                                        inactiveTrackColor: AppTheme.primary
                                            .withOpacity(0.2),
                                        valueIndicatorColor: AppTheme.primary,
                                        showValueIndicator:
                                            ShowValueIndicator.always,
                                      ),
                                      child: Slider(
                                        value: _intervalHours.toDouble(),
                                        min: 2,
                                        max: 12,
                                        divisions: 10,
                                        label: '$_intervalHours h',
                                        onChanged: (v) => setState(
                                            () => _intervalHours = v.toInt()),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('2h',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary)),
                                          Text(l10n.defaultTenH,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary)),
                                          Text('12h',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppTheme.textSecondary)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // ── Section 3: Sleep Window ────────────────────────────────
                _SectionHeader(
                  icon: Icons.bedtime_rounded,
                  title: l10n.sleepWindowSection,
                  color: AppTheme.accent,
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sleepWindowPauseDesc,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),

                        // Current status chip
                        if (_sleepStart != null && _sleepEnd != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppTheme.accent.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bedtime_rounded,
                                    color: AppTheme.accent, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  '${_fmtHour(_sleepStart!)} → ${_fmtHour(_sleepEnd!)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.accent,
                                      fontSize: 15),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _sleepStart = null;
                                    _sleepEnd = null;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.sosRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(l10n.clearLabel,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.sosRed,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        Row(
                          children: [
                            // Sleep start
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.nights_stay_rounded,
                                          size: 15, color: AppTheme.accent),
                                      const SizedBox(width: 4),
                                      Text(l10n.sleepTimeLabel,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _HourDropdown(
                                    value: _sleepStart,
                                    items: _hourItems,
                                    hint: l10n.notSet,
                                    onChanged: (v) =>
                                        setState(() => _sleepStart = v),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Wake time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.wb_sunny_rounded,
                                          size: 15, color: Colors.orange),
                                      const SizedBox(width: 4),
                                      Text(l10n.wakeTimeLabel,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  _HourDropdown(
                                    value: _sleepEnd,
                                    items: _hourItems,
                                    hint: l10n.notSet,
                                    onChanged: (v) =>
                                        setState(() => _sleepEnd = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_sleepStart == null && _sleepEnd == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.noSleepWindowSet,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

      // ── Sticky save button ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, size: 22),
                  label: Text(l10n.saveAndSync,
                      style: const TextStyle(fontSize: 17)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────


class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _ReadOnlyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}

class _SignalToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SignalToggleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? AppTheme.primary : AppTheme.textSecondary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: color)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              activeColor: AppTheme.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _HourDropdown extends StatelessWidget {
  final int? value;
  final List<DropdownMenuItem<int>> items;
  final String hint;
  final ValueChanged<int?> onChanged;

  const _HourDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(color: AppTheme.textSecondary)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
