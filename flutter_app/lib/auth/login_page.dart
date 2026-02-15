import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/auth_button.dart';
import 'package:flutter_app/widgets/inputfield.dart';
import 'package:flutter_app/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginPage({super.key, required this.onSwitch});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final formkey = GlobalKey<FormState>();
  final authService = AuthService();
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    if (email.text.isEmpty || pass.text.isEmpty) {
      setState(() {
        errorMessage = 'Please enter email and password';
        isLoading = false;
      });
      return;
    }

    try {
      await authService.signIn(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
      // Navigation handled by AuthWrapper
    } on AuthException catch (e) {
      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Login failed. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final success = await authService.signInWithGoogle();
      if (!success) {
        setState(() {
          errorMessage = 'Google sign-in was cancelled';
          isLoading = false;
        });
      }
      // Navigation handled by AuthWrapper
    } on AuthException catch (e) {
      setState(() {
        errorMessage = 'Google sign-in failed: ${e.message}';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Google sign-in failed. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(27.0),
          child: Form(
            key: formkey,
            child: Column(
              children: [
                const SizedBox(height: 140),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: "GetWel"),
                      TextSpan(
                        text: "+",
                        style: TextStyle(color: Color(0xFF4CAF50)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Inputfield(hint_text: "Email", controller: email),
                const SizedBox(height: 20),
                Inputfield(
                  hint_text: "Password",
                  controller: pass,
                  hidetext: true,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : AuthButton(label: "Log In", onPressed: _handleLogin),
                if (errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 20),
                const Text(
                  "OR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                // Google Sign-In Button
                isLoading
                    ? const SizedBox.shrink()
                    : OutlinedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          fixedSize: const Size(250, 50),
                          side: const BorderSide(
                            color: Color(0xFF4CAF50),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.g_mobiledata,
                              size: 28,
                              color: Color(0xFF4CAF50),
                            );
                          },
                        ),
                        label: const Text(
                          "Sign in with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onSwitch,
                  child: RichText(
                    text: const TextSpan(
                      text: 'Don\'t have an account?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: "  Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
