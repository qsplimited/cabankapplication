import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Logic & Model Imports
import 'package:cabankapplication/screens/pdf_download_logic.dart';
import 'package:cabankapplication/models/data_models.dart';
import '../providers/transaction_history_provider.dart';
import '../models/transaction_history_model.dart' as model;

// Theme & Dimensions
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String accountNumber;
  const TransactionHistoryScreen({super.key, required this.accountNumber});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(transactionHistoryProvider(widget.accountNumber));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Statement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: kAccentOrange)),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (transactions) {
          final balance = transactions.isNotEmpty ? transactions.last.currentBalance : 0.0;

          return Column(
            children: [
              _buildHeader(balance),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // RECENT TAB: Only show 5 transactions
                    _buildTransactionList(transactions.reversed.take(5).toList()),
                    // DETAILED TAB: Full history with filters
                    _buildDetailedView(transactions),
                  ],
                ),
              ),
              // Added significant space at the bottom to prevent "clumsy" look
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(double balance) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("A/C: XXXX ${widget.accountNumber.substring(widget.accountNumber.length > 4 ? widget.accountNumber.length - 4 : 0)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const Text("Available Balance", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          Text("₹${balance.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kAccentOrange)),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(kRadiusMedium),
          color: kAccentOrange,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [Tab(text: "RECENT"), Tab(text: "DETAILED")],
      ),
    );
  }

  Widget _buildDetailedView(List<model.TransactionHistory> allTxs) {
    final filtered = allTxs.where((t) =>
    t.transactionDateTime.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
        t.transactionDateTime.isBefore(_endDate.add(const Duration(days: 1)))
    ).toList().reversed.toList();

    return Column(
      children: [
        // Filter Selection
        Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Row(
            children: [
              Expanded(child: _datePickerBox("From", _startDate, true)),
              const SizedBox(width: 12),
              Expanded(child: _datePickerBox("To", _endDate, false)),
            ],
          ),
        ),
        // Aligned Download Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
          child: OutlinedButton.icon(
            onPressed: () => _handlePdfDownload(filtered),
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
            label: const Text("DOWNLOAD PDF STATEMENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kAccentOrange,
              side: const BorderSide(color: kAccentOrange),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildTransactionList(filtered)),
      ],
    );
  }

  Widget _datePickerBox(String label, DateTime date, bool isStart) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: isStart ? DateTime(2022) : _startDate, // End date cannot be before start
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            if (isStart) {
              _startDate = picked;
              if (_startDate.isAfter(_endDate)) _endDate = _startDate;
            } else {
              _endDate = picked;
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(kRadiusSmall),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(DateFormat('dd-MM-yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<model.TransactionHistory> txs) {
    if (txs.isEmpty) return const Center(child: Text("No transactions found", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final tx = txs[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(kRadiusMedium),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tx.isDebit ? kErrorRed.withOpacity(0.1) : kSuccessGreen.withOpacity(0.1),
                child: Icon(tx.isDebit ? Icons.call_made : Icons.call_received, size: 16, color: tx.isDebit ? kErrorRed : kSuccessGreen),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tx.isDebit ? "Paid to Transfer" : "Received Credit",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(DateFormat('dd MMM yyyy').format(tx.transactionDateTime),
                        style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Text(
                "${tx.isDebit ? '-' : '+'} ₹${tx.transactionAmount.toStringAsFixed(2)}",
                style: TextStyle(color: tx.isDebit ? kErrorRed : kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePdfDownload(List<model.TransactionHistory> history) async {
    final List<Transaction> pdfTxs = history.map((h) => Transaction(
      description: h.isDebit ? "Paid to Transfer" : "Received Credit",
      amount: h.transactionAmount,
      date: h.transactionDateTime,
      type: h.isDebit ? TransactionType.debit : TransactionType.credit,
    )).toList();

    final account = Account(
      accountNumber: widget.accountNumber,
      balance: history.isNotEmpty ? history.first.currentBalance : 0.0,
      accountType: "Savings",
      nickname: "User",
    );

    bool success = await generateAndSavePdf(
      pdfTxs,
      account,
      DateFormat('dd-MM-yyyy').format(_startDate),
      DateFormat('dd-MM-yyyy').format(_endDate),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Statement saved to downloads" : "Download failed")),
      );
    }
  }
}