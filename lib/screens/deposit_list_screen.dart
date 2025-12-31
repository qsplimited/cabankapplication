import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../api/deposit_repository.dart';
import '../utils/app_formatters.dart';
import 'manage_deposit_screen.dart'; // This is your "Deposit Hub"
import 'loan_details_screen.dart';

// Define an enum for clarity - easy for newcomers to read
enum DepositListMode { manage, loan }

class DepositListScreen extends StatefulWidget {
  final DepositListMode mode; // mode for manage and LAD

  const DepositListScreen({
    Key? key,
    this.mode = DepositListMode.manage // Default is manage
  }) : super(key: key);

  @override
  State<DepositListScreen> createState() => _DepositListScreenState();
}

class _DepositListScreenState extends State<DepositListScreen> with SingleTickerProviderStateMixin {
  final DepositRepository _repository = DepositRepository();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text("My Deposits"),
        backgroundColor: kAccentOrange,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: FutureBuilder<List<DepositAccount>>(
        future: _repository.fetchAllDeposits(), // 🌟 Using the new list-based API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading deposits"));
          }

          final allDeposits = snapshot.data ?? [];

          // Filter deposits based on status
          final activeDeposits = allDeposits.where((d) => d.status != DepositStatus.closed).toList();
          final historyDeposits = allDeposits.where((d) => d.status == DepositStatus.closed).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(activeDeposits),
              _buildList(historyDeposits),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<DepositAccount> deposits) {
    if (deposits.isEmpty) {
      return const Center(child: Text("No deposits found", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(kPaddingMedium),
      itemCount: deposits.length,
      itemBuilder: (context, index) {
        return _buildDepositCard(deposits[index]);
      },
    );
  }

  Widget _buildDepositCard(DepositAccount d) {
    bool isMatured = d.status == DepositStatus.matured;
    bool isRD = d.accountType.contains("Recurring");

    return GestureDetector(
      onTap: () {
        if (widget.mode == DepositListMode.loan) {
          // Navigate to Loan Details Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => LoanDetailsScreen(deposit: d)),
          );
        } else {
          // Navigate to Management Screen (Current behavior)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => ManageDepositScreen(deposit: d)),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: kPaddingMedium),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
        child: Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isRD ? kBrandPurple.withOpacity(0.1) : kAccentOrange.withOpacity(0.1),
                    child: Icon(isRD ? Icons.update : Icons.lock_clock, color: isRD ? kBrandPurple : kAccentOrange),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.accountType, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)),
                        Text(d.accountNumber, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(d.status),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniDetail("Principal", AppFormatters.formatCurrency(d.principalAmount)),
                  _miniDetail("ROI", "${d.interestRate}%"),
                  _miniDetail("Maturity", AppFormatters.formatDate(d.maturityDate)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(DepositStatus status) {
    Color color;
    String text;
    switch (status) {
      case DepositStatus.running:
        color = kSuccessGreen;
        text = "RUNNING";
        break;
      case DepositStatus.matured:
        color = kAccentOrange;
        text = "MATURED";
        break;
      case DepositStatus.closed:
        color = Colors.grey;
        text = "CLOSED";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _miniDetail(String l, String v) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      Text(v, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kBrandNavy)),
    ],
  );
}