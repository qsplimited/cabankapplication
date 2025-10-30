import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/banking_service.dart';

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

  // --- Constants & Styling ---
  final Color _primaryNavyBlue = const Color(0xFF003366);
  final Color _accentGreen = const Color(0xFF4CAF50);
  final Color _accentRed = const Color(0xFFD32F2F);
  final Color _lightBackground = const Color(0xFFF0F2F5);

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

  // --- Utility UI Methods ---

  void _showSnackbar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _accentGreen : _accentRed,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _nextStep(TpinSetupStep next) {
    setState(() {
      _currentStep = next;
      _tpinInputController.clear();
      _confirmTpinController.clear();
      _otpController.clear();
    });
  }

  // --- Core Logic Methods ---

  // STEP 1 (RESET FLOW): Verify mobile number
  Future<void> _verifyMobileNumber() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final mobile = _mobileController.text;
      // CRITICAL: Call the service to find/verify the number
      if (widget.bankingService.findAccountByMobileNumber(mobile)) {
        // Since number is verified, send the OTP immediately and move to OTP screen
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

  // STEP 1 (CHANGE FLOW): Verify Old TPIN
  Future<void> _verifyOldTpin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final oldPin = _tpinInputController.text;

      // Use the unified update method to check the old PIN validity
      // We pass a dummy new PIN, as the service checks the old PIN first.
      await widget.bankingService.updateTransactionPin(
        newPin: '000000',
        oldPin: oldPin,
      );

      // If no exception, the old PIN is correct. Store it for the final step.
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

  // STEP 2 (RESET FLOW): Send/Resend OTP
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

  // STEP 3 (RESET FLOW): Verify OTP
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

  // FINAL STEP (BOTH FLOWS): Set New TPIN
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
      // Determine the pin needed for authorization:
      // - If isResetFlow is true, authorization was via OTP, so oldPin is null.
      // - If isResetFlow is false (Change TPIN), we pass the pin verified in the previous step.
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

  // --- Step Builder Widgets ---

  // STEP 1: Mobile Number Input (Only for Reset/Setup)
  Widget _buildMobileVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.phone_android, size: 50, color: Color(0xFF003366)),
        const SizedBox(height: 20),
        Text('Verify Registered Mobile Number', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _primaryNavyBlue)),
        const SizedBox(height: 10),
        Text('To securely ${widget.isFirstTimeSetup ? 'set' : 'reset'} your TPIN, please confirm your registered mobile number.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 30),
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: '10-Digit Mobile Number',
            prefixText: '+91 ',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (value) {
            if (value == null || value.length != 10) return 'Please enter a valid 10-digit number';
            return null;
          },
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          label: _isLoading ? 'Verifying...' : 'Verify & Send OTP',
          onPressed: _isLoading ? null : _verifyMobileNumber,
          color: _primaryNavyBlue,
        ),
      ],
    );
  }

  // STEP 1: Old TPIN Input (Only for Change)
  Widget _buildOldTpinVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_open_rounded, size: 50, color: Colors.orange),
        const SizedBox(height: 20),
        Text('Verify Current TPIN', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _primaryNavyBlue)),
        const SizedBox(height: 10),
        Text('Enter your current 6-digit TPIN to authorize the change.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 30),
        _buildPinInputField(
            controller: _tpinInputController,
            label: 'Current TPIN (6 Digits)',
            validator: (value) {
              if (value == null || value.length != 6) return 'TPIN must be 6 digits';
              return null;
            }
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          label: _isLoading ? 'Verifying...' : 'Verify TPIN',
          onPressed: _isLoading ? null : _verifyOldTpin,
          color: _primaryNavyBlue,
        ),
      ],
    );
  }

  // STEP 2 (RESET FLOW): OTP Input
  Widget _buildOtpVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.sms_outlined, size: 50, color: Colors.blue),
        const SizedBox(height: 20),
        Text('Verify OTP', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _primaryNavyBlue)),
        const SizedBox(height: 10),
        Text('Enter the 6-digit code sent to ${widget.bankingService.getMaskedMobileNumber()}.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 30),
        _buildPinInputField(
            controller: _otpController,
            label: 'Enter OTP (6 Digits)',
            obscure: false,
            validator: (value) {
              if (value == null || value.length != 6) return 'OTP must be 6 digits';
              return null;
            }
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          label: _isLoading ? 'Verifying...' : 'Verify OTP & Proceed',
          onPressed: _isLoading ? null : _verifyOtp,
          color: _accentGreen,
        ),
        TextButton(
          onPressed: _isLoading ? null : _sendOtp,
          child: Text('Resend OTP', style: TextStyle(color: _primaryNavyBlue)),
        )
      ],
    );
  }

  // STEP 3 (BOTH FLOWS): Set New TPIN
  Widget _buildSetNewTpinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.lock_reset, size: 50, color: Colors.purple),
        const SizedBox(height: 20),
        Text('Set New TPIN', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: _primaryNavyBlue)),
        const SizedBox(height: 10),
        Text('Choose a new, secure 6-digit TPIN for future transactions.', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 30),
        _buildPinInputField(
            controller: _tpinInputController,
            label: 'New TPIN (6 Digits)',
            validator: (value) {
              if (value == null || value.length != 6) return 'TPIN must be 6 digits';
              return null;
            }
        ),
        const SizedBox(height: 20),
        _buildPinInputField(
            controller: _confirmTpinController,
            label: 'Confirm New TPIN (6 Digits)',
            validator: (value) {
              if (value == null || value.length != 6) return 'TPIN must be 6 digits';
              if (value != _tpinInputController.text) return 'TPINs do not match';
              return null;
            }
        ),
        const SizedBox(height: 30),
        _buildActionButton(
          label: _isLoading ? 'Processing...' : 'Set TPIN',
          onPressed: _isLoading ? null : _setNewTpin,
          color: _primaryNavyBlue,
        ),
      ],
    );
  }

  // FINAL STEP (BOTH FLOWS): Completion
  Widget _buildCompletionStep() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: _accentGreen),
          const SizedBox(height: 20),
          Text(
            'TPIN Successfully ${widget.isFirstTimeSetup ? 'Set' : 'Updated'}!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryNavyBlue),
          ),
          const SizedBox(height: 10),
          Text(
            'Your new TPIN is now active and ready for use in all transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 40),
          _buildActionButton(
            label: 'Back to Management Screen',
            onPressed: () => Navigator.of(context).pop(),
            color: _primaryNavyBlue,
          ),
        ],
      ),
    );
  }

  // Reusable TPIN/OTP input field
  Widget _buildPinInputField({
    required TextEditingController controller,
    required String label,
    bool obscure = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 28, letterSpacing: 10, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        hintText: '•' * 6,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryNavyBlue)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryNavyBlue, width: 2)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      validator: validator,
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback? onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: _isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          currentWidget = _buildMobileVerificationStep();
          currentStepIndex = 1;
          break;
        case TpinSetupStep.otpVerification:
          currentWidget = _buildOtpVerificationStep();
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
        default: // Should not happen
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
        default: // Should not happen
          currentWidget = const Center(child: Text('Error: Invalid Step'));
          currentStepIndex = 1;
      }
    }

    // Hide progress bar on the completion screen
    bool showProgressBar = _currentStep != TpinSetupStep.complete;

    return Scaffold(
      backgroundColor: _lightBackground,
      appBar: AppBar(
        title: Text(screenTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: _primaryNavyBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Step $currentStepIndex of $totalSteps',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _primaryNavyBlue,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                  // The actual content for the step
                  currentWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
