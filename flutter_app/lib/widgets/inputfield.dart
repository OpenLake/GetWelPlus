import 'package:flutter/material.dart';

class Inputfield extends StatelessWidget {
  final String hint_text;
  final TextEditingController controller;
  final bool hidetext;
  const Inputfield({super.key,
    required this.hint_text,
    required this.controller,
     this.hidetext=false,
  });

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
              borderSide: BorderSide(
            color: color
          ),
          borderRadius: BorderRadius.circular(17),
        
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: hidetext,
      validator: (val){
        if(val!.trim().isEmpty){
          return "$hint_text is missing";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint_text,
        contentPadding: EdgeInsets.all(21),
        enabledBorder: _border(Color.fromARGB(255, 103, 102, 102)),

        focusedBorder: _border(Color.fromARGB(255, 70, 155, 81))
      ),
    );
  }
}