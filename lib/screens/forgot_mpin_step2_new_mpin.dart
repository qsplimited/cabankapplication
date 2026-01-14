import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../event/registration_event.dart';
import '../state/registration_state.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class ForgotMpinStep2NewMpin extends StatefulWidget {
  const ForgotMpinStep2NewMpin({super.key}); // SessionId now comes from BLoC state

  @override
  State<ForgotMpinStep2NewMpin> createState() => _ForgotMpinStep2NewMpinState();
}

class _ForgotMpinStep2NewMpinState extends State<ForgotMpinStep2NewMpin> {
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  final _newFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _newMpinController.addListener(() => setState(() {}));
    _confirmMpinController.addListener(() => setState(() {}));
  }

  void _onReset() {
    if (_newMpinController.text.length < 6) return;
    if (_newMpinController.text != _confirmMpinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("MPINs do not match")));
      return;
    }

    // Trigger BLoC event
    context.read<RegistrationBloc>().add(MpinSetupTriggered(_newMpinController.text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.status == RegistrationStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("MPIN Reset Successful!")));
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create New MPIN'), backgroundColor: kAccentOrange),
        body: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            children: [
              const Text("Enter 6-digit New MPIN"),
              _buildPinField(_newMpinController, _newFocusNode),
              const SizedBox(height: 30),
              const Text("Confirm New MPIN"),
              _buildPinField(_confirmMpinController, _confirmFocusNode),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: BlocBuilder<RegistrationBloc, RegistrationState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == RegistrationStatus.loading ? null : _onReset,
                      style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                      child: state.status == RegistrationStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('RESET MPIN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _buildPinField(TextEditingController controller, FocusNode focusNode) {
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

  Widget _buildSingleBox(int index, TextEditingController controller, FocusNode focus) {
    bool isFocused = focus.hasFocus && controller.text.length == index;
    bool hasVal = controller.text.length > index;
    return Container(
      width: 48, height: 58,
      decoration: BoxDecoration(
        color: isFocused ? kAccentOrange.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isFocused ? kAccentOrange : Colors.grey.shade400, width: isFocused ? 2 : 1),
      ),
      child: Center(
        child: hasVal
            ? Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle))
            : null,
      ),
    );
  }
}