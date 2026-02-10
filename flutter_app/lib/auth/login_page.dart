import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/auth_button.dart';
import 'package:flutter_app/widgets/inputfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
class LoginPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const LoginPage({super.key,
      required this.onSwitch,
  
  });

  @override

  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final formkey = GlobalKey<FormState>();
  String? errorMessage;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) {
    return  Scaffold(
      // appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(27.0),
            child: Form(
              key: formkey,
              child: Column(
                children: [
                  SizedBox(height: 140,),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                        ),
                        children: const [
                          TextSpan(text: "GetWel"),
                          TextSpan(
                            text: "+",
                            style: TextStyle(color: Color(0xFF4CAF50)),
                          ),
                        ],
                      ),
                    ),
              
                  SizedBox(height: 30,),
                  Inputfield(hint_text: "Email",controller: email,),
                  SizedBox(height: 20,),
                  Inputfield(hint_text: "Password",controller: pass,hidetext: true,),
                  SizedBox(height: 20,),
                  AuthButton(label: "Log In",
                      onPressed: () async {
                        setState(() {
                          errorMessage = null;
                        });

                        if (email.text.isEmpty || pass.text.isEmpty) {
                          setState(() {
                            errorMessage = 'Please enter email and password';
                          });
                          return;
                        }

                        try {
                          await FirebaseAuth.instance.signInWithEmailAndPassword(
                            email: email.text.trim(),
                            password: pass.text.trim(),
                          );
                        } on FirebaseAuthException catch (e) {
                          setState(() {
                            if (e.code == 'user-not-found') {
                              errorMessage = 'User not found';
                            } else if (e.code == 'wrong-password') {
                              errorMessage = 'Incorrect password';
                            } else {
                              errorMessage = 'Login failed';
                            }
                          });
                        }
                      },

                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    SizedBox(height: 20,),
                    GestureDetector(
                    onTap: () {
                          widget.onSwitch();
                    },
                    child: RichText(text: TextSpan(
                        text: 'Don\'t have an account?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700
                        ),
                        children: [
                          TextSpan(text: "  Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50)
                            )
                          )
                                    
                        ]
                      )),
                  ),
                
              
              
                ],
              ),
            ),
          ),
        ),
      
    );
  }
}