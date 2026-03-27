// lib/widgets/language_button.dart
//
// Globe icon button shown in every AppBar.
// Tapping shows a bottom sheet to switch between EN / ZH / MS / TA.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language_rounded, size: 30,color: Colors.white,),
      tooltip: 'Change Language',
      onPressed: () => _showLanguagePicker(context),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeProvider = context.read<LocaleProvider>();
    final current = localeProvider.locale.languageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.selectLanguage,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...LocaleProvider.languageNames.entries.map((entry) {
              final isSelected = current == entry.key;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _flag(entry.key),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.primary : AppTheme.textPrimary,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded,
                        color: AppTheme.primary, size: 26)
                    : null,
                onTap: () async {
                  await localeProvider.setLocale(Locale(entry.key));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _flag(String code) {
    switch (code) {
      case 'en':
        return '🇬🇧';
      case 'zh':
        return '🇨🇳';
      case 'ms':
        return '🇲🇾';
      case 'ta':
        return '🇮🇳';
      default:
        return '🌐';
    }
  }
}
