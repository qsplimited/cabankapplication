import 'package:flutter/material.dart';

class TpinInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onComplete;

  const TpinInputWidget({
    super.key,
    required this.controller,
    required this.onComplete
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: true,
      maxLength: 6,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      autofocus: true,
      style: const TextStyle(
        fontSize: 24,
        letterSpacing: 20,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      decoration: InputDecoration(
        counterText: "", // Hides the 0/6 text
        hintText: "••••••",
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5), letterSpacing: 20),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        if (value.length == 6) onComplete();
      },
    );
  }
}