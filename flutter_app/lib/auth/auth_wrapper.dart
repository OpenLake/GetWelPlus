import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Logged in
        if (snapshot.hasData) {
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
