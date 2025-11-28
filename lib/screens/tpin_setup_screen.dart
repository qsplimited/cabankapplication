import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/banking_service.dart';
import '../theme/app_colors.dart'; // Import for specific color constants (kSuccessGreen, kErrorRed)
import '../theme/app_dimensions.dart'; // Import for size constants (kPadding..., kRadius..., kIconSize...)

// Defines the steps for the T-PIN setup/reset process
enum TpinSetupStep {
  mobileVerification, // Only for Reset/Setup flow
  oldTpinVerification, // Only for Change flow
  otpVerification,
  setNewPin,
  complete
}

class TpinSetupScreen extends StatefulWidget {
  final BankingService bankingService;
  final bool isResetFlow; // True for Forgot/First-time Setup, False for Change
  final bool isFirstTimeSetup; // True if TPIN is currently unset

  const TpinSetupScreen({
    super.key,
    required this.bankingService,
    required this.isResetFlow,
    this.isFirstTimeSetup = false,
  });

  @override
  State<TpinSetupScreen> createState() => _TpinSetupScreenState();
}

class _TpinSetupScreenState extends State<TpinSetupScreen> {
  // --- Controllers & State ---
  late TpinSetupStep _currentStep;

  // Input Controllers
  final TextEditingController _tpinInputController = TextEditingController(); // Used for old TPIN or new TPIN
  final TextEditingController _confirmTpinController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  // Internal Logic States
  String? _verifiedOldPin;
  bool _isLoading = false;
  bool _otpSent = false;

  // --- Form Keys ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Hardcoded Colors Removed ---
  // Replaced with theme references in methods below.

  @override
  void initState() {
    super.initState();
    // Initialize the starting step based on the flow type
    if (widget.isResetFlow) {
      // Start with mobile verification for Reset/First-time setup
      _currentStep = TpinSetupStep.mobileVerification;
    } else {
      // Start with old TPIN verification for Change TPIN flow
      _currentStep = TpinSetupStep.oldTpinVerification;
    }
  }

  @override
  void dispose() {
    _tpinInputController.dispose();
    _confirmTpinController.dispose();
    _otpController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  // --- Utility UI Methods ---

  void _showSnackbar(String message, {required bool isSuccess}) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Use kSuccessGreen and kErrorRed constants from app_colors.dart
        backgroundColor: isSuccess ? kSuccessGreen : kErrorRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _nextStep(TpinSetupStep next) {
    setState(() {
      _currentStep = next;
      // Clear relevant controllers on step transition
      _tpinInputController.clear();
      _confirmTpinController.clear();
      _otpController.clear();
      // Only clear mobile if going back to initial verification step
      if (next == TpinSetupStep.mobileVerification) {
        _mobileController.clear();
        _otpSent = false;
      }
    });
  }

  // --- Core Logic Methods (Unchanged) ---

  Future<void> _verifyMobileNumber() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final mobile = _mobileController.text;
      if (widget.bankingService.findAccountByMobileNumber(mobile)) {
        await _sendOtp();
        _nextStep(TpinSetupStep.otpVerification);
      } else {
        _showSnackbar('Account not found for this mobile number.', isSuccess: false);
      }
    } catch (e) {
      _showSnackbar('Verification Error: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOldTpin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final oldPin = _tpinInputController.text;

      // Use the unified update method to check the old PIN validity
      await widget.bankingService.updateTransactionPin(
        newPin: '000000', // Dummy new PIN for verification check
        oldPin: oldPin,
      );

      _verifiedOldPin = oldPin;
      _showSnackbar('Current TPIN Verified. Proceed to set new PIN.', isSuccess: true);
      _nextStep(TpinSetupStep.setNewPin);

    } on String catch (e) {
      _showSnackbar(e, isSuccess: false);
    } catch (e) {
      _showSnackbar('Verification Error: Current T-PIN is incorrect.', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final otp = await widget.bankingService.requestTpinOtp();
      setState(() => _otpSent = true);
      _showSnackbar('OTP sent to ${widget.bankingService.getMaskedMobileNumber()}. (Mock Code: $otp)', isSuccess: true);
    } catch (e) {
      _showSnackbar('Failed to send OTP: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await widget.bankingService.validateTpinOtp(_otpController.text);
      _showSnackbar('OTP Verified successfully!', isSuccess: true);
      _nextStep(TpinSetupStep.setNewPin);

    } catch (e) {
      _showSnackbar('Invalid or expired OTP. Please try again.', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setNewTpin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final newPin = _tpinInputController.text;
    final confirmPin = _confirmTpinController.text;

    if (newPin != confirmPin) {
      _showSnackbar('New TPINs do not match.', isSuccess: false);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final String? oldPinForAuth = widget.isResetFlow ? null : _verifiedOldPin;

      final message = await widget.bankingService.updateTransactionPin(
        newPin: newPin,
        oldPin: oldPinForAuth,
      );

      _showSnackbar(message, isSuccess: true);
      _nextStep(TpinSetupStep.complete);

    } catch (e) {
      _showSnackbar('Failed to set TPIN: ${e.toString()}', isSuccess: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- Step Builder Widgets (Refactored) ---

  // STEP 1: Mobile Number Input (Only for Reset/Setup)
  Widget _buildMobileVerificationStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Replaced hardcoded size/color with theme constants
        Icon(Icons.phone_android, size: kIconSizeXXL, color: colorScheme.primary),
        const SizedBox(height: kPaddingMedium),
        Text(
          'Verify Registered Mobile Number',
          // Used headlineSmall and theme primary color
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
        const SizedBox(height: kPaddingTen),
        Text(
          'To securely ${widget.isFirstTimeSetup ? 'set' : 'reset'} your TPIN, please confirm your registered mobile number.',
          // Used textTheme.bodyMedium and theme secondary text color (onSurface with opacity)
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: kPaddingExtraLarge),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '10-Digit Mobile Number',
            prefixText: '+91 ',
            counterText: '',
            // Replaced hardcoded radius
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.length != 10) return 'Please enter a valid 10-digit number';
            return null;
          },
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildActionButton(
          label: _isLoading ? 'Verifying...' : 'Verify & Send OTP',
          onPressed: _isLoading ? null : _verifyMobileNumber,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  // STEP 1: Old TPIN Input (Only for Change)
  Widget _buildOldTpinVerificationStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Replaced hardcoded size/color with theme constants
        Icon(Icons.lock_open_rounded, size: kIconSizeXXL, color: kAccentOrange),
        const SizedBox(height: kPaddingMedium),
        Text(
          'Verify Current TPIN',
          // Used headlineSmall and theme primary color
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
        const SizedBox(height: kPaddingTen),
        Text(
          'Enter your current 6-digit TPIN to authorize the change.',
          // Used bodyMedium and theme secondary text color
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildPinInputField(
            controller: _tpinInputController,
            label: 'Current TPIN (6 Digits)',
            validator: (value) {
              if (value == null || value.length != 6) return 'TPIN must be 6 digits';
              return null;
            }
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildActionButton(
          label: _isLoading ? 'Verifying...' : 'Verify TPIN',
          onPressed: _isLoading ? null : _verifyOldTpin,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  // STEP 2 (RESET FLOW): OTP Input
  Widget _buildOtpVerificationStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Replaced hardcoded size/color with theme constants
        Icon(Icons.sms_outlined, size: kIconSizeXXL, color: colorScheme.secondary),
        const SizedBox(height: kPaddingMedium),
        Text(
          'Verify OTP',
          // Used headlineSmall and theme primary color
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
        const SizedBox(height: kPaddingTen),
        Text(
          'Enter the 6-digit code sent to ${widget.bankingService.getMaskedMobileNumber()}.',
          // Used bodyMedium and theme secondary text color
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildPinInputField(
            controller: _otpController,
            label: 'Enter OTP (6 Digits)',
            obscure: false,
            validator: (value) {
              if (value == null || value.length != 6) return 'OTP must be 6 digits';
              return null;
            }
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildActionButton(
          label: _isLoading ? 'Verifying...' : 'Verify OTP & Proceed',
          onPressed: _isLoading ? null : _verifyOtp,
          // Used kSuccessGreen constant from app_colors.dart
          color: kSuccessGreen,
        ),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          // Used TextButton theme (which uses primary color)
          child: Text('Resend OTP', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
        )
      ],
    );
  }

  // STEP 3 (BOTH FLOWS): Set New TPIN
  Widget _buildSetNewTpinStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Replaced hardcoded size/color with theme constants
        Icon(Icons.lock_reset, size: kIconSizeXXL, color: colorScheme.secondary),
        const SizedBox(height: kPaddingMedium),
        Text(
          'Set New TPIN',
          // Used headlineSmall and theme primary color
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
        const SizedBox(height: kPaddingTen),
        Text(
          'Choose a new, secure 6-digit TPIN for future transactions.',
          // Used bodyMedium and theme secondary text color
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildPinInputField(
            controller: _tpinInputController,
            label: 'New TPIN (6 Digits)',
            validator: (value) {
              if (value == null || value.length != 6) return 'TPIN must be 6 digits';
              return null;
            }
        ),
        const SizedBox(height: kPaddingMedium + kPaddingExtraSmall),
        _buildPinInputField(
            controller: _confirmTpinController,
            label: 'Confirm New TPIN (6 Digits)',
            validator: (value) {
              if (value == null || value.length != 6) return 'TPIN must be 6 digits';
              if (value != _tpinInputController.text) return 'TPINs do not match';
              return null;
            }
        ),
        const SizedBox(height: kPaddingExtraLarge),
        _buildActionButton(
          label: _isLoading ? 'Processing...' : 'Set TPIN',
          onPressed: _isLoading ? null : _setNewTpin,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  // FINAL STEP (BOTH FLOWS): Completion
  Widget _buildCompletionStep() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Replaced hardcoded size/color with theme constants
          Icon(Icons.check_circle_outline, size: kIconSizeXXL * 1.3, color: kSuccessGreen),
          const SizedBox(height: kPaddingMedium),
          Text(
            'TPIN Successfully ${widget.isFirstTimeSetup ? 'Set' : 'Updated'}!',
            textAlign: TextAlign.center,
            // Used theme titleLarge and primary color
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
          ),
          const SizedBox(height: kPaddingTen),
          Text(
            'Your new TPIN is now active and ready for use in all transactions.',
            textAlign: TextAlign.center,
            // Used theme bodyLarge and theme secondary text color
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.8)),
          ),
          const SizedBox(height: kPaddingXXL),
          _buildActionButton(
            label: 'Back to Management Screen',
            onPressed: () => Navigator.of(context).pop(true), // Pop with result true
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // Reusable TPIN/OTP input field (Highly styled, theme applied)
  Widget _buildPinInputField({
    required TextEditingController controller,
    required String label,
    bool obscure = true,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      // Styled for large, prominent input
      style: textTheme.headlineMedium?.copyWith(letterSpacing: kPaddingSmall, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        hintText: '•' * 6,
        counterText: '',
        // Replaced hardcoded border radius/color
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium), borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
      ),
      validator: validator,
    );
  }

  // Reusable Action Button (Highly styled, theme applied)
  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: colorScheme.onPrimary, // Text color on primary button (should be white/light)
          padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
          elevation: kCardElevation,
        ),
        child: _isLoading
            ? SizedBox(
            height: kIconSize,
            width: kIconSize,
            // Use theme color for loading indicator
            child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 3))
            : Text(
            label,
            // Used theme labelLarge style
            style: textTheme.labelLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimary)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    String screenTitle = 'Setup Transaction PIN';
    if (!widget.isResetFlow) {
      screenTitle = 'Change TPIN';
    } else if (!widget.isFirstTimeSetup) {
      screenTitle = 'Reset Forgotten TPIN';
    }

    Widget currentWidget;
    int currentStepIndex;
    int totalSteps;

    // Determine the current step content and progress information
    if (widget.isResetFlow) {
      totalSteps = 3; // Mobile/OTP -> New PIN -> Complete
      switch (_currentStep) {
        case TpinSetupStep.mobileVerification:
        case TpinSetupStep.otpVerification:
          currentWidget = widget.isFirstTimeSetup ? _buildMobileVerificationStep() : _buildOtpVerificationStep();
          currentStepIndex = 1;
          break;
        case TpinSetupStep.setNewPin:
          currentWidget = _buildSetNewTpinStep();
          currentStepIndex = 2;
          break;
        case TpinSetupStep.complete:
          currentWidget = _buildCompletionStep();
          currentStepIndex = 3;
          break;
        default:
          currentWidget = const Center(child: Text('Error: Invalid Step'));
          currentStepIndex = 1;
      }
    } else {
      totalSteps = 3; // Old PIN -> New PIN -> Complete
      switch (_currentStep) {
        case TpinSetupStep.oldTpinVerification:
          currentWidget = _buildOldTpinVerificationStep();
          currentStepIndex = 1;
          break;
        case TpinSetupStep.setNewPin:
          currentWidget = _buildSetNewTpinStep();
          currentStepIndex = 2;
          break;
        case TpinSetupStep.complete:
          currentWidget = _buildCompletionStep();
          currentStepIndex = 3;
          break;
        default:
          currentWidget = const Center(child: Text('Error: Invalid Step'));
          currentStepIndex = 1;
      }
    }

    // Hide progress bar on the completion screen
    bool showProgressBar = _currentStep != TpinSetupStep.complete;

    return PopScope(
      canPop: _currentStep == TpinSetupStep.complete,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Custom back navigation for the multi-step flow
        if (_currentStep == TpinSetupStep.setNewPin && widget.isResetFlow) {
          _nextStep(TpinSetupStep.otpVerification);
        } else if (_currentStep == TpinSetupStep.otpVerification) {
          _nextStep(TpinSetupStep.mobileVerification);
        } else if (_currentStep == TpinSetupStep.setNewPin && !widget.isResetFlow) {
          _nextStep(TpinSetupStep.oldTpinVerification);
        }
      },
      child: Scaffold(
        // Used theme background color
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(screenTitle, style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
          // Used theme primary color
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            // Used theme padding constant
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              // Used theme padding constant
              padding: const EdgeInsets.all(kPaddingLarge),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                // Used theme radius constant
                borderRadius: BorderRadius.circular(kRadiusLarge),
                boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.1), blurRadius: 15)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (showProgressBar) ...[
                      // Progress Indicator
                      LinearProgressIndicator(
                        value: currentStepIndex / totalSteps,
                        backgroundColor: colorScheme.surfaceVariant, // Light/dark grey background
                        // Used kSuccessGreen constant
                        valueColor: const AlwaysStoppedAnimation<Color>(kSuccessGreen),
                        minHeight: kPaddingSmall, // Used theme padding constant
                      ),
                      const SizedBox(height: kPaddingTen),
                      Text(
                        'Step $currentStepIndex of $totalSteps',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: kPaddingExtraLarge),
                    ],
                    // The actual content for the step
                    currentWidget,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}