import 'package:cabankapplication/screens/pdf_download_logic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. CORE MODELS & PROVIDERS
import 'package:cabankapplication/models/data_models.dart';
import '../api/banking_service.dart' as service;
import '../providers/banking_provider.dart';

// THEME IMPORTS
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// --- Enums and Models ---

enum TransactionViewMode {
  Recent,
  Detailed,
}

class TransactionRowData {
  final Transaction transaction;
  final double runningBalance;

  TransactionRowData({required this.transaction, required this.runningBalance});
}

// --- Main Widget (Converted to ConsumerStatefulWidget) ---

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  // State Variables
  List<TransactionRowData> _displayData = [];
  TransactionViewMode _viewMode = TransactionViewMode.Detailed;

  late DateTime _startDate;
  late DateTime _endDate;
  bool _filtersApplied = false;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
  }

  // --- Data Filtering & Running Balance Logic ---

  void _applyFilters(List<service.Transaction> allTxsFromService, service.Account? accountFromService) {
    if (accountFromService == null || allTxsFromService.isEmpty) {
      setState(() {
        _displayData = [];
      });
      return;
    }

    // Explicit Type Mapping from service model to UI model
    final List<Transaction> allTransactions = allTxsFromService.map((txService) {
      return Transaction(
        description: txService.description,
        amount: txService.amount,
        date: txService.date,
        type: txService.type == service.TransactionType.credit
            ? TransactionType.credit
            : TransactionType.debit,
      );
    }).toList();

    final endOfEndDate = _endDate.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    final filteredTxs = allTransactions
        .where((t) =>
    t.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
        t.date.isBefore(endOfEndDate))
        .toList();

    filteredTxs.sort((a, b) => a.date.compareTo(b.date));
    _displayData = _calculateRunningBalance(filteredTxs, accountFromService.balance);
    _filtersApplied = true;
  }

  List<TransactionRowData> _calculateRunningBalance(List<Transaction> transactions, double currentBalance) {
    final List<TransactionRowData> data = [];
    if (transactions.isEmpty) return data;

    double netEffect = 0;
    for (var t in transactions) {
      netEffect += (t.type == TransactionType.credit) ? t.amount : -t.amount;
    }

    double balanceBeforeStatement = currentBalance - netEffect;
    double currentStatementBalance = balanceBeforeStatement;

    for (var t in transactions) {
      if (t.type == TransactionType.credit) {
        currentStatementBalance += t.amount;
      } else {
        currentStatementBalance -= t.amount;
      }

      data.add(TransactionRowData(
        transaction: t,
        runningBalance: currentStatementBalance,
      ));
    }
    return data;
  }

  // --- UI Interactivity ---

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final colorScheme = Theme.of(context).colorScheme;
    DateTime initialDate = isStart ? _startDate : _endDate;
    DateTime firstDate = isStart ? DateTime(2000) : _startDate;
    DateTime lastDate = isStart ? _endDate : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
        _filtersApplied = false; // Trigger re-filter in build
      });
    }
  }

  Future<void> _handlePdfDownload(service.Account account) async {
    if (_displayData.isEmpty) return;

    final transactionsToDownload = _displayData.map((d) => d.transaction).toList();

    // Map to the core Account type expected by pdf_download_logic
    final coreAccount = Account(
      accountNumber: account.accountNumber,
      balance: account.balance,
      accountType: 'Checking',
      nickname: account.nickname,
    );

    await generateAndSavePdf(
      transactionsToDownload,
      coreAccount,
      DateFormat('dd-MM-yyyy').format(_startDate),
      DateFormat('dd-MM-yyyy').format(_endDate),
    );
  }

  // --- Main Build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use Riverpod to watch data
    final transactionsAsync = ref.watch(transactionFutureProvider);
    final accountAsync = ref.watch(accountFutureProvider);

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (account) => transactionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (allTxs) {
            // Re-apply filters when data is available
            if (!_filtersApplied) _applyFilters(allTxs, account);

            final recentTransactions = _displayData.length > 10
                ? _displayData.sublist(_displayData.length - 10).toList()
                : _displayData;

            return Column(
              children: [
                _buildAccountHeader(account!),
                _buildTabView(),
                const Divider(height: 1, color: kDividerColor),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_viewMode == TransactionViewMode.Recent)
                          _buildTransactionList(data: recentTransactions, isDetailedView: false)
                        else ...[
                          _buildDetailedStatementControls(),
                          _buildTransactionList(data: _displayData, isDetailedView: true),
                        ],
                        const SizedBox(height: kPaddingLarge),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- ALL UI COMPONENTS COPIED FROM YOUR ORIGINAL DESIGN ---

  Widget _buildAccountHeader(service.Account account) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Account History',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_viewMode == TransactionViewMode.Detailed)
                TextButton(
                  onPressed: () => _handlePdfDownload(account),
                  child: Text('Download', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: kPaddingTen),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A/C: XXXX ${account.accountNumber.substring(account.accountNumber.length - 4)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.6))),
                  const SizedBox(height: kPaddingExtraSmall),
                  Text('Current Balance', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
              Text(
                '₹${account.balance.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall),
      child: Row(
        children: [
          _buildTabPill(TransactionViewMode.Recent, 'Recent Transactions'),
          const SizedBox(width: kPaddingSmall),
          _buildTabPill(TransactionViewMode.Detailed, 'Detailed Statement'),
        ],
      ),
    );
  }

  Widget _buildTabPill(TransactionViewMode mode, String label) {
    final isSelected = _viewMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() { _viewMode = mode; _filtersApplied = false; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: kPaddingTen),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
            border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStatementControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Row(
            children: [
              Expanded(child: _datePickerButton(date: _startDate, label: 'Start Date', isStart: true)),
              const SizedBox(width: kPaddingMedium),
              Expanded(child: _datePickerButton(date: _endDate, label: 'End Date', isStart: false)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
          child: Text('Showing Transactions (${_displayData.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: kPaddingTen),
      ],
    );
  }

  Widget _datePickerButton({required DateTime date, required String label, required bool isStart}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('dd-MM-yyyy').format(date), style: const TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionList({required List<TransactionRowData> data, required bool isDetailedView}) {
    if (data.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No transactions found.')));

    final listToDisplay = data.reversed.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listToDisplay.length,
      itemBuilder: (context, index) {
        final row = listToDisplay[index];
        final tx = row.transaction;
        final isDebit = tx.type == TransactionType.debit;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDebit ? kErrorRed : kSuccessGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isDebit ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(DateFormat('dd MMM yyyy').format(tx.date), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isDebit ? "-" : "+"} ₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: isDebit ? kErrorRed : kSuccessGreen, fontWeight: FontWeight.bold),
                      ),
                      if (isDetailedView)
                        Text('Bal: ₹${row.runningBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const Divider(height: 20),
            ],
          ),
        );
      },
    );
  }
}