// lib/pages/sos/sos_history_page.dart
//
// Detailed SOS history page. Shows all SOS alerts for a specific elderly user.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/checkin_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';
import '../../widgets/sos_button.dart';

class SosHistoryPage extends StatelessWidget {
  final String elderlyId;
  final String elderlyName;

  const SosHistoryPage({
    super.key,
    required this.elderlyId,
    required this.elderlyName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final ds = context.watch<DataService>();
    final history = ds.getSosHistoryForElderly(elderlyId);

    final activeCount = history.where((s) => s.status == SosStatus.active).length;
    final resolvedCount = history.where((s) => s.status == SosStatus.resolved).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.sosHistory} – $elderlyName'),
        actions: const [LanguageButton()],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64,
                      color: AppTheme.success.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSosHistory,
                    style: const TextStyle(
                        fontSize: 18, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Summary banner ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.sosRedLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.sosRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        label: l10n.total,
                        value: '${history.length}',
                        color: AppTheme.sosRed,
                        icon: Icons.warning_rounded,
                      ),
                      _StatChip(
                        label: l10n.active,
                        value: '$activeCount',
                        color: AppTheme.sosRed,
                        icon: Icons.notifications_active_rounded,
                      ),
                      _StatChip(
                        label: l10n.resolved,
                        value: '$resolvedCount',
                        color: AppTheme.success,
                        icon: Icons.check_circle_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── List ────────────────────────────────────────────────
                ...history.map((sos) {
                  final isActive = sos.status == SosStatus.active;
                  final triggeredStr = locale == 'zh'
                      ? '${sos.triggeredAt.year}年${sos.triggeredAt.month}月${sos.triggeredAt.day}日 ${DateFormat('HH:mm').format(sos.triggeredAt)}'
                      : DateFormat('d MMM yyyy, h:mm a').format(sos.triggeredAt);
                  final resolvedStr = sos.resolvedAt == null
                      ? null
                      : locale == 'zh'
                          ? '${sos.resolvedAt!.year}年${sos.resolvedAt!.month}月${sos.resolvedAt!.day}日 ${DateFormat('HH:mm').format(sos.resolvedAt!)}'
                          : DateFormat('d MMM yyyy, h:mm a').format(sos.resolvedAt!);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppTheme.sosRedLight
                                      : AppTheme.successLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isActive
                                      ? Icons.warning_rounded
                                      : Icons.check_circle_rounded,
                                  color: isActive
                                      ? AppTheme.sosRed
                                      : AppTheme.success,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? AppTheme.sosRed
                                            : AppTheme.success,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isActive ? l10n.active : l10n.resolved,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                TextButton(
                                  onPressed: () => ds.resolveSos(sos.id),
                                  child: Text(l10n.resolve,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.sosRed,
                                          fontWeight: FontWeight.w700)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            sos.description,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            label: l10n.triggered,
                            value: triggeredStr,
                            color: AppTheme.sosRed,
                          ),
                          if (resolvedStr != null)
                            _InfoRow(
                              icon: Icons.check_circle_outline_rounded,
                              label: l10n.resolvedAt,
                              value: resolvedStr,
                              color: AppTheme.success,
                            ),
                          if (sos.resolvedAt != null) ...[
                            const SizedBox(height: 4),
                            _InfoRow(
                              icon: Icons.timer_outlined,
                              label: l10n.duration,
                              value: _formatDuration(
                                  sos.resolvedAt!.difference(sos.triggeredAt)),
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '< 1 min';
    if (d.inHours < 1) return '${d.inMinutes} min';
    return '${d.inHours}h ${d.inMinutes.remainder(60)}min';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 13, color: color)),
          ),
        ],
      ),
    );
  }
}
