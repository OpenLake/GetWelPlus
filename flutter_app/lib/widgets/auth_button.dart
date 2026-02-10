import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const AuthButton({super.key,
  required this.label,
  required this.onPressed,
  
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(167, 50),
        backgroundColor: Color(0xFF4CAF50),
      ),
      child: 
            Text(label,style: 
              TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: Colors.black
              )
            ,)
      ),
    );
  }
}