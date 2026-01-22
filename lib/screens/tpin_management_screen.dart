import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tpin_provider.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

enum TpinFlow {
  initial,
  setPin,
  changePin,
  resetVerifyMobile,
  resetVerifyOtp,
  resetSetNewPin
}

class TpinManagementScreen extends ConsumerStatefulWidget {
  const TpinManagementScreen({super.key});

  @override
  ConsumerState<TpinManagementScreen> createState() => _TpinManagementScreenState();
}

class _TpinManagementScreenState extends ConsumerState<TpinManagementScreen> {
  TpinFlow _currentFlow = TpinFlow.initial;

  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<bool> _onInternalBackPress() async {
    final state = ref.read(tpinProvider);
    if (state.status == TpinStateStatus.loading) return false;

    if (_currentFlow != TpinFlow.initial) {
      _resetLocalControllers();
      setState(() => _currentFlow = TpinFlow.initial);
      return false;
    }
    return true;
  }

  void _resetLocalControllers() {
    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    _mobileController.clear();
    _otpController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tpinProvider);
    final isLoading = state.status == TpinStateStatus.loading;

    // Listener for state changes (Error/Success/Navigation)
    ref.listen<TpinProcessState>(tpinProvider, (prev, next) {
      if (next.status == TpinStateStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: kErrorRed),
        );
      }

      if (next.status == TpinStateStatus.success) {
        if (_currentFlow == TpinFlow.resetVerifyOtp) {
          setState(() => _currentFlow = TpinFlow.resetSetNewPin);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.message ?? "Success"), backgroundColor: kSuccessGreen),
          );
          Navigator.pop(context);
        }
      }
    });

    Widget currentWidget;
    String appBarTitle = 'T-PIN Management';

    switch (_currentFlow) {
      case TpinFlow.initial:
        currentWidget = _buildInitialScreen();
        break;
      case TpinFlow.setPin:
        appBarTitle = 'Set Your T-PIN (6 Digits)';
        currentWidget = _buildPinForm(requireOld: false, isLoading: isLoading);
        break;
      case TpinFlow.changePin:
        appBarTitle = 'Change T-PIN';
        currentWidget = _buildPinForm(requireOld: true, isLoading: isLoading);
        break;
      case TpinFlow.resetVerifyMobile:
        appBarTitle = 'Reset T-PIN Wizard';
        currentWidget = _buildVerifyMobileScreen(isLoading);
        break;
      case TpinFlow.resetVerifyOtp:
        appBarTitle = 'Reset T-PIN Wizard';
        currentWidget = _buildVerifyOtpScreen(state.maskedMobile, isLoading);
        break;
      case TpinFlow.resetSetNewPin:
        appBarTitle = 'Reset T-PIN Wizard';
        currentWidget = _buildPinForm(requireOld: false, isLoading: isLoading);
        break;
    }

    return PopScope(
      canPop: _currentFlow == TpinFlow.initial && !isLoading,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _onInternalBackPress();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(title: Text(appBarTitle)),
        body: currentWidget,
      ),
    );
  }

  // FIXED: Added onChanged to ensure button activates/deactivates instantly
  Widget _buildVerifyMobileScreen(bool isLoading) {
    return _buildFlowContainer(
      title: 'Forgot T-PIN: Step 1/3',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter your registered mobile number to receive an OTP for external verification.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _mobileController,
            maxLength: 10,
            keyboardType: TextInputType.phone,
            enabled: !isLoading,
            onChanged: (value) => setState(() {}), // Forces rebuild to check length
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Registered Mobile Number',
              prefixIcon: const Icon(Icons.phone_android),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              counterText: "",
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            // Button enables only when length is exactly 10
            onPressed: (isLoading || _mobileController.text.length != 10)
                ? null
                : () async {
              await ref.read(tpinProvider.notifier).processMobileVerification(_mobileController.text);
              // Check if OTP was sent successfully before moving screens
              if (ref.read(tpinProvider).isOtpSent) {
                setState(() => _currentFlow = TpinFlow.resetVerifyOtp);
              }
            },
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Verify Number & Get OTP'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyOtpScreen(String maskedMobile, bool isLoading) {
    return _buildFlowContainer(
      title: 'Forgot T-PIN: Step 2/3',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Enter the 6-digit OTP sent to $maskedMobile.', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 20),
          TextField(
            controller: _otpController,
            maxLength: 6,
            keyboardType: TextInputType.number,
            enabled: !isLoading,
            onChanged: (value) => setState(() {}), // Refresh button state
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '6-Digit OTP',
              counterText: '',
              prefixIcon: const Icon(Icons.message),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (isLoading || _otpController.text.length != 6)
                ? null
                : () => ref.read(tpinProvider.notifier).processOtpValidation(_otpController.text),
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Validate OTP'),
          ),
          TextButton(
            onPressed: isLoading ? null : () => setState(() => _currentFlow = TpinFlow.resetVerifyMobile),
            child: const Text('Change Number or Resend OTP'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialScreen() {
    return _buildFlowContainer(
      title: 'T-PIN Security Management',
      child: Column(
        children: [
          const Text('Your Transaction PIN (T-PIN) is set. Select an option below.', textAlign: TextAlign.center),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.lock_reset),
            label: const Text('Change My T-PIN'),
            onPressed: () => setState(() => _currentFlow = TpinFlow.changePin),
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            icon: const Icon(Icons.help_outline),
            label: const Text('Forgot T-PIN?'),
            onPressed: () => setState(() => _currentFlow = TpinFlow.resetVerifyMobile),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }

  Widget _buildPinForm({required bool requireOld, required bool isLoading}) {
    return _buildFlowContainer(
      title: requireOld ? 'Change Transaction PIN' : 'Set New Transaction PIN',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (requireOld) _buildPinInput(_oldPinController, 'Current T-PIN', isLoading),
          _buildPinInput(_newPinController, 'New 6-Digit T-PIN', isLoading),
          _buildPinInput(_confirmPinController, 'Confirm New T-PIN', isLoading),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : () {
              if (_newPinController.text != _confirmPinController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PINs do not match"), backgroundColor: Colors.red));
                return;
              }
              ref.read(tpinProvider.notifier).submitNewPin(
                newPin: _newPinController.text,
                oldPin: requireOld ? _oldPinController.text : null,
              );
            },
            child: isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(requireOld ? 'Change PIN' : 'Set PIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowContainer({required String title, required Widget child}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPaddingLarge),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            elevation: kCardElevation,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
            child: Padding(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.primary),
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

  Widget _buildPinInput(TextEditingController ctrl, String label, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        maxLength: 6,
        enabled: !isLoading,
        onChanged: (val) => setState(() {}),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
          counterText: '',
          prefixIcon: const Icon(Icons.lock_outline),
        ),
      ),
    );
  }
}