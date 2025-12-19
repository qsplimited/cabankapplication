import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../api/deposit_repository.dart';
import '../utils/app_formatters.dart';

class MaturityActionScreen extends StatefulWidget {
  final DepositAccount deposit;
  const MaturityActionScreen({Key? key, required this.deposit}) : super(key: key);

  @override
  _MaturityActionScreenState createState() => _MaturityActionScreenState();
}

class _MaturityActionScreenState extends State<MaturityActionScreen> {
  late String _selectedAction;
  String _selectedTenure = '1 Year';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // VALIDATION 1: Default selection depends on maturity status
    _selectedAction = widget.deposit.isMatured ? 'FULL_RENEWAL' : 'CLOSE';
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.deposit;
    final bool isMatured = deposit.isMatured;

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: Text(isMatured ? "Maturity Action" : "Early Withdrawal"),
        backgroundColor: kAccentOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // VALIDATION 2: Banner changes based on status
            isMatured ? _buildMaturityBanner() : _buildPrematureWarning(),

            const SizedBox(height: kSpacingMedium),

            // VALIDATION 3: Financial Summary includes penalty if not matured
            _buildFinancialSummary(deposit, !isMatured),

            const SizedBox(height: kSpacingLarge),
            const Text("Select Instruction", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: kPaddingSmall),

            // VALIDATION 4: Only show Renewals if the deposit is actually matured
            if (isMatured) ...[
              _buildActionOption(
                id: 'FULL_RENEWAL',
                title: "Renew Principal + Interest",
                subtitle: "Reinvest \$${deposit.totalMaturityAmount} for a new term.",
                icon: Icons.autorenew,
              ),
              _buildActionOption(
                id: 'PRINCIPAL_RENEWAL',
                title: "Renew Principal Only",
                subtitle: "Interest to A/C ${deposit.linkedAccountNumber}.",
                icon: Icons.account_balance,
              ),
            ],

            // Close option is always available
            _buildActionOption(
              id: 'CLOSE',
              title: isMatured ? "Close & Payout" : "Premature Payout",
              subtitle: "Transfer funds to A/C ${deposit.linkedAccountNumber}.",
              icon: Icons.exit_to_app,
            ),

            const SizedBox(height: kSpacingLarge),

            // VALIDATION 5: Tenure dropdown only for renewals
            if (_selectedAction != 'CLOSE' && isMatured) ...[
              const Text("New Tenure", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: kPaddingSmall),
              _buildTenureDropdown(),
            ],

            const SizedBox(height: kSpacingExtraLarge),

            _buildSubmitButton(isMatured),
          ],
        ),
      ),
    );
  }

  // --- Supporting UI Methods ---

  Widget _buildPrematureWarning() {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(color: kErrorRed.withOpacity(0.1), borderRadius: BorderRadius.circular(kRadiusSmall)),
      child: const Text("⚠ Withdrawal before maturity attracts a penalty on interest.",
          style: TextStyle(color: kErrorRed, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMaturityBanner() {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(color: kSuccessGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(kRadiusSmall)),
      child: const Text(" This deposit has matured. Select an action to proceed.",
          style: TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFinancialSummary(DepositAccount d, bool showPenalty) {
    double penalty = showPenalty ? (d.accruedInterest * 0.01) : 0.0;
    double netAmount = d.totalMaturityAmount - penalty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            _row("Principal", AppFormatters.formatCurrency(d.principalAmount)),
            _row("Interest", "+${AppFormatters.formatCurrency(d.accruedInterest)}"),
            if (showPenalty)
              _row("Early Penalty (1%)", "-${AppFormatters.formatCurrency(penalty)}", color: kErrorRed),
            const Divider(),
            // This will now show ₹1,08,250.00 correctly
            _row("Net Amount", AppFormatters.formatCurrency(netAmount), isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _row(String l, String v, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: kLightTextSecondary)),
          Text(v, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: color ?? kBrandNavy)),
        ],
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: kLightTextSecondary)),
              ]),
            ),
            if (selected) const Icon(Icons.check_circle, color: kBrandNavy),
          ],
        ),
      ),
    );
  }

  Widget _buildTenureDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(kRadiusSmall), border: Border.all(color: kDividerColor)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTenure,
          isExpanded: true,
          onChanged: (val) => setState(() => _selectedTenure = val!),
          items: ['1 Year', '3 Years'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isMatured) {
    return SizedBox(
      width: double.infinity,
      height: kButtonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: isMatured ? kBrandNavy : kErrorRed),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("CONFIRM", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _submit() async {
    setState(() => _isLoading = true);
    bool success = await DepositRepository().submitMaturityAction(
      depositId: widget.deposit.id,
      actionType: _selectedAction,
      tenure: _selectedTenure,
    );
    setState(() => _isLoading = false);
    if (success) Navigator.pop(context);
  }
}