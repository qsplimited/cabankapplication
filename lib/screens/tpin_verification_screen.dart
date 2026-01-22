import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class TPinVerificationScreen extends ConsumerStatefulWidget {
  final String title;
  final String subTitle;
  final Future<bool> Function(String pin) onAuthorize;

  const TPinVerificationScreen({super.key, required this.title, required this.subTitle, required this.onAuthorize});

  @override
  ConsumerState<TPinVerificationScreen> createState() => _TPinVerificationScreenState();
}

class _TPinVerificationScreenState extends ConsumerState<TPinVerificationScreen> {
  final _pinController = TextEditingController();
  bool _isBusy = false;

  void _handleConfirm() async {
    if (_pinController.text.length < 6) return;
    setState(() => _isBusy = true);
    bool success = await widget.onAuthorize(_pinController.text);
    if (mounted) setState(() => _isBusy = false);
    if (success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(kPaddingLarge), child: Text(widget.subTitle, style: Theme.of(context).textTheme.bodyLarge)),
            // Keep your specific PIN dots design
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (i) => _buildPinDot(i, isDark))),
            const SizedBox(height: 40),
            TextField(controller: _pinController, autofocus: true, keyboardType: TextInputType.number, maxLength: 6, decoration: const InputDecoration(counterText: ""), onChanged: (v) => v.length == 6 ? _handleConfirm() : setState(() {})),
            if (_isBusy) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDot(int index, bool isDark) {
    bool hasValue = _pinController.text.length > index;
    return Container(
      margin: const EdgeInsets.all(5),
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isDark ? kDarkSurface : kLightSurface,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: hasValue ? kAccentOrange : Colors.grey),
      ),
      child: Center(child: Text(hasValue ? "●" : "", style: const TextStyle(fontSize: 20))),
    );
  }
}