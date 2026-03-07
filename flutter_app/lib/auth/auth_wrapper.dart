import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/pages/homepage.dart';
import 'package:flutter_app/pages/onboarding_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'package:flutter_app/pages/admin_dashboard.dart';
import 'package:flutter_app/auth/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool showLogin = false;
  bool? _onboardingComplete;
  bool _checkingOnboarding = false;
  bool? _isAdmin;
  bool _checkingAdmin = false;

  Future<void> _checkAdminStatus(String userId) async {
    if (_checkingAdmin) return;
    _checkingAdmin = true;

    try {
      final authService = AuthService();
      final adminCheck = await authService.isAdmin(userId);
      if (mounted) {
        setState(() {
          _isAdmin = adminCheck;
          _checkingAdmin = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _checkingAdmin = false;
        });
      }
    }
  }

  Future<void> _checkOnboardingStatus(String userId) async {
    if (_checkingOnboarding) return;
    _checkingOnboarding = true;

    try {
      final profile = await Supabase.instance.client
          .from('patient_profiles')
          .select('onboarding_complete')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _onboardingComplete = profile?['onboarding_complete'] == true;
          _checkingOnboarding = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _onboardingComplete = false;
          _checkingOnboarding = false;
        });
      }
    }
  }

  void _completeOnboarding() {
    setState(() => _onboardingComplete = true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.hasData ? snapshot.data!.session : null;

        if (session != null) {
          if (_isAdmin == null && !_checkingAdmin) {
            _checkAdminStatus(session.user.id);
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_isAdmin == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_isAdmin == true) {
            return const AdminDashboard();
          }

          if (_onboardingComplete == null && !_checkingOnboarding) {
            _checkOnboardingStatus(session.user.id);
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_onboardingComplete == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (_onboardingComplete == false) {
            return OnboardingPage(onComplete: _completeOnboarding);
          }

          return const HomePage();
        }

        if (_onboardingComplete != null) {
          _onboardingComplete = null;
        }

        if (_isAdmin != null) {
          _isAdmin = null;
        }

        return showLogin
            ? LoginPage(onSwitch: () => setState(() => showLogin = false))
            : SignupPage(onSwitch: () => setState(() => showLogin = true));
      },
    );
  }
}