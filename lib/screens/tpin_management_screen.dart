import 'package:flutter/material.dart';

import '../api/banking_service.dart'; // Import the service from its expected path

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
  const TpinManagementScreen({super.key});

  @override
  State<TpinManagementScreen> createState() => _TpinManagementScreenState();
}

class _TpinManagementScreenState extends State<TpinManagementScreen> {
  // Define the custom color as a constant for easy reuse
  static const Color _primaryColor = Color(0xFF003366); // <-- YOUR REQUESTED COLOR

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
// If T-PIN is not set, force the user to the Set Pin flow immediately.
// Otherwise, show the initial options menu.
      _currentFlow = _isTpinSet ? TpinFlow.initial : TpinFlow.setPin;
    });
  }

// --- Utility Methods for State and UI ---

  void _setStatus(String message, {bool isError = false}) {
// Show SnackBar for feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
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

    // VITAL CHANGE: Explicitly update the local status to reflect success.
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

// --- API Interaction Handlers ---

  /// Handles setting a new PIN or changing an existing one.
  Future<void> _handleSetPin({String? oldPin}) async {
    if (_newPinController.text != _confirmPinController.text) {
      _onError('New PIN and Confirm PIN do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
// In the Forgot flow, 'oldPin' is null, which the service handles as a reset.
      final message = await _service.updateTransactionPin(
        newPin: _newPinController.text,
        oldPin: oldPin,
      );
      _onSuccess(message);
    } catch (e) {
      _onError(e);
    }
  }

  /// Step 1 of Reset: Verifies mobile number and requests OTP.
  Future<void> _handleMobileVerification() async {
    setState(() => _isLoading = true);
    try {
      if (_service.findAccountByMobileNumber(_mobileController.text)) {
        await _service.requestTpinOtp(); // Request OTP after verification
        setState(() {
          _currentFlow = TpinFlow.resetVerifyOtp;
          _isLoading = false; // Set loading to false upon successful transition
        });
      } else {
        throw 'Mobile number not registered with this account.';
      }
    } catch (e) {
      _onError(e);
    }
  }

  /// Step 2 of Reset: Validates OTP.
  Future<void> _handleOtpValidation() async {
    setState(() => _isLoading = true);
    try {
      await _service.validateTpinOtp(_otpController.text);
// Move to the final step: setting the new PIN (no old PIN required)
      setState(() {
        _currentFlow = TpinFlow.resetSetNewPin;
        _isLoading = false; // Set loading to false upon successful transition
        _newPinController.clear();
        _confirmPinController.clear();
      });
    } catch (e) {
      _onError(e);
    }
  }

// --- UI Builders ---

  Widget _buildPinInputField(
      TextEditingController controller,
      String label,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          counterText: '',
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 6, // Enforcing 6-digit PIN
        onChanged: (value) => setState(() {}), // Force rebuild for button state
      ),
    );
  }

  Widget _buildFlowContainer({required String title, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor, // <-- Color change 1/7
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
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

// The required length for submission check
    final bool canSubmit = (_newPinController.text.length == 6 &&
        _confirmPinController.text.length == 6 &&
        (!requireOldPin || _oldPinController.text.length == 6));

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
              child: const Text('Forgot T-PIN? Reset via Mobile'),
            ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: canSubmit
                ? () => _handleSetPin(oldPin: requireOldPin ? _oldPinController.text : null)
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: _primaryColor, // <-- Color change 2/7
              foregroundColor: Colors.white,
            ),
            child: Text(requireOldPin ? 'Change PIN' : 'Set PIN', style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

// --- Reset PIN Flow Wizard ---

  Widget _buildResetFlow() {
    switch (_currentFlow) {
      case TpinFlow.resetVerifyMobile:
        return _buildVerifyMobileScreen();
      case TpinFlow.resetVerifyOtp:
        return _buildVerifyOtpScreen();
      case TpinFlow.resetSetNewPin:
// Final step uses the generic form but without requiring the old PIN
        return _buildSetOrChangePinForm(requireOldPin: false);
      default:
// Should not happen when navigating via the Forgot flow button
        return const SizedBox.shrink();
    }
  }

  Widget _buildVerifyMobileScreen() {
    return _buildFlowContainer(
      title: 'Forgot T-PIN: Step 1/3',
      child: Column(
        children: [
          const Text('Enter your registered mobile number to receive an OTP for external verification.'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _mobileController,
              decoration: const InputDecoration(
                labelText: 'Registered Mobile Number',
                hintText: 'e.g., 9876541234',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixIcon: Icon(Icons.phone_android),
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              onChanged: (value) => setState(() {}),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _mobileController.text.length == 10 ? _handleMobileVerification : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: _primaryColor, // <-- Color change 3/7
              foregroundColor: Colors.white,
            ),
            child: const Text('Verify Number & Get OTP', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyOtpScreen() {
    return _buildFlowContainer(
      title: 'Forgot T-PIN: Step 2/3',
      child: Column(
        children: [
          Text('Enter the 6-digit OTP sent to ${_service.getMaskedMobileNumber()}.'),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: '6-Digit OTP',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                counterText: '',
                prefixIcon: Icon(Icons.message),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) => setState(() {}),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _otpController.text.length == 6 ? _handleOtpValidation : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: _primaryColor, // <-- Color change 4/7
              foregroundColor: Colors.white,
            ),
            child: const Text('Validate OTP', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => setState(() => _currentFlow = TpinFlow.resetVerifyMobile),
            child: const Text('Change Number or Resend OTP'),
          )
        ],
      ),
    );
  }

// --- Initial Screen ---

  Widget _buildInitialScreen() {
    return _buildFlowContainer(
      title: 'T-PIN Security Management',
      child: Column(
        children: [
          const Text(
            'Your Transaction PIN (T-PIN) is set. Select an option below.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Change My T-PIN', style: TextStyle(fontSize: 18)),
            onPressed: () => setState(() => _currentFlow = TpinFlow.changePin),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: _primaryColor, // <-- Color change 5/7
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            icon: const Icon(Icons.help_outline),
            label: const Text('Forgot T-PIN?', style: TextStyle(fontSize: 18)),
            onPressed: () => setState(() => _currentFlow = TpinFlow.resetVerifyMobile),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              foregroundColor: _primaryColor, // <-- Color change 6/7
              side: const BorderSide(color: _primaryColor), // <-- Color change 7/7
            ),
          ),
        ],
      ),
    );
  }

  // Necessary function to handle back button press and flow transitions
  Future<bool> _onInternalBackPress() async {
    if (_isLoading) {
      // Prevent any navigation while an API call is in progress
      return false;
    }

    // If T-PIN is not set, the user MUST complete the setup and cannot go back.
    if (!_isTpinSet && _currentFlow == TpinFlow.setPin) {
      _setStatus("You must set your T-PIN to proceed.", isError: true);
      return false;
    }

    // For all other flows (Change, Reset steps), go back to the initial options screen
    // instead of popping the whole screen.
    if (_currentFlow != TpinFlow.initial) {
      _resetFlowControllers();
      setState(() => _currentFlow = TpinFlow.initial);
      return false; // Block the default system pop action
    }

    // Only allow system pop if we are in the initial menu (TpinFlow.initial)
    return true;
  }


// --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    Widget currentWidget;
    String appBarTitle = 'T-PIN Management';

// Determine the current view based on the flow state
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

// Wrap the widget in a PopScope to control back navigation
    return PopScope(
      // canPop is false if:
      // 1. We are in the mandatory setPin flow
      // 2. We are in a sub-flow (change/reset) which should internally navigate back to initial first
      // 3. An operation is loading
      canPop: _currentFlow == TpinFlow.initial && !_isLoading,
      onPopInvoked: (didPop) async {
        if (didPop) return; // If canPop was true, the system handled it.

        // Otherwise, run custom back logic for internal flow control
        await _onInternalBackPress();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(appBarTitle),
          backgroundColor: _primaryColor, // <-- Color change (AppBar)
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: currentWidget,
      ),
    );
  }
}
