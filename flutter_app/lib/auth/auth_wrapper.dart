import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_app/pages/homepage.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool showLogin = false; // false = Signup, true = Login

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user is logged in
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // Logged in
        if (session != null) {
          return const HomePage();
        }

        // Logged out → switch between Login & Signup
        return showLogin
            ? LoginPage(
                onSwitch: () {
                  setState(() => showLogin = false);
                },
              )
            : SignupPage(
                onSwitch: () {
                  setState(() => showLogin = true);
                },
              );
      },
    );
  }
}
