import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../utils/app_formatters.dart';

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

  Widget _buildVisualFlowCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: isDark ? kBrandNavy.withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        border: Border.all(color: kAccentOrange.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          _buildFlowPoint("From Deposit", deposit.accountNumber, AppFormatters.formatCurrency(deposit.totalMaturityAmount), isSource: true),

          // Visual Connector
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Icon(Icons.account_tree_outlined, color: kAccentOrange.withOpacity(0.5)),
          ),

          if (actionType != 'CLOSE')
            _buildFlowPoint("Renewal (New FD)", "Tenure: $tenure", _getRenewalAmount(), color: kBrandNavy),

          if (actionType != 'FULL_RENEWAL') ...[
            const SizedBox(height: 12),
            _buildFlowPoint("Payout (Savings)", "A/C: ${deposit.linkedAccountNumber}", _getPayoutAmount(), color: kSuccessGreen),
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
          child: Icon(isSource ? Icons.upload : Icons.download, color: color ?? kAccentOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: kLightTextSecondary)),
            Text(sub, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ]),
        ),
        Text(amount, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
      ],
    );
  }

  Widget _buildNomineeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LEGAL NOMINEES", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12, color: kLightTextSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: deposit.nominees.map((n) => Chip(
            backgroundColor: isDark ? Colors.grey[900] : Colors.white,
            side: const BorderSide(color: kDividerColor),
            avatar: const Icon(Icons.person, size: 16, color: kAccentOrange),
            label: Text("${n.name} (${n.share}%)", style: const TextStyle(fontSize: 12)),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTermsNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(kPaddingSmall),
      decoration: BoxDecoration(color: Colors.amber.withOpacity(0.05), borderRadius: BorderRadius.circular(kRadiusSmall)),
      child: const Text(
        "By proceeding, you authorize the bank to close the existing deposit and execute instructions as per the breakdown above.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: kLightTextSecondary, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildStylishFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: kButtonHeight,
          child: ElevatedButton(
            onPressed: () => _showFinalAuth(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentOrange, // Matches AppBar for uniqueness
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              elevation: 0,
            ),
            child: const Text("AUTHENTICATE & CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // Same logic as before for split calculation
  String _getRenewalAmount() => actionType == 'FULL_RENEWAL' ? AppFormatters.formatCurrency(deposit.totalMaturityAmount) : AppFormatters.formatCurrency(deposit.principalAmount);
  String _getPayoutAmount() => actionType == 'CLOSE' ? AppFormatters.formatCurrency(deposit.totalMaturityAmount) : AppFormatters.formatCurrency(deposit.accruedInterest);

  void _showFinalAuth(BuildContext context) {
    // Navigate to T-PIN as the final step
  }
}