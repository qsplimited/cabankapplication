// File: lib/screens/detailed_statement_screen.dart (Refactored)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/banking_service.dart';
import '../main.dart'; // Assuming Account and Transaction models are here

// 💡 IMPORTANT: Import centralized design files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// This screen will handle fetching and displaying the full transaction history,
// and will include features for: Date Range Filtering, Downloading Statement.

class DetailedStatementScreen extends StatefulWidget {
  final BankingService bankingService;
  final Account account;

  const DetailedStatementScreen({
    super.key,
    required this.bankingService,
    required this.account,
  });

  @override
  State<DetailedStatementScreen> createState() => _DetailedStatementScreenState();
}

class _DetailedStatementScreenState extends State<DetailedStatementScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // --- Date Range State ---
  // Start with the last 30 days as default
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch initial statement for the last 30 days
    _fetchDetailedStatement();
  }

  // --- Data Fetching Logic (Unchanged) ---
  Future<void> _fetchDetailedStatement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allTransactions = await widget.bankingService.fetchTransactionHistory(
        widget.account.accountId,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _transactions = allTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load statement. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  // --- UI Components ---

  Future<void> _selectDateRange(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              // Refactored colors for Date Picker Theme
              primary: colorScheme.primary,
              onPrimary: colorScheme.onPrimary,
              surface: colorScheme.surface,
              onSurface: colorScheme.onSurface,
            ),
            dialogBackgroundColor: colorScheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      // Re-fetch data for the new date range
      _fetchDetailedStatement();
    }
  }

  // 1. Filter and Download Bar
  Widget _buildFilterAndDownloadBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // Replaced hardcoded padding with constants (16.0, 10.0)
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingTen),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date Range Picker
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                // Replaced hardcoded padding (10.0, 12.0) with constants
                padding: const EdgeInsets.symmetric(vertical: kPaddingTen, horizontal: kPaddingSmall + kPaddingExtraSmall),
                decoration: BoxDecoration(
                  // Replaced hardcoded Colors.grey.shade300 with theme
                  border: Border.all(color: colorScheme.outline),
                  // Replaced hardcoded 8.0 with kRadiusSmall
                  borderRadius: BorderRadius.circular(kRadiusSmall),
                  // Replaced hardcoded Colors.white with colorScheme.surface
                  color: colorScheme.surface,
                ),
                child: Row(
                  children: [
                    // Replaced hardcoded color and size with theme/constants
                    Icon(Icons.calendar_today, size: kIconSizeSmall, color: colorScheme.primary),
                    const SizedBox(width: kPaddingSmall), // Replaced hardcoded 8
                    Flexible(
                      child: Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        // Replaced hardcoded style with theme/constants
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: kPaddingTen), // Replaced hardcoded 10
          // Download Button
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon!')),
              );
            },
            // Replaced hardcoded size with constant
            icon: const Icon(Icons.download_rounded, size: kIconSizeSmall),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              // Replaced hardcoded colors with theme
              foregroundColor: colorScheme.onPrimary,
              backgroundColor: colorScheme.primary,
              // Replaced hardcoded padding with constants (10, 10)
              padding: const EdgeInsets.symmetric(horizontal: kPaddingTen, vertical: kPaddingTen),
              // Replaced hardcoded 8 with kRadiusSmall
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Replaced hardcoded Colors.grey.shade50 with theme background
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        // Replaced hardcoded style/color with theme
        title: Text('Detailed Statement', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
        // Replaced hardcoded _primaryNavyBlue with colorScheme.primary
        backgroundColor: colorScheme.primary,
        // Replaced hardcoded Colors.white with colorScheme.onPrimary
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: Column(
        children: [
          // Account Summary Header
          Container(
            // Replaced hardcoded padding with constants
            padding: const EdgeInsets.fromLTRB(kPaddingMedium, kPaddingMedium, kPaddingMedium, kPaddingSmall),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.account.nickname,
                  // Replaced hardcoded Colors.black87 with colorScheme.onSurface
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                Text(
                  'A/C No: ${widget.account.accountNumber}',
                  // Replaced hardcoded Colors.grey.shade600 with theme/opacity
                  style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),

          // Filter and Download Bar
          _buildFilterAndDownloadBar(),

          // Replaced hardcoded Divider
          const Divider(height: 1, color: kDividerColor, indent: kPaddingMedium, endIndent: kPaddingMedium),

          // Transaction List Area
          Expanded(
            child: _isLoading
            // Replaced hardcoded _primaryNavyBlue with colorScheme.primary
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)))
                : _transactions.isEmpty
                ? Center(child: Text('No transactions found in this period.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))))
                : ListView.separated(
              itemCount: _transactions.length,
              // Replaced hardcoded Divider with constant
              separatorBuilder: (context, index) => const Divider(height: 1, color: kDividerColor, indent: kPaddingMedium, endIndent: kPaddingMedium),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isDebit = tx.type == TransactionType.debit;
                // Refactored Color: _accentRed -> colorScheme.error, _accentGreen -> kSuccessGreen
                final amountColor = isDebit ? colorScheme.error : kSuccessGreen;
                // final iconColor = isDebit ? colorScheme.error : kSuccessGreen; // Same as amountColor

                return ListTile(
                  leading: Container(
                    // Replaced hardcoded 40 with kTxnLeadingSize
                    width: kTxnLeadingSize,
                    height: kTxnLeadingSize,
                    decoration: BoxDecoration(
                      color: amountColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      // Replaced hardcoded color and size with theme/constants
                      color: amountColor,
                      size: kIconSizeSmall,
                    ),
                  ),
                  title: Text(
                    tx.description,
                    // Replaced hardcoded style/color with theme
                    style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                    // Replaced hardcoded style/color with theme/opacity
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${isDebit ? '-' : '+'} ₹${tx.amount.toStringAsFixed(2)}',
                        // Replaced hardcoded style/color with theme. titleSmall is close to 15px.
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                      Text(
                        'Bal: ₹${tx.runningBalance.toStringAsFixed(2)}',
                        // Replaced hardcoded style/color with theme/opacity. bodySmall is 12-14px.
                        style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

extension on Transaction {
  get runningBalance => null;
}