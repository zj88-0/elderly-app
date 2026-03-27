// lib/pages/elderly/wellbeing_page.dart
// Daily wellbeing questionnaire for elderly users.
// Simple emoji-based scoring (1–5) — friendly, large UI.
// Results viewable by all caregivers in the group.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/wellbeing_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';
import '../../widgets/sos_button.dart';

class WellbeingPage extends StatefulWidget {
  const WellbeingPage({super.key});

  @override
  State<WellbeingPage> createState() => _WellbeingPageState();
}

class _WellbeingPageState extends State<WellbeingPage> {
  // Scores for each question: 1–5
  final Map<String, int> _scores = {
    'mood': 3,
    'pain': 3,
    'sleep': 3,
    'appetite': 3,
    'lonely': 3,
  };
  bool _saving = false;

  // Emoji labels per score level
  static const List<String> _emojis = ['😢', '😕', '😐', '🙂', '😄'];

  // Colors per score
  static const List<Color> _scoreColors = [
    Color(0xFFD32F2F), // 1 - red
    Color(0xFFE65100), // 2 - deep orange
    Color(0xFFF9A825), // 3 - amber
    Color(0xFF388E3C), // 4 - green
    Color(0xFF1976D2), // 5 - blue
  ];

  Future<void> _save() async {
    final ds = context.read<DataService>();
    final user = ds.currentUser!;
    setState(() => _saving = true);
    try {
      final answers = _scores.entries
          .map((e) => WellbeingAnswer(questionKey: e.key, score: e.value))
          .toList();
      await ds.saveWellbeingEntry(elderlyId: user.id, answers: answers);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            AppLocalizations.of(context).wellbeingSaved,
            style: const TextStyle(fontSize: 18),
          ),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final user = ds.currentUser!;
    final existing = ds.getTodayWellbeing(user.id);

    // Pre-fill with today's existing answers if any
    if (existing != null && _scores.values.every((v) => v == 3)) {
      for (final a in existing.answers) {
        _scores[a.questionKey] = a.score;
      }
    }

    final questions = [
      _Question(key: 'mood', labelKey: 'wellbeingMood',
          iconData: Icons.sentiment_satisfied_alt_rounded),
      _Question(key: 'pain', labelKey: 'wellbeingPain',
          iconData: Icons.healing_rounded),
      _Question(key: 'sleep', labelKey: 'wellbeingSleep',
          iconData: Icons.bedtime_rounded),
      _Question(key: 'appetite', labelKey: 'wellbeingAppetite',
          iconData: Icons.restaurant_rounded),
      _Question(key: 'lonely', labelKey: 'wellbeingLonely',
          iconData: Icons.people_rounded),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyWellbeing),
        actions: const [LanguageButton()],
      ),
      floatingActionButton: const SosButton(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 40),
                const SizedBox(height: 10),
                Text(
                  l10n.wellbeingGreeting,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.wellbeingSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (existing != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.success.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.success, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.wellbeingAlreadyDone,
                      style: const TextStyle(
                          color: AppTheme.success,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Questions
          ...questions.map((q) {
            final score = _scores[q.key]!;
            final color = _scoreColors[score - 1];
            return _QuestionCard(
              question: q,
              score: score,
              color: color,
              emoji: _emojis[score - 1],
              label: l10n.get(q.labelKey),
              onChanged: (v) => setState(() => _scores[q.key] = v),
            );
          }),

          const SizedBox(height: 24),

          // Save button
          _saving
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_rounded, size: 28),
                  label: Text(
                    existing != null ? l10n.wellbeingUpdate : l10n.wellbeingSubmit,
                    style: const TextStyle(fontSize: 22),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(72),
                    backgroundColor: AppTheme.success,
                  ),
                ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Question {
  final String key;
  final String labelKey;
  final IconData iconData;
  const _Question(
      {required this.key, required this.labelKey, required this.iconData});
}

class _QuestionCard extends StatelessWidget {
  final _Question question;
  final int score;
  final Color color;
  final String emoji;
  final String label;
  final ValueChanged<int> onChanged;

  const _QuestionCard({
    required this.question,
    required this.score,
    required this.color,
    required this.emoji,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question label
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(question.iconData, color: color, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Big emoji display
            Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 56),
              ),
            ),
            const SizedBox(height: 12),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: color,
                thumbColor: color,
                inactiveTrackColor: color.withOpacity(0.2),
                overlayColor: color.withOpacity(0.15),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 16),
                trackHeight: 8,
              ),
              child: Slider(
                value: score.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            // Score labels row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final isSelected = score == i + 1;
                  return GestureDetector(
                    onTap: () => onChanged(i + 1),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: color, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Wellbeing view for caregivers ──────────────────────────────────────────
class WellbeingViewPage extends StatelessWidget {
  final String elderlyId;
  final String elderlyName;

  const WellbeingViewPage({
    super.key,
    required this.elderlyId,
    required this.elderlyName,
  });

  static const List<String> _emojis = ['😢', '😕', '😐', '🙂', '😄'];

  static const List<Color> _scoreColors = [
    Color(0xFFD32F2F),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    Color(0xFF388E3C),
    Color(0xFF1976D2),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ds = context.watch<DataService>();
    final history = ds.getWellbeingHistory(elderlyId, days: 7);
    final today = ds.getTodayWellbeing(elderlyId);

    return Scaffold(
      appBar: AppBar(
        title: Text('$elderlyName – ${l10n.dailyWellbeing}'),
        actions: const [LanguageButton()],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64,
                      color: AppTheme.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(l10n.noWellbeingData,
                      style: const TextStyle(
                          fontSize: 18, color: AppTheme.textSecondary)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Today summary
                if (today != null) ...[
                  _SummaryCard(entry: today, l10n: l10n),
                  const SizedBox(height: 16),
                ],

                Text(l10n.wellbeingHistory,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),

                ...history.map((entry) => _HistoryCard(
                      entry: entry,
                      l10n: l10n,
                      emojis: _emojis,
                      colors: _scoreColors,
                    )),
              ],
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final WellbeingEntry entry;
  final AppLocalizations l10n;
  const _SummaryCard({required this.entry, required this.l10n});

  static const List<Color> _scoreColors = [
    Color(0xFFD32F2F),
    Color(0xFFE65100),
    Color(0xFFF9A825),
    Color(0xFF388E3C),
    Color(0xFF1976D2),
  ];

  @override
  Widget build(BuildContext context) {
    final avg = entry.averageScore;
    final color = _scoreColors[(avg.round() - 1).clamp(0, 4)];
    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today_rounded, color: color, size: 24),
                const SizedBox(width: 8),
                Text(l10n.todayWellbeing,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${avg.toStringAsFixed(1)} / 5',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: entry.answers.map((a) {
                final c = _scoreColors[(a.score - 1).clamp(0, 4)];
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.get(
                          'wellbeing${_capitalize(a.questionKey)}'),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Text('${a.score}/5',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: c)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _HistoryCard extends StatelessWidget {
  final WellbeingEntry entry;
  final AppLocalizations l10n;
  final List<String> emojis;
  final List<Color> colors;
  const _HistoryCard(
      {required this.entry,
      required this.l10n,
      required this.emojis,
      required this.colors});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final avg = entry.averageScore;
    final color = colors[(avg.round() - 1).clamp(0, 4)];
    final emoji = emojis[(avg.round() - 1).clamp(0, 4)];

    final dateStr = locale == 'zh'
        ? '${entry.date.month}月${entry.date.day}日'
        : DateFormat('d MMM yyyy').format(entry.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: entry.answers.map((a) {
                      final c = colors[(a.score - 1).clamp(0, 4)];
                      return Text(
                        '${l10n.get('wellbeing${_cap(a.questionKey)}')} ${a.score}',
                        style: TextStyle(
                            fontSize: 12, color: c, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                avg.toStringAsFixed(1),
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
