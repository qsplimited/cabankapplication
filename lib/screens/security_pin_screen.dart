import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transaction_service.dart';
import '../models/transaction_response_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'transaction_success_screen.dart';

class SecurityPinScreen extends ConsumerStatefulWidget {
  final String fromAccount;
  final String toAccount;
  final String recipientName;
  final double amount;

  const SecurityPinScreen({
    super.key,
    required this.fromAccount,
    required this.toAccount,
    required this.recipientName,
    required this.amount,
  });

  @override
  ConsumerState<SecurityPinScreen> createState() => _SecurityPinScreenState();
}

class _SecurityPinScreenState extends ConsumerState<SecurityPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the device keyboard on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onPinChanged(String value) {
    setState(() {}); // Update the circular UI
    if (value.length == 6) {
      _processPayment(value);
    }
  }

  void _processPayment(String pin) async {
    setState(() => _isLoading = true);
    try {
      final TransactionResponse response = await ref.read(transServiceProvider).transferFunds(
        fromAcc: widget.fromAccount,
        toAcc: widget.toAccount,
        amount: widget.amount,
        mpin: pin,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionSuccessScreen(
              response: response,
              recipientName: widget.recipientName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _pinController.clear();
        _focusNode.requestFocus(); // Keep keyboard open for retry
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: kErrorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Enter T-PIN", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kAccentOrange))
          : Column(
        children: [
          const SizedBox(height: 50),


          Text(
            "Transferring to ${widget.recipientName}",
            style: const TextStyle(fontSize: 14, color: kLightTextSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            "₹ ${widget.amount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: kBrandNavy,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 60),

          // 2. PIN Input Title
          const Text(
            "ENTER 6-DIGIT PIN",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: kLightTextSecondary
            ),
          ),
          const SizedBox(height: 30),

          // 3. Custom Round PIN Indicators (Interactive)
          GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) => _buildPinIndicator(index)),
            ),
          ),

          // Hidden Native TextField
          Opacity(
            opacity: 0,
            child: SizedBox(
              height: 0,
              width: 0,
              child: TextField(
                controller: _pinController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: _onPinChanged,
                autofocus: true,
              ),
            ),
          ),

          const Spacer(),

          // 4. Secure Footer
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                "Your transaction is encrypted and secure",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPinIndicator(int index) {
    bool isFilled = _pinController.text.length > index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isFilled ? kAccentOrange : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isFilled ? kAccentOrange : kBrandNavy.withOpacity(0.2),
          width: 2,
        ),
      ),
    );
  }
}