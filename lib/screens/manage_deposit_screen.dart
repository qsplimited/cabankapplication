import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../api/deposit_repository.dart';
import 'maturity_action_screen.dart';
import 'edit_nominee_screen.dart';

class ManageDepositScreen extends StatefulWidget {
  // CRITICAL: We pass the specific deposit selected from the list
  final DepositAccount deposit;

  const ManageDepositScreen({Key? key, required this.deposit}) : super(key: key);

  @override
  _ManageDepositScreenState createState() => _ManageDepositScreenState();
}

class _ManageDepositScreenState extends State<ManageDepositScreen> {
  final DepositRepository _repository = DepositRepository();
  late DepositAccount _currentDeposit;

  @override
  void initState() {
    super.initState();
    _currentDeposit = widget.deposit;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    // Industry Standard: Differentiate Running vs Matured visually
    final bool isRunning = _currentDeposit.status == DepositStatus.running;

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: Text(_currentDeposit.accountType),
        backgroundColor: isRunning ? kAccentOrange : kAccentOrange,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. High-Level Summary Card
            _buildSummaryCard(_currentDeposit, isRunning),
            const SizedBox(height: kSpacingLarge),

            // 2. Dates & Key Details
            _sectionHeader("Tenure Details"),
            _buildInfoGrid(_currentDeposit, df),
            const SizedBox(height: kSpacingLarge),

            // 3. Nominees Section
            _sectionHeader(
              "Legal Nominees",
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => EditNomineeScreen(deposit: _currentDeposit),
                  ),
                );
              },
            ),
            ..._currentDeposit.nominees.map((n) => _buildNomineeCard(n)).toList(),

            const SizedBox(height: kSpacingExtraLarge),

            // 4. DYNAMIC ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => MaturityActionScreen(deposit: _currentDeposit),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isRunning ? kAccentOrange : kAccentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                ),
                child: Text(
                  isRunning ? "PREMATURE CLOSURE" : "SETTLE NOW",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(DepositAccount d, bool isRunning) {
    return Container(
      padding: const EdgeInsets.all(kPaddingLarge),
      decoration: BoxDecoration(
        color: isRunning ? kBrandNavy : kDarkTextSecondary,
        borderRadius: BorderRadius.circular(kRadiusMedium),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TOTAL VALUE (P+I)", style: TextStyle(color: Colors.white70, fontSize: 12)),
              _buildStatusBadge(d.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            d.totalMaturityAmount.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const Divider(color: Colors.white38, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat("Interest Rate", "${d.interestRate}%"),
              _stat("Accrued Interest", d.accruedInterest.toStringAsFixed(2)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(DepositStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _stat(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ],
  );

  Widget _buildInfoGrid(DepositAccount d, DateFormat f) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: kDividerColor),
        borderRadius: BorderRadius.circular(kRadiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            _dataRow("Opening Date", f.format(d.openingDate)),
            _dataRow("Maturity Date", f.format(d.maturityDate)),
            _dataRow("Payout Account", d.linkedAccountNumber),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: kLightTextSecondary)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)),
      ],
    ),
  );

  Widget _buildNomineeCard(Nominee n) => Card(
    elevation: 0,
    color: kInputBackgroundColor,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: const Icon(Icons.account_circle_outlined, color: kBrandNavy),
      title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(n.relationship, style: const TextStyle(fontSize: 12)),
      trailing: Text("${n.share}%", style: const TextStyle(color: kBrandNavy, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _sectionHeader(String t, {VoidCallback? onEdit}) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kBrandNavy)),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: const Text("Edit Details", style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
      ],
    ),
  );
}