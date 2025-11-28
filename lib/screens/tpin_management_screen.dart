// File: tpin_management_screen.dart (Refactored)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for numerical input formatting

import '../api/banking_service.dart'; // Import the service from its expected path
// Import theme constants
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

/// Defines the different flows within the T-PIN management screen.
enum TpinFlow {
  initial, // Screen loads, decides between Setup/Change/Reset
  setPin, // First-time setup (if isTpinSet == false)
  changePin, // Changing PIN (requires old PIN)
  resetVerifyMobile, // Step 1 of Forgot flow: Verify mobile number
  resetVerifyOtp, // Step 2 of Forgot flow: Validate OTP
  resetSetNewPin, // Step 3 of Forgot flow: Set new T-PIN
}

class TpinManagementScreen extends StatefulWidget {
  // Assuming the BankingService instance is injected or provided elsewhere,
  // but since the original code instantiates it internally, we keep that for now.
  // If the service were passed via constructor, it would be:
  // final BankingService bankingService;
  // const TpinManagementScreen({super.key, required this.bankingService});

  const TpinManagementScreen({super.key});

  @override
  State<TpinManagementScreen> createState() => _TpinManagementScreenState();
}

class _TpinManagementScreenState extends State<TpinManagementScreen> {
  // Hardcoded color constant removed.
  final BankingService _service = BankingService();
  TpinFlow _currentFlow = TpinFlow.initial;
  bool _isLoading = false;
  bool _isTpinSet = false;

  // Controllers for various inputs
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkTpinStatus();
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Checks the T-PIN status from the service and determines the starting flow.
  void _checkTpinStatus() {
    setState(() {
      _isTpinSet = _service.isTpinSet;
      _currentFlow = _isTpinSet ? TpinFlow.initial : TpinFlow.setPin;
    });
  }

  // --- Utility Methods for State and UI ---

  void _setStatus(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Show SnackBar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          // Use onPrimary or corresponding text color for success/error backgrounds
          style: textTheme.bodyMedium?.copyWith(
            color: isError ? colorScheme.onError : colorScheme.onSecondary,
          ),
        ),
        // Use theme-aware colors for status feedback
        backgroundColor: isError ? colorScheme.error : colorScheme.secondary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetFlowControllers() {
    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    _mobileController.clear();
    _otpController.clear();
  }

  void _onSuccess(String message) {
    _setStatus(message, isError: false);
    _resetFlowControllers();

    setState(() {
      _isTpinSet = true;
    });

    // After success, navigate back to the previous screen.
    Navigator.of(context).pop(true);
  }

  void _onError(dynamic error) {
    setState(() {
      _isLoading = false;
    });
    // Clean up the error message for better display
    _setStatus(error.toString().replaceAll('Exception: ', '').replaceAll('Error: ', ''), isError: true);
  }

  // --- API Interaction Handlers (Logic preserved) ---

  Future<void> _handleSetPin({String? oldPin}) async {
    if (_newPinController.text != _confirmPinController.text) {
      _onError('New PIN and Confirm PIN do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = await _service.updateTransactionPin(
        newPin: _newPinController.text,
        oldPin: oldPin,
      );
      _onSuccess(message);
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> _handleMobileVerification() async {
    setState(() => _isLoading = true);
    try {
      if (_service.findAccountByMobileNumber(_mobileController.text)) {
        await _service.requestTpinOtp(); // Request OTP after verification
        setState(() {
          _currentFlow = TpinFlow.resetVerifyOtp;
          _isLoading = false;
        });
      } else {
        throw 'Mobile number not registered with this account.';
      }
    } catch (e) {
      _onError(e);
    }
  }

  Future<void> _handleOtpValidation() async {
    setState(() => _isLoading = true);
    try {
      await _service.validateTpinOtp(_otpController.text);
      setState(() {
        _currentFlow = TpinFlow.resetSetNewPin;
        _isLoading = false;
        _newPinController.clear();
        _confirmPinController.clear();
      });
    } catch (e) {
      _onError(e);
    }
  }

  // --- UI Builders (Refactored) ---

  Widget _buildPinInputField(
      TextEditingController controller,
      String label,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      // Replaced 16.0 with kPaddingMedium
      padding: const EdgeInsets.only(bottom: kPaddingMedium),
      child: TextField(
        controller: controller,
        // Use input formatters to only allow digits
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          // Replaced hardcoded border radius
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(kRadiusMedium)),
          ),
          counterText: '',
          // Use theme color for icon
          prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 6, // Enforcing 6-digit PIN
        onChanged: (value) => setState(() {}), // Force rebuild for button state
      ),
    );
  }

  Widget _buildFlowContainer({required String title, required Widget child}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      // Replaced 24.0 with kPaddingLarge
      padding: const EdgeInsets.all(kPaddingLarge),
      child: Center(
        child: ConstrainedBox(
          // Preserved max width
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            // Use theme card elevation
            elevation: kCardElevation,
            // Replaced 16 radius with kRadiusLarge
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
            child: Padding(
              // Replaced 24.0 with kPaddingLarge
              padding: const EdgeInsets.all(kPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    // Used textTheme.titleLarge and theme primary color
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  // Replaced 20 with kPaddingMedium + kPaddingExtraSmall
                  const SizedBox(height: kPaddingMedium + kPaddingExtraSmall),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// --- Set/Change PIN Forms ---

  Widget _buildSetOrChangePinForm({required bool requireOldPin}) {
    final title = requireOldPin
        ? 'Change Transaction PIN'
        : _isTpinSet ? 'Reset New Transaction PIN' : 'Set Your Transaction PIN';

    final bool canSubmit = (_newPinController.text.length == 6 &&
        _confirmPinController.text.length == 6 &&
        (!requireOldPin || _oldPinController.text.length == 6));

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _buildFlowContainer(
      title: title,
      child: Column(
        children: [
          if (requireOldPin)
            _buildPinInputField(_oldPinController, 'Current T-PIN'),
          _buildPinInputField(_newPinController, 'New 6-Digit T-PIN'),
          _buildPinInputField(_confirmPinController, 'Confirm New T-PIN'),

          // Only show Forgot option if T-PIN is currently set AND we are in the change flow
          if (_isTpinSet && requireOldPin)
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                _resetFlowControllers();
                setState(() => _currentFlow = TpinFlow.resetVerifyMobile);
              },
              // Relying on TextButton theme for color, but explicitly setting style
              child: Text(
                'Forgot T-PIN? Reset via Mobile',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          // Replaced 16 with kPaddingMedium
          const SizedBox(height: kPaddingMedium),
          _isLoading
          // Use theme colors for CircularProgressIndicator
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : ElevatedButton(
            onPressed: canSubmit
                ? () => _handleSetPin(oldPin: requireOldPin ? _oldPinController.text : null)
                : null,
            // Relying on global ElevatedButtonThemeData for styling
            child: Text(
              requireOldPin ? 'Change PIN' : 'Set PIN',
              // Replaced hardcoded style/size with theme text style
              style: textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

// --- Reset PIN Flow Wizard (Logic preserved) ---

  Widget _buildResetFlow() {
    switch (_currentFlow) {
      case TpinFlow.resetVerifyMobile:
        return _buildVerifyMobileScreen();
      case TpinFlow.resetVerifyOtp:
        return _buildVerifyOtpScreen();
      case TpinFlow.resetSetNewPin:
        return _buildSetOrChangePinForm(requireOldPin: false);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildVerifyMobileScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _buildFlowContainer(
      title: 'Forgot T-PIN: Step 1/3',
      child: Column(
        children: [
          Text('Enter your registered mobile number to receive an OTP for external verification.', style: textTheme.bodyMedium),
          // Replaced 20 with kPaddingMedium + kPaddingExtraSmall
          const SizedBox(height: kPaddingMedium + kPaddingExtraSmall),
          Padding(
            // Replaced 16.0 with kPaddingMedium
            padding: const EdgeInsets.only(bottom: kPaddingMedium),
            child: TextField(
              controller: _mobileController,
              // Relying on InputDecorationTheme
              decoration: InputDecoration(
                labelText: 'Registered Mobile Number',
                hintText: 'e.g., 9876541234',
                // Replaced hardcoded border radius
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(kRadiusMedium))),
                // Use theme color for icon
                prefixIcon: Icon(Icons.phone_android, color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (value) => setState(() {}),
            ),
          ),
          _isLoading
          // Use theme colors for CircularProgressIndicator
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : ElevatedButton(
            onPressed: _mobileController.text.length == 10 ? _handleMobileVerification : null,
            // Relying on global ElevatedButtonThemeData for styling
            child: Text(
              'Verify Number & Get OTP',
              // Replaced hardcoded style/size with theme text style
              style: textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyOtpScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _buildFlowContainer(
      title: 'Forgot T-PIN: Step 2/3',
      child: Column(
        children: [
          Text('Enter the 6-digit OTP sent to ${_service.getMaskedMobileNumber()}.', style: textTheme.bodyMedium),
          // Replaced 20 with kPaddingMedium + kPaddingExtraSmall
          const SizedBox(height: kPaddingMedium + kPaddingExtraSmall),
          Padding(
            // Replaced 16.0 with kPaddingMedium
            padding: const EdgeInsets.only(bottom: kPaddingMedium),
            child: TextField(
              controller: _otpController,
              // Relying on InputDecorationTheme
              decoration: InputDecoration(
                labelText: '6-Digit OTP',
                // Replaced hardcoded border radius
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(kRadiusMedium))),
                counterText: '',
                // Use theme color for icon
                prefixIcon: Icon(Icons.message, color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) => setState(() {}),
            ),
          ),
          _isLoading
          // Use theme colors for CircularProgressIndicator
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : ElevatedButton(
            onPressed: _otpController.text.length == 6 ? _handleOtpValidation : null,
            // Relying on global ElevatedButtonThemeData for styling
            child: Text(
              'Validate OTP',
              // Replaced hardcoded style/size with theme text style
              style: textTheme.labelLarge,
            ),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _currentFlow = TpinFlow.resetVerifyMobile),
            // Relying on TextButton theme for color, but explicitly setting style
            child: Text(
              'Change Number or Resend OTP',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
          )
        ],
      ),
    );
  }

// --- Initial Screen ---

  Widget _buildInitialScreen() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _buildFlowContainer(
      title: 'T-PIN Security Management',
      child: Column(
        children: [
          Text(
            'Your Transaction PIN (T-PIN) is set. Select an option below.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge,
          ),
          // Replaced 30 with kPaddingExtraLarge - kPaddingSmall
          const SizedBox(height: kPaddingExtraLarge - kPaddingSmall),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: Text('Change My T-PIN', style: textTheme.labelLarge),
            onPressed: () => setState(() => _currentFlow = TpinFlow.changePin),
            style: ElevatedButton.styleFrom(
              // Replaced hardcoded size with kButtonHeight and double.infinity
              minimumSize: const Size(double.infinity, kButtonHeight),
              // Replaced hardcoded radius with kRadiusMedium
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              // Explicitly ensuring primary theme colors are used for icon/text
              iconColor: colorScheme.onPrimary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
          // Replaced 15 with kPaddingMedium - kPaddingExtraSmall
          const SizedBox(height: kPaddingMedium - kPaddingExtraSmall),
          OutlinedButton.icon(
            icon: const Icon(Icons.help_outline),
            label: Text('Forgot T-PIN?', style: textTheme.labelLarge),
            onPressed: () => setState(() => _currentFlow = TpinFlow.resetVerifyMobile),
            style: OutlinedButton.styleFrom(
              // Replaced hardcoded size with kButtonHeight and double.infinity
              minimumSize: const Size(double.infinity, kButtonHeight),
              // Replaced hardcoded radius with kRadiusMedium
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              // Used theme primary color for foreground/side border
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Necessary function to handle back button press and flow transitions (Logic preserved)
  Future<bool> _onInternalBackPress() async {
    if (_isLoading) {
      return false;
    }

    if (!_isTpinSet && _currentFlow == TpinFlow.setPin) {
      _setStatus("You must set your T-PIN to proceed.", isError: true);
      return false;
    }

    if (_currentFlow != TpinFlow.initial) {
      _resetFlowControllers();
      setState(() => _currentFlow = TpinFlow.initial);
      return false;
    }

    return true;
  }


// --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget currentWidget;
    String appBarTitle = 'T-PIN Management';

    switch (_currentFlow) {
      case TpinFlow.initial:
        currentWidget = _buildInitialScreen();
        break;
      case TpinFlow.setPin:
        appBarTitle = 'Set Your T-PIN (6 Digits)';
        currentWidget = _buildSetOrChangePinForm(requireOldPin: false);
        break;
      case TpinFlow.changePin:
        appBarTitle = 'Change T-PIN';
        currentWidget = _buildSetOrChangePinForm(requireOldPin: true);
        break;
      case TpinFlow.resetVerifyMobile:
      case TpinFlow.resetVerifyOtp:
      case TpinFlow.resetSetNewPin:
        appBarTitle = 'Reset T-PIN Wizard';
        currentWidget = _buildResetFlow();
        break;
    }

    return PopScope(
      canPop: _currentFlow == TpinFlow.initial && !_isLoading,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        await _onInternalBackPress();
      },
      child: Scaffold(
        // Replaced hardcoded Colors.grey[50] with theme background color
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          title: Text(appBarTitle),
          // Removed hardcoded background/foreground/elevation to rely on AppBarTheme
        ),
        body: currentWidget,
      ),
    );
  }
}