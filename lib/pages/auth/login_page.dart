// lib/pages/auth/login_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../services/background_service.dart';
import '../../widgets/language_button_login.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import '../elderly/elderly_home_page.dart';
import '../caregiver/caregiver_home_page.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({Key? key, this.size = 120.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval( // <--- This "clips" anything outside the circle
      child: Image.asset(
        'assets/images/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Note: Using BoxFit.cover ensures the blue fills the circle
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Load saved credentials ─────────────────────────────────────────────
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final remember = prefs.getBool('remember_me') ?? false;
    if (remember && savedEmail != null && savedPassword != null) {
      setState(() {
        _emailCtrl.text = savedEmail;
        _passwordCtrl.text = savedPassword;
        _rememberMe = true;
      });
    }
  }

  // ── Save or clear credentials ──────────────────────────────────────────
  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final ds = context.read<DataService>();
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final user = await ds.login(email, password);
      await _saveCredentials(email, password);
      if (!mounted) return;
      if (user.role == UserRole.elderly) {
        await BackgroundServiceHelper.startForElderly(user.id, user.name);
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ElderlyHomePage()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CaregiverHomePage()));
      }
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Branding ───────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      AppLogo(size: 120),
                      const SizedBox(height: 20),
                      Text(l10n.appName,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primary,
                          )),
                      const SizedBox(height: 6),
                      Text(l10n.tagline,
                          style: const TextStyle(
                            fontSize: 17,
                            color: AppTheme.textSecondary,
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Email ──────────────────────────────────────────────────
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

                // ── Password ───────────────────────────────────────────────
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
                  validator: (v) =>
                  (v == null || v.isEmpty) ? l10n.password : null,
                ),

                const SizedBox(height: 8),

                // ── Remember me checkbox ────────────────────────────────────
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      activeColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _rememberMe = !_rememberMe),
                      child: Text(
                        l10n.rememberMe,
                        style: const TextStyle(
                          fontSize: 17,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Forgot password — own line below, wraps freely ──────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 4),
                    ),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage())),
                    child: Text(
                      l10n.forgotPassword,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      // Allow wrapping on long translations (Tamil)
                      softWrap: true,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Login button ───────────────────────────────────────────
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login_rounded, size: 26),
                  label: Text(l10n.login),
                ),

                const SizedBox(height: 32),

                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l10n.noAccount,
                          style: const TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SignupPage())),
                  icon: const Icon(Icons.person_add_rounded, size: 26),
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