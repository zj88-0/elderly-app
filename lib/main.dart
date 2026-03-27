// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/data_service.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'models/user_model.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'pages/auth/login_page.dart';
import 'pages/elderly/elderly_home_page.dart';
import 'pages/caregiver/caregiver_home_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must initialise before anything else
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  await NotificationService.requestPermissions();
  await initBackgroundService();

  final dataService = DataService();
  await dataService.init();

  final localeProvider = LocaleProvider();
  await localeProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DataService>.value(value: dataService),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: const ElderCareApp(),
    ),
  );
}

class ElderCareApp extends StatelessWidget {
  const ElderCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().locale;
    return MaterialApp(
      title: 'VisionGuard SG',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _SplashRouter(),
    );
  }
}

class _SplashRouter extends StatefulWidget {
  const _SplashRouter();

  @override
  State<_SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<_SplashRouter> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _SplashScreen();
    final user = context.watch<DataService>().currentUser;
    if (user == null) return const LoginPage();
    if (user.role == UserRole.elderly) return const ElderlyHomePage();
    return const CaregiverHomePage();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLogo(size: 120),
            const SizedBox(height: 24),
            const Text(
              'VisionGuard SG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your family, always connected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}