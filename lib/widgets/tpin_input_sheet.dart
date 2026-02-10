import 'package:flutter/material.dart';

class TpinInputSheet extends StatefulWidget {
  final Function(String) onConfirm;

  const TpinInputSheet({super.key, required this.onConfirm});

  @override
  State<TpinInputSheet> createState() => _TpinInputSheetState();
}

class _TpinInputSheetState extends State<TpinInputSheet> {
  final TextEditingController _pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Moves up with keyboard
        left: 24, right: 24, top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("Authorize Payment", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Enter your 6-digit T-PIN to proceed", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),

          TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            style: const TextStyle(fontSize: 26, letterSpacing: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (_pinController.text.length == 6) {
                  widget.onConfirm(_pinController.text);
                }
              },
              child: const Text("AUTHORIZE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}