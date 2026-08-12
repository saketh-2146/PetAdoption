import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'firebase_options.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'services/seed_service.dart';
import 'package:petconnect/l10n/app_localizations.dart';

import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/root_shell.dart';
import 'screens/admin_dashboard_screen.dart';
import 'services/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PetConnectApp());
}

class PetConnectApp extends StatefulWidget {
  const PetConnectApp({super.key});

  @override
  State<PetConnectApp> createState() => _PetConnectAppState();
}

class _PetConnectAppState extends State<PetConnectApp> {
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize Firebase first because it is required for AuthGate
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    
    // Fire and forget other initializations
    Future.microtask(() async {
      try {
        await Supabase.initialize(
          url: SupabaseConfig.supabaseUrl,
          publishableKey: SupabaseConfig.supabaseAnonKey,
        );
        debugPrint('Supabase initialized successfully');
      } catch (e) {
        debugPrint('Supabase initialization failed: $e');
      }
      await SeedService().clearAllPets();
      await SeedService().ensureAdminExists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppColors.cream,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: AppColors.cream,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Initialization Error:\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppState()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: Consumer<SettingsProvider>(
            builder: (context, settings, child) {
              return MaterialApp(
                title: 'PetConnect',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: settings.themeMode,
                locale: settings.locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const AuthGate(),
              );
            },
          ),
        );
      },
    );
  }
}

/// Decides which top-level screen to show:
/// 1. Onboarding carousel (first launch only, kept in memory for this session)
/// 2. Login screen (not signed in)
/// 3. RootShell with bottom nav (signed in)
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _onboarded = false;

  @override
  Widget build(BuildContext context) {
    if (!_onboarded) {
      return OnboardingScreen(onFinish: () => setState(() => _onboarded = true));
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        final user = snapshot.data;
        final appState = context.read<AppState>();
        // Keep AppState's liked-pet set in sync with the signed-in user.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appState.bindUser(user);
        });

        if (user == null) {
          return const LoginScreen();
        }

        return appState.loginRole == 'admin' ? const AdminDashboardScreen() : const RootShell();
      },
    );
  }
}
