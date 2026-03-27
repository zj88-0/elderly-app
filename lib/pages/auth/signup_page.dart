// lib/pages/auth/signup_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  UserRole _selectedRole = UserRole.elderly;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<DataService>().createUser(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            role: _selectedRole,
            phoneNumber: _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.accountCreated,
            style: const TextStyle(fontSize: 17)),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pop(context);
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
        title: Text(l10n.signup),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Role picker ───────────────────────────────────────────
                Text(l10n.iAm,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        role: UserRole.elderly,
                        selectedRole: _selectedRole,
                        icon: Icons.elderly_rounded,
                        label: l10n.elderly,
                        description: l10n.elderlyDesc,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.elderly),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _RoleCard(
                        role: UserRole.caregiver,
                        selectedRole: _selectedRole,
                        icon: Icons.volunteer_activism_rounded,
                        label: l10n.caregiver,
                        description: l10n.caregiverDesc,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.caregiver),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Full name ─────────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
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
                const SizedBox(height: 16),

                // ── Phone ─────────────────────────────────────────────────
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: l10n.phoneNumber,
                    prefixIcon: const Icon(Icons.phone_rounded,
                        color: AppTheme.primary, size: 26),
                    hintText: '+65 9123 4567',
                  ),
                ),
                const SizedBox(height: 16),

                // ── Password ──────────────────────────────────────────────
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_rounded,
                        color: AppTheme.primary, size: 26),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textSecondary,
                        size: 26,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.password;
                    if (v.length < 6) return l10n.password;
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── Confirm password ──────────────────────────────────────
                TextFormField(
                  controller: _confirmCtrl,
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
                        size: 26,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      (v != _passwordCtrl.text) ? l10n.confirmPassword : null,
                ),

                const SizedBox(height: 32),

                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _signUp,
                        icon: const Icon(Icons.how_to_reg_rounded, size: 26),
                        label: Text(l10n.signup),
                      ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final UserRole selectedRole;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = role == selectedRole;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.divider,
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 48,
                color: isSelected ? Colors.white : AppTheme.primary),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                )),
            const SizedBox(height: 6),
            Text(description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected
                      ? Colors.white.withOpacity(0.85)
                      : AppTheme.textSecondary,
                  height: 1.4,
                )),
            const SizedBox(height: 10),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 26),
          ],
        ),
      ),
    );
  }
}
