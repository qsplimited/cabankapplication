import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../utils/app_formatters.dart';
import 'maturity_review_screen.dart';

class MaturityActionScreen extends StatefulWidget {
  final DepositAccount deposit;
  const MaturityActionScreen({Key? key, required this.deposit}) : super(key: key);

  @override
  _MaturityActionScreenState createState() => _MaturityActionScreenState();
}

class _MaturityActionScreenState extends State<MaturityActionScreen> {
  late String _selectedAction;
  String _selectedTenure = '1 Year';

  final List<String> _tenureOptions = ['6 Months', '1 Year', '2 Years', '3 Years', '5 Years'];

  @override
  void initState() {
    super.initState();
    // LOGIC: Default to Renewal for Matured, Close for Running
    _selectedAction = widget.deposit.status == DepositStatus.matured ? 'FULL_RENEWAL' : 'CLOSE';
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.deposit;
    final bool isMatured = deposit.status == DepositStatus.matured;
    final bool isRunning = deposit.status == DepositStatus.running;

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: Text(isMatured ? "Maturity Instructions" : "Premature Closure"),
        backgroundColor: isRunning ? kAccentOrange : kAccentOrange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMatured ? _buildMaturityBanner() : _buildPrematureWarning(),
            const SizedBox(height: kSpacingMedium),

            // Financial Preview: Shows Penalty if isRunning is true
            _buildFinancialSummary(deposit, isRunning),
            const SizedBox(height: kSpacingLarge),

            const Text("What would you like to do?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrandNavy)),
            const SizedBox(height: kPaddingSmall),

            if (isMatured) ...[
              _buildActionOption(
                id: 'FULL_RENEWAL',
                title: "Renew Principal + Interest",
                subtitle: "Reinvest total amount for a new term",
                icon: Icons.autorenew,
              ),
              _buildActionOption(
                id: 'PRINCIPAL_RENEWAL',
                title: "Renew Principal Only",
                subtitle: "Interest will be paid to your Savings Account",
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],

            _buildActionOption(
              id: 'CLOSE',
              title: isMatured ? "Close & Payout" : "Withdraw Entire Amount",
              subtitle: "Funds will be credited to A/C ${deposit.linkedAccountNumber}",
              icon: Icons.logout_rounded,
            ),

            if (_selectedAction != 'CLOSE' && isMatured) ...[
              const SizedBox(height: kSpacingLarge),
              const Text("Select Renewal Tenure", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: kPaddingSmall),
              _buildTenureDropdown(),
            ],

            const SizedBox(height: kSpacingExtraLarge),
            _buildSubmitButton(isRunning),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary(DepositAccount d, bool isPremature) {
    // Logic: 1% Penalty on Accrued Interest for early withdrawal
    double penalty = isPremature ? (d.accruedInterest * 0.01) : 0.0;
    double netAmount = d.totalMaturityAmount - penalty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            _row("Current Principal", AppFormatters.formatCurrency(d.principalAmount)),
            _row("Interest Earned", "+ ${AppFormatters.formatCurrency(d.accruedInterest)}"),
            if (isPremature)
              _row("Premature Penalty (1%)", "- ${AppFormatters.formatCurrency(penalty)}", color: kErrorRed),
            const Divider(height: 24),
            _row("Net Payout Amount", AppFormatters.formatCurrency(netAmount), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildActionOption({required String id, required String title, required String subtitle, required IconData icon}) {
    bool selected = _selectedAction == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedAction = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: kPaddingSmall),
        padding: const EdgeInsets.all(kPaddingMedium),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? kBrandNavy : kDividerColor, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(kRadiusMedium),
          color: selected ? kBrandNavy.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? kBrandNavy : kLightTextSecondary),
            const SizedBox(width: kPaddingMedium),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? kBrandNavy : kDarkTextPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: kLightTextSecondary)),
              ]),
            ),
            if (selected) const Icon(Icons.check_circle, color: kBrandNavy, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTenureDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadiusSmall), border: Border.all(color: kDividerColor), color: Colors.white),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTenure,
          isExpanded: true,
          onChanged: (val) => setState(() => _selectedTenure = val!),
          items: _tenureOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isRunning) {
    return SizedBox(
      width: double.infinity,
      height: kButtonHeight,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => MaturityReviewScreen(
                deposit: widget.deposit,
                actionType: _selectedAction,
                tenure: _selectedTenure,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: isRunning ? kAccentOrange : kAccentOrange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall))
        ),
        child: const Text("PROCEED TO REVIEW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMaturityBanner() => Container(
    padding: const EdgeInsets.all(kPaddingSmall),
    decoration: BoxDecoration(color: kSuccessGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(kRadiusSmall)),
    child: const Row(children: [Icon(Icons.stars, color: kSuccessGreen, size: 18), SizedBox(width: 8), Text("This deposit is ready for settlement.", style: TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 12))]),
  );

  Widget _buildPrematureWarning() => Container(
    padding: const EdgeInsets.all(kPaddingSmall),
    decoration: BoxDecoration(color: kErrorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(kRadiusSmall)),
    child: const Row(children: [Icon(Icons.info_outline, color: kErrorRed, size: 18), SizedBox(width: 8), Expanded(child: Text("Closing early reduces your interest rate and incurs a penalty.", style: TextStyle(color: kErrorRed, fontSize: 12, fontWeight: FontWeight.w500)))]),
  );

  Widget _row(String l, String v, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
          Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? kBrandNavy, fontSize: 14)),
        ],
      ),
    );
  }
}