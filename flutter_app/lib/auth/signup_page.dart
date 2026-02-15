import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/auth_button.dart';
import 'package:flutter_app/widgets/inputfield.dart';
import 'package:flutter_app/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const SignupPage({super.key, required this.onSwitch});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final formkey = GlobalKey<FormState>();
  final authService = AuthService();
  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    // Validate fields
    if (name.text.isEmpty || email.text.isEmpty || pass.text.isEmpty) {
      setState(() {
        errorMessage = 'Please fill all fields';
        isLoading = false;
      });
      return;
    }

    // Validate password length
    if (pass.text.length < 6) {
      setState(() {
        errorMessage = 'Password must be at least 6 characters';
        isLoading = false;
      });
      return;
    }

    try {
      await authService.signUp(
        email: email.text.trim(),
        password: pass.text.trim(),
        name: name.text.trim(),
      );
      // Navigation handled by AuthWrapper
    } on AuthException catch (e) {
      setState(() {
        errorMessage = e.message;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Signup failed. Please try again.';
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
                const SizedBox(height: 20),
                const SizedBox(height: 10),
                Inputfield(hint_text: "Name", controller: name),
                const SizedBox(height: 20),
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
                    : AuthButton(label: "Sign Up", onPressed: _handleSignup),
                if (errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: widget.onSwitch,
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: "  Log In",
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
