import 'package:flutter/material.dart';
import 'package:flutter_app/widgets/auth_button.dart';
import 'package:flutter_app/widgets/inputfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onSwitch;
  const SignupPage({super.key,
    required this.onSwitch,
  });

  @override

  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final formkey = GlobalKey<FormState>();
  String? errorMessage;

  @override
  void dispose() {
    name.dispose();
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
              
                  SizedBox(height: 20,),
                  SizedBox(height: 10,),
                  Inputfield(hint_text: "Name",controller: name,),
                  SizedBox(height: 20,),
                  Inputfield(hint_text: "Email",controller: email,),
                  SizedBox(height: 20,),
                  Inputfield(hint_text: "Password",controller: pass,hidetext: true,),
                  SizedBox(height: 20,),
                  AuthButton(
                    label: "Sign Up",
                    onPressed: () async {
                      // clear old error
                      setState(() {
                        errorMessage = null;
                      });

                      // manual validation (no TextField resize)
                      if (name.text.isEmpty ||
                          email.text.isEmpty ||
                          pass.text.isEmpty) {
                        setState(() {
                          errorMessage = 'Please fill all fields';
                        });
                        return;
                      }

                      try {
                        await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: email.text.trim(),
                          password: pass.text.trim(),
                        );
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .set({
                                'name': name.text.trim(),
                                'email': user.email,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                        }                        
                      } on FirebaseAuthException catch (e) {
                        setState(() {
                          if (e.code == 'email-already-in-use') {
                            errorMessage = 'Email already in use';
                          } else if (e.code == 'weak-password') {
                            errorMessage = 'Password is too weak';
                          } else if (e.code == 'invalid-email') {
                            errorMessage = 'Invalid email address';
                          } else {
                            errorMessage = 'Signup failed';
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
                        text: 'Already have an account?',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700
                        ),
                        children: [
                          TextSpan(text: "  Log In",
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