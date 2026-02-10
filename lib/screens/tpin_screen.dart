import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/pin_provider.dart';

class TpinScreen extends ConsumerStatefulWidget {
  final String accountNumber;
  const TpinScreen({super.key, required this.accountNumber});

  @override
  ConsumerState<TpinScreen> createState() => _TpinScreenState();
}

class _TpinScreenState extends ConsumerState<TpinScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    _f1.dispose();
    _f2.dispose();
    super.dispose();
  }

  // Updated to handle the boolean result directly
  void _handleSetPin() async {
    final pin = _pinController.text;
    final confirmPin = _confirmController.text;

    if (pin.length < 6) {
      _showSnackBar("PIN must be 6 digits", kErrorRed);
      return;
    }
    if (pin != confirmPin) {
      _showSnackBar("PINs do not match", kErrorRed);
      return;
    }

    final success = await ref.read(pinNotifierProvider.notifier).setTransactionPin(
        widget.accountNumber,
        pin
    );

    if (success) {
      _showSuccessDialog();
    } else {
      final error = ref.read(pinNotifierProvider).errorMessage;
      _showSnackBar(error.isNotEmpty ? error : "Failed to set PIN", kErrorRed);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color)
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
        title: const Icon(Icons.check_circle, color: kSuccessGreen, size: kIconSizeXXL),
        content: const Text("Transaction PIN Set Successfully!",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to Dashboard
              },
              child: const Text("DONE", style: TextStyle(color: kBrandNavy, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinState = ref.watch(pinNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Set Transaction PIN"),
        backgroundColor: kAccentOrange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text("Account: ${widget.accountNumber}",
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 40),

            _buildLabel("Enter New 6-Digit PIN"),
            _buildPinBoxes(_pinController, _f1),

            const SizedBox(height: 24),

            _buildLabel("Confirm New PIN"),
            _buildPinBoxes(_confirmController, _f2),

            const SizedBox(height: 50),

            // Pass pinState.isLoading to show the loader
            _buildButton("SET PIN", _handleSetPin, pinState.isLoading),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(fontSize: 14, color: kBrandNavy, fontWeight: FontWeight.w600)),
  );

  Widget _buildButton(String text, VoidCallback onPressed, bool loading) {
    return SizedBox(
      width: double.infinity,
      height: kButtonHeight,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
        child: loading
            ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
        )
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPinBoxes(TextEditingController controller, FocusNode node) {
    return Stack(
      children: [
        Opacity(
          opacity: 0,
          child: TextField(
            controller: controller,
            focusNode: node,
            keyboardType: TextInputType.number,
            maxLength: 6,
            onChanged: (v) {
              if (v.length == 6 && node == _f1) _f2.requestFocus();
              setState(() {});
            },
          ),
        ),
        GestureDetector(
          onTap: () => node.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => Container(
              width: 45, height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(kRadiusSmall),
                border: Border.all(
                    color: controller.text.length > index ? kAccentOrange : Colors.grey.shade300,
                    width: 1.5
                ),
              ),
              child: Center(
                  child: controller.text.length > index
                      ? const Icon(Icons.circle, size: 10, color: kBrandNavy)
                      : null
              ),
            )),
          ),
        ),
      ],
    );
  }
}