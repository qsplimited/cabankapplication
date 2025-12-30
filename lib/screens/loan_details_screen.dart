import 'package:flutter/material.dart';
import '../models/deposit_account.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../utils/app_formatters.dart';
import 'loan_review_screen.dart'; // We will build this next

class LoanDetailsScreen extends StatefulWidget {
  final DepositAccount deposit;
  const LoanDetailsScreen({Key? key, required this.deposit}) : super(key: key);

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  final TextEditingController _amountController = TextEditingController();
  String? _errorText;
  bool _isEligible = false;

  // Constants based on Bank Standards
  final double marginRate = 2.0; // Bank adds 2% markup
  final double ltvRatio = 0.90;  // 90% Loan to Value

  late double maxLoanAmount;
  late double applicableROI;
  late int remainingDays;

  @override
  void initState() {
    super.initState();
    maxLoanAmount = widget.deposit.principalAmount * ltvRatio;
    applicableROI = widget.deposit.interestRate + marginRate;
    remainingDays = widget.deposit.maturityDate.difference(DateTime.now()).inDays;
  }

  void _onAmountChanged(String value) {
    double? entered = double.tryParse(value);
    setState(() {
      if (entered == null || entered <= 0) {
        _errorText = "Please enter a valid amount";
        _isEligible = false;
      } else if (entered > maxLoanAmount) {
        _errorText = "Exceeds 90% limit (${AppFormatters.formatCurrency(maxLoanAmount)})";
        _isEligible = false;
      } else {
        _errorText = null;
        _isEligible = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text("Apply for Loan"),
        backgroundColor: kAccentOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. COLLATERAL SUMMARY (Selected FD/RD)
            _buildSectionLabel("SELECTED COLLATERAL"),
            _buildCollateralCard(),
            const SizedBox(height: 20),

            // 2. LOAN CONFIGURATION (Calculations)
            _buildSectionLabel("LOAN CONFIGURATION"),
            _buildLoanConfigCard(),
            const SizedBox(height: 20),

            // 3. AMOUNT ENTRY
            _buildSectionLabel("HOW MUCH DO YOU NEED?"),
            _buildAmountInput(),
            const SizedBox(height: 20),

            // 4. DISBURSEMENT TARGET
            _buildSectionLabel("DISBURSEMENT ACCOUNT"),
            _buildDisbursementCard(),

            const SizedBox(height: 32),

            // PROCEED BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isEligible ? _navigateToReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                ),
                child: const Text("REVIEW APPLICATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
  );

  Widget _buildCollateralCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            _dataRow("Deposit Account", widget.deposit.accountNumber),
            _dataRow("Current Principal", AppFormatters.formatCurrency(widget.deposit.principalAmount)),
            _dataRow("Maturity Date", AppFormatters.formatDate(widget.deposit.maturityDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanConfigCard() {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
          color: kBrandLightBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(kRadiusMedium),
          border: Border.all(color: kBrandLightBlue.withOpacity(0.3))
      ),
      child: Column(
        children: [
          _dataRow("Max Eligibility (90%)", AppFormatters.formatCurrency(maxLoanAmount), color: kSuccessGreen),
          _dataRow("Loan ROI (FD + 2%)", "$applicableROI% p.a.", color: Colors.red),
          _dataRow("Estimated Tenure", "$remainingDays Days"),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      onChanged: _onAmountChanged,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandNavy),
      decoration: InputDecoration(
        prefixText: "₹ ",
        hintText: "0.00",
        errorText: _errorText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      ),
    );
  }

  Widget _buildDisbursementCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance, color: kAccentOrange),
        title: Text(widget.deposit.linkedAccountNumber),
        subtitle: const Text("Linked Savings Account"),
        trailing: const Icon(Icons.check_circle, color: kSuccessGreen),
      ),
    );
  }

  Widget _dataRow(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? kBrandNavy)),
      ],
    ),
  );

  void _navigateToReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoanReviewScreen(
          deposit: widget.deposit,
          requestedAmount: double.parse(_amountController.text),
          interestRate: applicableROI,
          tenureDays: remainingDays,
        ),
      ),
    );
  }
}