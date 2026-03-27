// lib/widgets/sos_button.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/data_service.dart';
import '../l10n/app_localizations.dart';
import '../models/user_model.dart';

import '../theme/app_theme.dart';

class SosButton extends StatelessWidget {
  const SosButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<DataService>().currentUser;
    if (user == null || user.role != UserRole.elderly) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton(
        onPressed: () => _showSosDialog(context, user),
        backgroundColor: AppTheme.sosRed,
        foregroundColor: Colors.white,
        elevation: 10,
        shape: const CircleBorder(),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_rounded, size: 26, color: Colors.white),
            SizedBox(height: 2),
            Text(
              'SOS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSosDialog(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Read l10n inside the dialog builder so it always has context
        final dialogL10n = AppLocalizations.of(ctx);
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppTheme.sosRedLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_rounded,
                            color: AppTheme.sosRed, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dialogL10n.sendSOS,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.sosRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    dialogL10n.sosDesc,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      hintText: dialogL10n.sosHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52)),
                          child: Text(dialogL10n.cancel,
                              style: const TextStyle(fontSize: 17)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.sosRed,
                            minimumSize: const Size(0, 52),
                          ),
                          icon: const Icon(Icons.send_rounded),
                          label: Text(dialogL10n.sendSOSButton,
                              style: const TextStyle(fontSize: 17)),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _triggerSos(
                                context, user, controller.text.trim(), l10n);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _triggerSos(BuildContext context, UserModel user,
      String description, AppLocalizations l10n) async {
    final ds = context.read<DataService>();
    try {
      await ds.triggerSos(
        elderlyId: user.id,
        description:
        description.isEmpty ? 'Emergency! Please help.' : description,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sosSent,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600)),
            backgroundColor: AppTheme.sosRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
