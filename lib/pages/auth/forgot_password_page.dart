// lib/pages/auth/forgot_password_page.dart
// Firebase version: resetPassword sends an email via Firebase Auth.
// The old 2-step "verify email → set new password" flow is replaced with
// Firebase's standard email reset link, which is more secure.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      // Firebase Auth sends a password reset email directly.
      // resetPassword() in DataService calls:
      //   FirebaseAuth.instance.sendPasswordResetEmail(email: email)
      await context
          .read<DataService>()
          .resetPassword(_emailCtrl.text.trim(), '');
      if (mounted) setState(() => _emailSent = true);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.resetPassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            color: AppTheme.primary, size: 50),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.resetPassword,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Success state ─────────────────────────────────────────
                if (_emailSent) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppTheme.success.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_rounded,
                            color: AppTheme.success, size: 52),
                        const SizedBox(height: 16),
                        const Text(
                          'Reset email sent!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Check your inbox at\n${_emailCtrl.text.trim()}\nand follow the link to reset your password.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.success,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: Text(l10n.login,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ],

                // ── Input state ───────────────────────────────────────────
                if (!_emailSent) ...[
                  Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 18),
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
                  const SizedBox(height: 28),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton.icon(
                    onPressed: _sendResetEmail,
                    icon: const Icon(Icons.send_rounded, size: 24),
                    label: Text(l10n.findMyAccount,
                        style: const TextStyle(fontSize: 18)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}