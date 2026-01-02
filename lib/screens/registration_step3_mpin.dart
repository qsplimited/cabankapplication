import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';
import 'registration_step4_finalize.dart';

class RegistrationStep3Mpin extends StatefulWidget {
  final String? sessionId;

  const RegistrationStep3Mpin({super.key, this.sessionId});

  @override
  State<RegistrationStep3Mpin> createState() => _RegistrationStep3MpinState();
}

class _RegistrationStep3MpinState extends State<RegistrationStep3Mpin> {
  final TextEditingController _mpinController = TextEditingController();
  final TextEditingController _confirmMpinController = TextEditingController();
  final FocusNode _mpinFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mpinController.addListener(() => setState(() {}));
    _confirmMpinController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mpinController.dispose();
    _confirmMpinController.dispose();
    _mpinFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _handleMpinSetup() {
    setState(() => _errorMessage = null);

    if (_mpinController.text.length < 6) {
      setState(() => _errorMessage = "Please enter a 6-digit MPIN");
      return;
    }
    if (_mpinController.text != _confirmMpinController.text) {
      setState(() => _errorMessage = "MPINs do not match. Please re-enter.");
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RegistrationStep4Finalize(
              sessionId: widget.sessionId,
              mpin: _mpinController.text,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Set MPIN', // Standard standard heading
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAccentOrange,
        centerTitle: false, // Left aligned title
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(kPaddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Secure Your Account',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This PIN will be used for all your future logins and transactions.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- NEW MPIN ---
                    Text(
                      'ENTER NEW 6-DIGIT MPIN',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kAccentOrange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPinInputSection(_mpinController, _mpinFocusNode),

                    const SizedBox(height: 40),

                    // --- CONFIRM MPIN ---
                    Text(
                      'CONFIRM NEW MPIN',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kAccentOrange,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildPinInputSection(_confirmMpinController, _confirmFocusNode),

                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 24),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- Fixed Bottom Action Button ---
            Padding(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleMpinSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kAccentOrange.withOpacity(0.5),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'SET MPIN', // Unique and standard button text
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinInputSection(TextEditingController controller, FocusNode focusNode) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: 0,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(counterText: ""),
          ),
        ),
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

  Widget _buildSingleBox(int index, TextEditingController controller, FocusNode focusNode) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isFocused = focusNode.hasFocus && controller.text.length == index;
    bool hasValue = controller.text.length > index;

    return Container(
      width: 50,
      height: 60,
      decoration: BoxDecoration(
        color: isFocused
            ? kAccentOrange.withOpacity(0.05)
            : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(
          color: isFocused ? kAccentOrange : colorScheme.outline.withOpacity(0.2),
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: hasValue
            ? Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colorScheme.onSurface,
            shape: BoxShape.circle,
          ),
        )
            : isFocused
            ? Container(width: 2, height: 24, color: kAccentOrange)
            : null,
      ),
    );
  }
}