import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'auth_service.dart';
import 'preferences_service.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';

class AppStartRouter extends StatelessWidget {
  const AppStartRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final preferencesService = Provider.of<PreferencesService>(context);
    final isOnboardingCompleted = preferencesService.isOnboardingCompleted;

    // 1. If onboarding is not completed, show OnboardingScreen
    if (!isOnboardingCompleted) {
      return const OnboardingScreen();
    }

    // 2. If onboarding is completed, react to auth state
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Connection state active means we have an initial value or updates
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          if (user == null) {
            // If user is not logged in, show the LoginScreen
            return const LoginScreen();
          } else {
            Future.microtask(() {
              context.read<AuthService>().configurePostLoginNotifications(user);
            });
            // If user is logged in, show the DashboardScreen
            return const DashboardScreen();
          }
        }

        // Show loading indicator while checking auth state
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          ),
        );
      },
    );
  }
}
