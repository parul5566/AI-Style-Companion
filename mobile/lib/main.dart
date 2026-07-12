/// AI Style Companion — Flutter app entry point.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'data/providers/auth_provider.dart';
import 'data/services/api_client.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/main_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  runApp(const AIStyleCompanionApp());
}

class AIStyleCompanionApp extends StatelessWidget {
  const AIStyleCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
      ],
      child: MaterialApp(
        title: 'AI Style Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes the user to welcome, login, onboarding, or main app based on auth state.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showWelcome = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Not logged in → show welcome screen or auth flow
        if (!auth.isLoggedIn) {
          if (_showWelcome) {
            return WelcomeScreen(
              onGetStarted: () => setState(() => _showWelcome = false),
              onLogin: () => setState(() => _showWelcome = false),
            );
          }
          return AuthFlow();
        }

        // Logged in but no onboarding → show onboarding
        if (auth.needsOnboarding) {
          return const OnboardingScreen();
        }

        // Logged in + onboarded → main app
        return const MainNav();
      },
    );
  }
}

/// Handles switching between login and register screens.
class AuthFlow extends StatefulWidget {
  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

class _AuthFlowState extends State<AuthFlow> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(onRegisterTap: () => setState(() => _showLogin = false));
    }
    return RegisterScreen(onLoginTap: () => setState(() => _showLogin = true));
  }
}
