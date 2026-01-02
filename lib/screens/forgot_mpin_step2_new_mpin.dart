// lib/screens/forgot_mpin_step2_new_mpin.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class ForgotMpinStep2NewMpin extends StatefulWidget {
  final String? sessionId;
  const ForgotMpinStep2NewMpin({super.key, this.sessionId});

  @override
  State<ForgotMpinStep2NewMpin> createState() => _ForgotMpinStep2NewMpinState();
}

class _ForgotMpinStep2NewMpinState extends State<ForgotMpinStep2NewMpin> {
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _newMpinController.addListener(() => setState(() {}));
    _confirmMpinController.addListener(() => setState(() {}));
  }

  void _resetAndBind() async {
    if (_newMpinController.text.length < 6) {
      setState(() => _error = "Please enter 6 digits");
      return;
    }
    if (_newMpinController.text != _confirmMpinController.text) {
      setState(() => _error = "PINs do not match");
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    final result = await globalDeviceService.resetMpin(
      newMpin: _newMpinController.text,
      sessionId: widget.sessionId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        // Success: Go back to Login
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Create New PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Set New MPIN', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Create a new 6-digit secure PIN for your account.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),

            const SizedBox(height: 40),
            Text('NEW MPIN', style: textTheme.labelLarge?.copyWith(color: kAccentOrange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPinField(_newMpinController, _newFocusNode),

            const SizedBox(height: 32),
            Text('CONFIRM NEW MPIN', style: textTheme.labelLarge?.copyWith(color: kAccentOrange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPinField(_confirmMpinController, _confirmFocusNode),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 60),
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetAndBind,
                style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('UPDATE MPIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinField(TextEditingController controller, FocusNode focusNode) {
    return Stack(
      children: [
        Opacity(opacity: 0, child: TextField(controller: controller, focusNode: focusNode, keyboardType: TextInputType.number, maxLength: 6, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
        GestureDetector(
          onTap: () => focusNode.requestFocus(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) => _buildSingleBox(index, controller, focusNode)),
          ),
        ),
      ],
    );
  }

  Widget _buildSingleBox(int index, TextEditingController controller, FocusNode focus) {
    bool isFocused = focus.hasFocus && controller.text.length == index;
    bool hasVal = controller.text.length > index;
    return Container(
      width: 48, height: 58,
      decoration: BoxDecoration(
        color: isFocused ? kAccentOrange.withOpacity(0.05) : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isFocused ? kAccentOrange : Colors.grey.shade400, width: isFocused ? 2 : 1),
      ),
      child: Center(child: hasVal ? const Icon(Icons.circle, size: 12) : (isFocused ? Container(width: 2, height: 20, color: kAccentOrange) : null)),
    );
  }
}