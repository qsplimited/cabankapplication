// lib/screens/forgot_mpin_step2_new_mpin.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class ForgotMpinStep2NewMpin extends ConsumerStatefulWidget {
  const ForgotMpinStep2NewMpin({super.key});
  @override
  ConsumerState<ForgotMpinStep2NewMpin> createState() => _ForgotMpinStep2NewMpinState();
}

class _ForgotMpinStep2NewMpinState extends ConsumerState<ForgotMpinStep2NewMpin> {
  final _mpin = TextEditingController();
  final _confirm = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();

  @override
  void initState() {
    super.initState();
    // Re-render UI as user types to fill the boxes
    _mpin.addListener(() => setState(() {}));
    _confirm.addListener(() => setState(() {}));
  }

  void _onUpdate() {
    if (_mpin.text.length == 6 && _mpin.text == _confirm.text) {
      ref.read(registrationProvider.notifier).finalizeRegistration(_mpin.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("MPINs do not match or are incomplete"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for success to return to landing page (Test Mode)
    ref.listen(registrationProvider, (prev, next) {
      if (next.status == RegistrationStatus.success) {
        ref.read(registrationProvider.notifier).reset(); // Reset for next test
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    });

    final state = ref.watch(registrationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Reset MPIN"), backgroundColor: kAccentOrange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          children: [
            const Text("Enter New 6-Digit MPIN", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildPinRow(_mpin, _f1),
            const SizedBox(height: 40),
            const Text("Confirm New MPIN", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildPinRow(_confirm, _f2),
            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: state.status == RegistrationStatus.loading ? null : _onUpdate,
                style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                child: state.status == RegistrationStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("UPDATE MPIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinRow(TextEditingController controller, FocusNode node) {
    return Stack(
      children: [
        // Hidden TextField to capture input
        Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: node,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            )
        ),
        // Visual Boxes
        GestureDetector(
          onTap: () => node.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => Container(
              width: 48, height: 58,
              decoration: BoxDecoration(
                  color: node.hasFocus && controller.text.length == i ? kAccentOrange.withOpacity(0.1) : Colors.grey.shade100,
                  border: Border.all(color: node.hasFocus && controller.text.length == i ? kAccentOrange : Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Center(child: controller.text.length > i ? const Icon(Icons.circle, size: 14, color: Colors.black87) : null),
            )),
          ),
        )
      ],
    );
  }
}