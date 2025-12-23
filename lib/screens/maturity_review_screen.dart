import 'package:flutter/material.dart';
import '../api/mock_otp_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../utils/app_formatters.dart';
import 'common_otp_screen.dart';
import 'success_receipt_screen.dart'; // Ensure you create this file next

class MaturityReviewScreen extends StatelessWidget {
  final DepositAccount deposit;
  final String actionType;
  final String tenure;

  const MaturityReviewScreen({
    Key? key,
    required this.deposit,
    required this.actionType,
    required this.tenure,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : kLightBackground,
      appBar: AppBar(
        title: const Text("Confirm Instruction"),
        backgroundColor: kAccentOrange,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                children: [
                  _buildActionSummaryHeader(),
                  const SizedBox(height: kSpacingMedium),
                  _buildVisualFlowCard(isDarkMode),
                  const SizedBox(height: kSpacingLarge),
                  _buildNomineeSection(isDarkMode),
                  const SizedBox(height: kSpacingLarge),
                  _buildTermsNotice(isDarkMode),
                ],
              ),
            ),
          ),
          _buildStylishFooter(context),
        ],
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildActionSummaryHeader() {
    String title = "";
    String description = "";

    if (actionType == 'FULL_RENEWAL') {
      title = "TOTAL RENEWAL";
      description = "Reinvesting principal and interest into a new term.";
    } else if (actionType == 'PRINCIPAL_RENEWAL') {
      title = "PARTIAL RENEWAL";
      description = "Renewing principal only; interest will be paid out.";
    } else {
      title = "FULL PAYOUT";
      description = "Closing account and transferring all funds to savings.";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: kAccentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kRadiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kAccentOrange, fontSize: 16)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(fontSize: 13, color: kLightTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildVisualFlowCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: isDark ? kBrandNavy.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(color: kAccentOrange.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildFlowPoint("Source Account", deposit.accountNumber, AppFormatters.formatCurrency(deposit.totalMaturityAmount), isSource: true),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.keyboard_double_arrow_down_rounded, color: kAccentOrange.withOpacity(0.4)),
          ),
          if (actionType != 'CLOSE')
            _buildFlowPoint("New Fixed Deposit", "Tenure: $tenure", _getRenewalAmount(), color: kBrandNavy),
          if (actionType != 'FULL_RENEWAL') ...[
            const SizedBox(height: 12),
            _buildFlowPoint("Savings Payout", "A/C: ${deposit.linkedAccountNumber}", _getPayoutAmount(), color: kSuccessGreen),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowPoint(String label, String sub, String amount, {bool isSource = false, Color? color}) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: (color ?? kAccentOrange).withOpacity(0.1),
          child: Icon(isSource ? Icons.account_balance_wallet : Icons.arrow_forward_rounded, color: color ?? kAccentOrange, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: kLightTextSecondary)),
            Text(sub, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
        Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color)),
      ],
    );
  }

  Widget _buildNomineeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LEGAL NOMINEE DETAILS", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 13, color: kBrandNavy)),
        const SizedBox(height: 10),
        ...deposit.nominees.map((n) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(kPaddingMedium),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(kRadiusMedium),
            border: Border.all(color: kDividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_pin_rounded, color: kAccentOrange, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("${n.relationship} | ${n.share}% Share", style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildTermsNotice(bool isDark) {
    return Text(
      "By clicking authenticate, you authorize the closure of A/C ${deposit.accountNumber} and execution of the instructions above.",
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: kLightTextSecondary, height: 1.4),
    );
  }

  Widget _buildStylishFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: kButtonHeight,
          child: ElevatedButton(
            onPressed: () => _showFinalAuth(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              elevation: 0,
            ),
            child: const Text("AUTHENTICATE & CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  String _getRenewalAmount() => actionType == 'FULL_RENEWAL' ? AppFormatters.formatCurrency(deposit.totalMaturityAmount) : AppFormatters.formatCurrency(deposit.principalAmount);
  String _getPayoutAmount() => actionType == 'CLOSE' ? AppFormatters.formatCurrency(deposit.totalMaturityAmount) : AppFormatters.formatCurrency(deposit.accruedInterest);

  void _showFinalAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommonOtpScreen(
          transactionTitle: "Maturity Authorization",
          mobileNumber: mockRegisteredMobile,
          subDetails: "Verifying instruction for Account ${deposit.accountNumber}",
          onSuccess: () {
            _navigateToSuccess(context);
          },
        ),
      ),
    );
  }

  void _navigateToSuccess(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => SuccessReceiptScreen(
          transactionId: "TXN${DateTime.now().millisecondsSinceEpoch}",
          amount: actionType == 'CLOSE'
              ? deposit.totalMaturityAmount
              : (actionType == 'FULL_RENEWAL' ? deposit.totalMaturityAmount : deposit.principalAmount),
          accountNumber: deposit.accountNumber,
          actionName: actionType.replaceAll('_', ' '),
        ),
      ),
          (route) => route.isFirst,
    );
  }
}