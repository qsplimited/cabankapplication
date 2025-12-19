import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class TPinVerificationScreen extends StatefulWidget {
  final String title;
  final String subTitle;
  final Future<bool> Function(String pin) onAuthorize;

  const TPinVerificationScreen({
    Key? key,
    required this.title,
    required this.subTitle,
    required this.onAuthorize,
  }) : super(key: key);

  @override
  _TPinVerificationScreenState createState() => _TPinVerificationScreenState();
}

class _TPinVerificationScreenState extends State<TPinVerificationScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isBusy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPaddingLarge),
            child: Column(
              children: [
                const SizedBox(height: kSpacingExtraLarge),

                // FIXED ICON: Changed to a valid Flutter Icon name
                Container(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  decoration: BoxDecoration(
                    color: kAccentOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                      Icons.lock_person_outlined, // Valid icon name
                      size: kIconSizeXXL,
                      color: kAccentOrange
                  ),
                ),

                const SizedBox(height: kPaddingLarge),

                Text(
                  widget.subTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? kDarkTextSecondary : kLightTextSecondary,
                  ),
                ),

                const SizedBox(height: kSpacingExtraLarge),

                // PIN BOXES
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _pinController,
                        focusNode: _focusNode,
                        autofocus: true,
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          setState(() {});
                          if (v.length == 6) _handleConfirm();
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) => _buildPinBox(index, isDark)),
                      ),
                    ),
                  ],
                ),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: kPaddingLarge),
                    child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(color: kErrorRed)
                    ),
                  ),

                const SizedBox(height: kSpacingExtraLarge),

                // CONFIRM BUTTON
                ElevatedButton(
                  onPressed: _isBusy ? null : _handleConfirm,
                  child: _isBusy
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text("CONFIRM"),
                ),

                const SizedBox(height: kPaddingMedium),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                      "CANCEL",
                      style: TextStyle(color: isDark ? kDarkTextSecondary : kLightTextSecondary)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinBox(int index, bool isDark) {
    bool hasValue = _pinController.text.length > index;
    bool isFocused = _pinController.text.length == index;

    return Container(
      width: kTpinFieldSize + 5,
      height: kTpinFieldSize + 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? kDarkSurface : kLightSurface,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(
          // FIXED CONSTANT ERROR: Removed 'const' because colors are dynamic
          color: isFocused ? kAccentOrange : (isDark ? kDarkDivider : kLightDivider),
          width: 2,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: kAccentOrange.withOpacity(0.2), blurRadius: 4)]
            : [],
      ),
      child: Text(
        hasValue ? "●" : "",
        style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? kDarkTextPrimary : kLightTextPrimary
        ),
      ),
    );
  }

// ... (imports and class definition same as your provided code)

  void _handleConfirm() async {
    if (_pinController.text.length < 6) return;
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    // Call the function passed from EditNomineeScreen
    bool success = await widget.onAuthorize(_pinController.text);

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (!success) {
      setState(() => _errorMessage = "Invalid T-PIN. Please try again.");
      _pinController.clear();
      _focusNode.requestFocus();
    }
    // Note: We don't navigate here. The 'onAuthorize' logic handles navigation on success.
  }
}