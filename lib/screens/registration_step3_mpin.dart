import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../event/registration_event.dart';
import '../state/registration_state.dart';
import 'registration_step4_finalize.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class RegistrationStep3Mpin extends StatefulWidget {
  const RegistrationStep3Mpin({super.key});

  @override
  State<RegistrationStep3Mpin> createState() => _RegistrationStep3MpinState();
}

class _RegistrationStep3MpinState extends State<RegistrationStep3Mpin> {
  final _mpinController = TextEditingController();
  final _confirmController = TextEditingController();
  final _mpinFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _mpinController.addListener(() => setState(() {}));
    _confirmController.addListener(() => setState(() {}));
  }

  void _onSubmit() {
    if (_mpinController.text.length == 6 && _mpinController.text == _confirmController.text) {
      context.read<RegistrationBloc>().add(MpinSetupTriggered(_mpinController.text));
    } else if (_mpinController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("MPINs do not match")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.currentStep == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationStep4Finalize()));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Secure MPIN'), backgroundColor: kAccentOrange),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create 6-Digit MPIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildPinInput(_mpinController, _mpinFocus),
              const SizedBox(height: 40),
              const Text("Confirm MPIN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildPinInput(_confirmController, _confirmFocus),
              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: BlocBuilder<RegistrationBloc, RegistrationState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == RegistrationStatus.loading ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                      child: state.status == RegistrationStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SET MPIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput(TextEditingController controller, FocusNode focusNode) {
    return Stack(
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
            children: List.generate(6, (index) => _buildDotBox(index, controller, focusNode)),
          ),
        ),
      ],
    );
  }

  Widget _buildDotBox(int index, TextEditingController controller, FocusNode focus) {
    bool hasValue = controller.text.length > index;
    bool isFocused = focus.hasFocus && controller.text.length == index;
    return Container(
      width: 48, height: 58,
      decoration: BoxDecoration(
        color: isFocused ? kAccentOrange.withOpacity(0.05) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isFocused ? kAccentOrange : Colors.grey.shade300),
      ),
      child: Center(
        child: hasValue
            ? Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle))
            : null,
      ),
    );
  }
}