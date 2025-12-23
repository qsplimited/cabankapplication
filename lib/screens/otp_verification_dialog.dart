// File: lib/screens/otp_verification_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/mock_otp_service.dart'; // Use the abstract interface defined in mock_otp_service.dart
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'dart:async';

class OtpVerificationDialog extends StatefulWidget {
  final OtpService otpService;
  final String mobileNumber;

  const OtpVerificationDialog({
    super.key,
    required this.otpService,
    required this.mobileNumber,
  });

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  // Initialize controllers and focus nodes for the 6 OTP fields
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isVerifying = false;
  int _resendSeconds = 30;
  Timer? _resendTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    _sendOtp();

    // Add listeners to controllers to handle automatic focus shift
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].addListener(() {
        if (_otpControllers[i].text.length == 1) {
          if (i < 5) {
            _focusNodes[i + 1].requestFocus(); // Move to next field
          }
        } else if (_otpControllers[i].text.length > 1) {
          _otpControllers[i].text = _otpControllers[i].text.substring(_otpControllers[i].text.length - 1);
        }

        if (_errorMessage != null && mounted) {
          setState(() {
            _errorMessage = null; // Clear error on new input
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _resendTimer?.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();

    try {
      setState(() {
        _errorMessage = null;
        _isVerifying = true;
      });
      await widget.otpService.sendOtp(widget.mobileNumber);
      _startResendTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to ****${widget.mobileNumber.substring(widget.mobileNumber.length - 4)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() {
        _errorMessage = 'Failed to send OTP. Please try again.';
      });
    } finally {
      if (mounted) setState(() {
        _isVerifying = false;
      });
    }
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    final otp = _currentOtp;

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.otpService.verifyOtp(
        widget.mobileNumber,
        otp,
      );

      if (mounted) {
        if (success) {
          // 🌟 CRUCIAL: Pop the actual verified OTP string (e.g., '654321')
          Navigator.of(context).pop(otp);
        } else {
          setState(() {
            _errorMessage = 'Invalid OTP. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        _errorMessage = 'Verification failed. Try again later.';
      });
    } finally {
      if (mounted) setState(() {
        _isVerifying = false;
      });
    }
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 38.0,
      height: 45.0,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.delete) {
              if (_otpControllers[index].text.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            }
          }
        },
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: kBrandNavy,
            fontWeight: FontWeight.bold,
            fontSize: 22.0,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: kInputBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall),
              borderSide: const BorderSide(color: kLightDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall),
              borderSide: const BorderSide(color: kBrandLightBlue, width: 2.0),
            ),
          ),
          autofocus: index == 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('OTP Verification Required', style: textTheme.titleLarge?.copyWith(color: kBrandNavy)),
      contentPadding: const EdgeInsets.fromLTRB(kPaddingMedium, kPaddingMedium, kPaddingMedium, kPaddingSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'A One-Time Password (OTP) has been sent to your registered mobile number: ****${widget.mobileNumber.substring(widget.mobileNumber.length - 4)}',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: kPaddingMedium),

            // --- 6 OTP Input Boxes ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) => _buildOtpBox(index)),
            ),

            // Error Message
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: kPaddingSmall),
                child: Text(
                  _errorMessage!,
                  style: textTheme.labelSmall?.copyWith(color: kErrorRed),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: kPaddingSmall),

            // Resend Timer/Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_resendSeconds > 0)
                  Text(
                    'Resend in $_resendSeconds seconds',
                    style: textTheme.bodySmall?.copyWith(color: kLightTextSecondary),
                  )
                else
                  TextButton(
                    onPressed: _isVerifying ? null : _sendOtp,
                    child: const Text('RESEND OTP'),
                  ),
              ],
            ),
            const SizedBox(height: kPaddingLarge),

            // Verification Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isVerifying || _currentOtp.length != 6) ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, kButtonHeight),
                ),
                child: _isVerifying
                    ? const SizedBox(
                  height: kIconSizeSmall,
                  width: kIconSizeSmall,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                )
                    : const Text('VERIFY & CONFIRM'),
              ),
            ),
          ],
        ),
      ),
      // Action to allow cancelling the dialog
      actions: [
        TextButton(
          onPressed: () {
            // Pop null to signify cancellation
            Navigator.of(context).pop(null);
          },
          child: const Text('CANCEL', style: TextStyle(color: kErrorRed)),
        ),
      ],
      actionsAlignment: MainAxisAlignment.end,
    );
  }
}