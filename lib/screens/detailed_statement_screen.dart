import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add 'intl' package to your pubspec.yaml for date formatting
import '../api/banking_service.dart';
import '../main.dart'; // Assuming Account and Transaction models are here

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

  // Color reference from Dashboard
  final Color _primaryNavyBlue = const Color(0xFF003366);
  final Color _accentRed = const Color(0xFFD32F2F);
  final Color _accentGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    // Fetch initial statement for the last 30 days
    _fetchDetailedStatement();
  }

  // --- Data Fetching Logic ---
  Future<void> _fetchDetailedStatement() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // NOTE: This call relies on the API/BankingService being updated
      // to handle date range and account ID.
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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryNavyBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Date Range Picker
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8.0),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: _primaryNavyBlue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                        style: TextStyle(color: _primaryNavyBlue, fontWeight: FontWeight.w600, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Download Button (Placeholder)
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement Statement Download Logic (PDF/CSV)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Download feature coming soon!')),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 20),
            label: const Text('Download'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _primaryNavyBlue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Detailed Statement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryNavyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Account Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.account.nickname,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'A/C No: ${widget.account.accountNumber}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // Filter and Download Bar
          _buildFilterAndDownloadBar(),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Transaction List Area
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: _primaryNavyBlue))
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)))
                : _transactions.isEmpty
                ? const Center(child: Text('No transactions found in this period.'))
                : ListView.separated(
              itemCount: _transactions.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final tx = _transactions[index];
                final isDebit = tx.type == TransactionType.debit;
                final amountColor = isDebit ? _accentRed : _accentGreen;
                final iconColor = isDebit ? _accentRed : _accentGreen;

                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: iconColor,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    tx.description,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    // Assuming Transaction model has a 'date' field
                    DateFormat('dd MMM yyyy, HH:mm').format(tx.date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${isDebit ? '-' : '+'} ₹${tx.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          fontSize: 15,
                        ),
                      ),
                      // Assuming a runningBalance is available in the Transaction model
                      Text(
                        'Bal: ₹${tx.runningBalance.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
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