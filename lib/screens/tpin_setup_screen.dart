import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tpin_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

enum TpinSetupStep { mobileVerification, oldTpinVerification, otpVerification, setNewPin, complete }

class TpinSetupScreen extends ConsumerStatefulWidget {
  final bool isResetFlow;
  final bool isFirstTimeSetup;

  const TpinSetupScreen({super.key, required this.isResetFlow, this.isFirstTimeSetup = false});

  @override
  ConsumerState<TpinSetupScreen> createState() => _TpinSetupScreenState();
}

class _TpinSetupScreenState extends ConsumerState<TpinSetupScreen> {
  late TpinSetupStep _currentStep;
  final _tpinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpController = TextEditingController();
  final _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentStep = widget.isResetFlow ? TpinSetupStep.mobileVerification : TpinSetupStep.oldTpinVerification;
  }

  void _nextStep(TpinSetupStep next) {
    setState(() => _currentStep = next);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tpinProvider);
    final isLoading = state.status == TpinStateStatus.loading;
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<TpinProcessState>(tpinProvider, (prev, next) {
      if (next.status == TpinStateStatus.success) {
        if (_currentStep == TpinSetupStep.otpVerification) _nextStep(TpinSetupStep.setNewPin);
        else if (_currentStep == TpinSetupStep.setNewPin) Navigator.pop(context);
      }
      if (next.status == TpinStateStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.error!), backgroundColor: kErrorRed));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Security Setup')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
            child: Padding(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  LinearProgressIndicator(value: _currentStep.index / 4, color: kSuccessGreen),
                  const SizedBox(height: kPaddingLarge),
                  _buildStepContent(isLoading),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(bool isLoading) {
    if (_currentStep == TpinSetupStep.mobileVerification) {
      return Column(children: [
        TextFormField(controller: _mobileController, decoration: const InputDecoration(labelText: 'Mobile Number')),
        ElevatedButton(onPressed: () => ref.read(tpinProvider.notifier).processMobileVerification(_mobileController.text).then((_) {
          if (ref.read(tpinProvider).isOtpSent) _nextStep(TpinSetupStep.otpVerification);
        }), child: const Text('Verify Mobile'))
      ]);
    }
    if (_currentStep == TpinSetupStep.otpVerification) {
      return Column(children: [
        TextFormField(controller: _otpController, decoration: const InputDecoration(labelText: 'Enter OTP')),
        ElevatedButton(onPressed: () => ref.read(tpinProvider.notifier).processOtpValidation(_otpController.text), child: const Text('Verify OTP'))
      ]);
    }
    return Column(children: [
      TextFormField(controller: _tpinController, decoration: const InputDecoration(labelText: 'New PIN')),
      TextFormField(controller: _confirmController, decoration: const InputDecoration(labelText: 'Confirm PIN')),
      ElevatedButton(onPressed: () => ref.read(tpinProvider.notifier).submitNewPin(newPin: _tpinController.text), child: const Text('Set PIN'))
    ]);
  }
}