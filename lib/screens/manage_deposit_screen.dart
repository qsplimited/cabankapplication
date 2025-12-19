import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../api/deposit_repository.dart';
import 'maturity_action_screen.dart';
import 'edit_nominee_screen.dart'; // Ensure this is imported

class ManageDepositScreen extends StatefulWidget {
  const ManageDepositScreen({Key? key}) : super(key: key);

  @override
  _ManageDepositScreenState createState() => _ManageDepositScreenState();
}

class _ManageDepositScreenState extends State<ManageDepositScreen> {
  final DepositRepository _repository = DepositRepository();
  late Future<DepositAccount> _depositFuture;

  @override
  void initState() {
    super.initState();
    _depositFuture = _repository.fetchDepositDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text("Deposit Hub"),
        backgroundColor: kAccentOrange,
      ),
      body: FutureBuilder<DepositAccount>(
        future: _depositFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error Loading Data"));
          }

          final deposit = snapshot.data!;
          final df = DateFormat('dd MMM yyyy');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. High-Level Summary Card
                _buildSummaryCard(deposit),
                const SizedBox(height: kSpacingLarge),

                // 2. Dates & Key Details
                _sectionHeader("Tenure Details"),
                _buildInfoGrid(deposit, df),
                const SizedBox(height: kSpacingLarge),

                // 3. Nominees Section with Update Option
                _sectionHeader(
                  "Legal Nominees",
                  onEdit: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => EditNomineeScreen(deposit: deposit),
                      ),
                    );
                  },
                ),
                ...deposit.nominees.map((n) => _buildNomineeCard(n)).toList(),

                const SizedBox(height: kSpacingExtraLarge),

                // 4. ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: kButtonHeight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => MaturityActionScreen(deposit: deposit),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                    child: Text(
                      deposit.isMatured ? "SETTLE NOW" : "MANAGE MATURITY",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSummaryCard(DepositAccount d) {
    return Container(
      padding: const EdgeInsets.all(kPaddingLarge),
      decoration: BoxDecoration(
        color: kDarkTextSecondary,
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TOTAL VALUE (P+I)",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            d.totalMaturityAmount.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white38, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat("Rate", "${d.interestRate}%"),
              _stat("Interest", d.accruedInterest.toStringAsFixed(2)),
            ],
          )
        ],
      ),
    );
  }

  Widget _stat(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(v,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
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
        Text(v, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _buildNomineeCard(Nominee n) => Card(
    color: kInputBackgroundColor,
    child: ListTile(
      leading: const Icon(Icons.verified_user, color: kBrandNavy),
      title: Text(n.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(n.relationship),
      trailing: Text("${n.share}%",
          style: const TextStyle(
              color: kBrandNavy, fontWeight: FontWeight.bold)),
    ),
  );

  Widget _sectionHeader(String t, {VoidCallback? onEdit}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: kBrandNavy)),
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            child: const Text(
              "Update",
              style: TextStyle(
                  color: kAccentOrange, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    ),
  );
}