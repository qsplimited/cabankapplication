import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Assuming these files exist in your project structure
import '../main.dart';
import 'dashboard_screen.dart';
import 'forgot_mpin_step1_identity.dart';

// --- THEME COLOR DEFINITION ---
const Color _primaryNavyBlue = Color(0xFF003366);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _mpinFocusNode = FocusNode();
  final TextEditingController _mpinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mpinController.addListener(_updatePinDisplay);

    // Automatically focus the input field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_mpinFocusNode);
    });
  }

  void _updatePinDisplay() {
    // Calling setState here rebuilds the widget tree, updating the _PinCodeDisplay
    // to show dots for entered digits and highlight the next box.
    setState(() {});
  }

  @override
  void dispose() {
    _mpinController.removeListener(_updatePinDisplay);
    _mpinController.dispose();
    _mpinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Check pin length immediately
    if (_mpinController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit M-PIN.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String mpin = _mpinController.text.trim();

    // Simulating login API call
    final bool success = await globalDeviceService.loginWithMpin(mpin: mpin);

    if (mounted) {
      if (success) {
        // Success: Navigate to the Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        // Failure: Show an error and clear the input
        _mpinController.clear();
        FocusScope.of(context).requestFocus(_mpinFocusNode);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid M-PIN. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotMpinStep1Identity(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Attractive and Professional Title
        title: const Text('Secure Device Login'),
        backgroundColor: _primaryNavyBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // Increased vertical padding for better visual spacing
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: _buildLoginCard(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    final bool isPinComplete = _mpinController.text.length == 6;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.lock_rounded,
              size: 70,
              color: _primaryNavyBlue,
            ),
            const SizedBox(height: 20),

            const Text(
              'Welcome Back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            const Text(
              'Please enter your 6-digit M-PIN to continue.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // --- Custom 6-Digit M-PIN Input Display (Visual Boxes) ---
            GestureDetector(
              // Tapping the box area ensures the hidden input gets focus
              onTap: () => FocusScope.of(context).requestFocus(_mpinFocusNode),
              child: _PinCodeDisplay(
                pinLength: 6,
                currentPin: _mpinController.text,
              ),
            ),
            // --- END Custom M-PIN Input Display ---

            // Hidden TextFormField to handle actual input and keyboard interaction
            const SizedBox(height: 20),
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                height: 1, // Minimize visible size
                child: TextFormField(
                  focusNode: _mpinFocusNode,
                  controller: _mpinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true, // Crucial for accessibility, even though it's hidden
                  validator: (value) {
                    // Validator ensures the form is considered valid only if 6 digits are present
                    return (value != null && value.length == 6) ? null : ' ';
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    // Manually trigger login once 6 digits are entered
                    if (value.length == 6) {
                      _handleLogin();
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Login Button
            _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: _primaryNavyBlue),
            )
                : ElevatedButton(
              onPressed: (isPinComplete && !_isLoading) ? _handleLogin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryNavyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: _primaryNavyBlue.withOpacity(0.5),
              ),
              child: const Text(
                'LOG IN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),

            // Forgot M-PIN? Text Button
            TextButton(
              onPressed: _navigateToForgotPassword,
              child: const Text(
                'Forgot M-PIN?',
                style: TextStyle(color: _primaryNavyBlue, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Pin Code Display Widget ---
class _PinCodeDisplay extends StatelessWidget {
  final int pinLength;
  final String currentPin;

  const _PinCodeDisplay({
    required this.pinLength,
    required this.currentPin,
  });

  @override
  Widget build(BuildContext context) {
    // The key change: use LayoutBuilder to determine available width
    return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate the ideal size for each box to fit perfectly with small gaps
          // We use MainAxisAlignment.spaceEvenly inside the Row below.
          final double boxSize = (constraints.maxWidth - (10 * (pinLength - 1))) / pinLength;
          const double boxHeight = 55;

          List<Widget> pinBoxes = List.generate(pinLength, (index) {
            bool isFilled = index < currentPin.length;
            bool isFocused = index == currentPin.length;

            return Container(
              // Use calculated width instead of fixed width
              width: boxSize > 50 ? 50 : boxSize, // Max size 50, but adjust down if needed
              height: boxHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isFocused ? _primaryNavyBlue : Colors.grey.shade300,
                  width: isFocused ? 3 : 2,
                ),
                boxShadow: isFocused
                    ? [
                  BoxShadow(
                    color: _primaryNavyBlue.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ]
                    : null,
              ),
              child: isFilled
                  ? const Padding(
                padding: EdgeInsets.only(bottom: 2.0),
                child: Icon(
                  Icons.circle, // Obscured text dot
                  size: 14,
                  color: Colors.black87,
                ),
              )
                  : Container(),
            );
          });

          // Use a Row with spaceAround or spaceBetween
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: pinBoxes,
          );
        }
    );
  }
}
