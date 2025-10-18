import 'package:flutter/material.dart';
import '../constants.dart'; // updated import path

class CustomTextField extends StatelessWidget {
  final IconData icon;
  final bool obscureText;
  final String hintText;

  const CustomTextField({
    super.key,
    required this.icon,
    required this.obscureText,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Constants.blackColor),
      decoration: InputDecoration(
        border: InputBorder.none,
        prefixIcon:
            Icon(icon, color: Constants.blackColor.withValues(alpha: 0.3)),
        hintText: hintText,
      ),
      cursorColor: Constants.blackColor.withValues(alpha: 0.5),
    );
  }
}
