import 'package:flutter/material.dart';
import '../models/deposit_account.dart';
import '../api/deposit_repository.dart';
import '../api/mock_otp_service.dart'; // Import for mockRegisteredMobile
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../utils/app_formatters.dart';
import 'otp_verification_dialog.dart'; // Your generic reusable dialog
import 'loan_success_screen.dart';

class LoanReviewScreen extends StatefulWidget {
  final DepositAccount deposit;
  final double requestedAmount;
  final double interestRate;
  final int tenureDays;

  const LoanReviewScreen({
    Key? key,
    required this.deposit,
    required this.requestedAmount,
    required this.interestRate,
    required this.tenureDays,
  }) : super(key: key);

  @override
  State<LoanReviewScreen> createState() => _LoanReviewScreenState();
}

class _LoanReviewScreenState extends State<LoanReviewScreen> {
  bool _agreeToTerms = false;

  /// Triggering the Generic OTP Dialog
  Future<void> _handleConfirm() async {
    // In a large-scale app, we fetch the mobile from the user profile.
    // Here we use the mock constant you provided in mock_otp_service.dart
    const String userMobile = mockRegisteredMobile;

    // showDialog returns the OTP String if verified, or null if cancelled
    final String? verifiedOtp = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpVerificationDialog(
        otpService: MockOtpService(), // Reusing your existing service
        mobileNumber: userMobile,
      ),
    );

    if (verifiedOtp != null) {
      // OTP is valid, proceed to success screen
      _navigateToSuccess();
    }
  }

  void _navigateToSuccess() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoanSuccessScreen(
          amount: widget.requestedAmount,
          targetAccount: widget.deposit.linkedAccountNumber,
          collateralId: widget.deposit.accountNumber,
        ),
      ),
          (route) => route.isFirst, // Security: Clears the navigation stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text("Review & Confirm"),
        backgroundColor: kAccentOrange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("APPLICATION SUMMARY"),
            _buildSummaryCard(),
            const SizedBox(height: 20),

            _buildHeader("DISBURSEMENT DETAILS"),
            _buildDisbursementCard(),
            const SizedBox(height: 20),

            _buildHeader("LIEN & LEGAL TERMS"),
            _buildLienAgreementSection(),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _agreeToTerms ? _handleConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandNavy,
                  disabledBackgroundColor: Colors.grey.shade400,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                ),
                child: const Text(
                    "CONFIRM & VERIFY OTP",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy, fontSize: 12, letterSpacing: 1.0)
    ),
  );

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            _row("Loan Amount Requested", AppFormatters.formatCurrency(widget.requestedAmount), isBold: true),
            _row("Interest Rate", "${widget.interestRate}% p.a."),
            _row("Tenure", "${widget.tenureDays} Days"),
            const Divider(height: 24),
            _row("Processing Fee", "₹ 0.00 (NIL)", color: kSuccessGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildDisbursementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            _row("Collateral Deposit", widget.deposit.accountNumber),
            _row("Credit Account", widget.deposit.linkedAccountNumber),
            _row("Account Holder", "Self"),
          ],
        ),
      ),
    );
  }

  Widget _buildLienAgreementSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(kRadiusMedium),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "By proceeding, you agree that a lien (legal hold) will be marked against your deposit. You cannot withdraw or close the deposit until the loan is settled in full.",
                  style: TextStyle(fontSize: 12, color: Colors.brown, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                  activeColor: kBrandNavy,
                  value: _agreeToTerms,
                  onChanged: (v) => setState(() => _agreeToTerms = v!)
              ),
              const Expanded(
                  child: Text(
                      "I accept the Lien Terms and Conditions.",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kBrandNavy)
                  )
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text(
            v,
            style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: color ?? kBrandNavy,
                fontSize: 13
            )
        ),
      ],
    ),
  );
}