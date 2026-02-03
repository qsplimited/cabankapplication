import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step4_finalize.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class RegistrationStep3Mpin extends ConsumerStatefulWidget {
  const RegistrationStep3Mpin({super.key});

  @override
  ConsumerState<RegistrationStep3Mpin> createState() => _RegistrationStep3MpinState();
}

class _RegistrationStep3MpinState extends ConsumerState<RegistrationStep3Mpin> {
  final _mpinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _f1 = FocusNode();
  final _f2 = FocusNode();

  @override
  void initState() {
    super.initState();
    // Rebuild UI when typing to show/hide dots visually
    _mpinController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mpinController.dispose();
    _confirmController.dispose();
    _f1.dispose();
    _f2.dispose();
    super.dispose();
  }

  void _onContinue() {
    final mpin = _mpinController.text;
    final confirm = _confirmController.text;

    // 1. Check if both fields have 6 digits
    if (mpin.length != 6 || confirm.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter 6 digits for both fields"), backgroundColor: Colors.orange),
      );
      return;
    }

    // 2. Check if both fields match (CRITICAL for security)
    if (mpin != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("MPINs do not match!"), backgroundColor: Colors.red),
      );
      return;
    }

    // 3. Trigger the API: POST http://192.168.0.102:8088/customer/set/mpin
    ref.read(registrationProvider.notifier).finalizeRegistration(mpin);
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);

    // NAVIGATION LISTENER: Moves to the Final Success screen upon value: true from server
    ref.listen(registrationProvider, (previous, next) {
      if (next.status == RegistrationStatus.success && next.currentStep == 4) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegistrationStep4Finalize())
        );
      }

      if (next.status == RegistrationStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.errorMessage ?? "Failed to set MPIN"),
              backgroundColor: Colors.red
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Secure MPIN", style: TextStyle(color: Colors.white)),
        backgroundColor: kAccentOrange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Create New 6-Digit MPIN",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildPinRow(_mpinController, _f1),

            const SizedBox(height: 40),

            const Text("Confirm New MPIN",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
            const SizedBox(height: 12),
            _buildPinRow(_confirmController, _f2),

            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: regState.status == RegistrationStatus.loading ? null : _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                ),
                child: regState.status == RegistrationStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SET MPIN & BIND DEVICE",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        // Hidden input for keyboard capture
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 58,
            child: TextField(
              controller: controller,
              focusNode: node,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ""),
              onChanged: (val) {
                if (val.length == 6 && node == _f1) {
                  _f2.requestFocus(); // Auto-focus confirm field
                }
              },
            ),
          ),
        ),
        // Visual dots row
        GestureDetector(
          onTap: () => node.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              bool isFilled = controller.text.length > i;
              bool isFocused = node.hasFocus && controller.text.length == i;

              return Container(
                width: 48,
                height: 58,
                decoration: BoxDecoration(
                  color: isFocused ? kAccentOrange.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFocused ? kAccentOrange : Colors.grey.shade300,
                    width: isFocused ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: isFilled
                      ? const Icon(Icons.circle, size: 14, color: Colors.black87)
                      : null,
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}