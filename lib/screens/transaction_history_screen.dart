import 'package:cabankapplication/screens/pdf_download_logic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. CORE MODELS
import 'package:cabankapplication/models/data_models.dart';

// 2. CRITICAL FIX: Use an alias 'as service' for the service import.
import '../api/banking_service.dart' as service;

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

// --- Main Widget ---

class TransactionHistoryScreen extends StatefulWidget {
  final service.BankingService bankingService;
  const TransactionHistoryScreen({super.key, required this.bankingService});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  // State Variables
  List<Transaction> _allTransactions = [];
  List<TransactionRowData> _displayData = []; // Data for Detailed View
  Account? _primaryAccount;
  bool _isLoading = true;
  String? _errorMessage;

  // New State for UI Mode
  TransactionViewMode _viewMode = TransactionViewMode.Detailed;

  // --- Color Palette for consistency ---
  final Color _primaryNavyBlue = const Color(0xFF003366);
  final Color _accentRed = const Color(0xFFD32F2F);
  final Color _accentGreen = const Color(0xFF4CAF50);
  final Color _lightBackground = const Color(0xFFF0F0F0);
  final Color _tabSelectedColor = const Color(0xFFE8EAF6); // Light Indigo/Blue for selected tab

  // Filter Date Range (Default: Last 30 days)
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    _fetchData();
  }

  // --- Data Fetching and Filtering Logic ---

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<service.Transaction> allTxsFromService = await widget.bankingService.fetchAllTransactions();
      final service.Account? accountFromService = await widget.bankingService.fetchAccountSummary();

      if (mounted) {
        setState(() {
          // --- EXPLICIT TYPE MAPPING ---
          _allTransactions = allTxsFromService.map((txService) {
            final coreTxType = txService.type == service.TransactionType.credit
                ? TransactionType.credit
                : TransactionType.debit;

            return Transaction(
              description: txService.description,
              amount: txService.amount,
              date: txService.date,
              type: coreTxType,
            );
          }).toList();

          // Convert service.Account to the core Account type
          if (accountFromService != null) {
            _primaryAccount = Account(
              accountNumber: accountFromService.accountNumber,
              balance: accountFromService.balance,
              accountType: 'Checking',
              nickname: 'Primary Account',
            );
          } else {
            _primaryAccount = null;
          }
        });
        _applyFilters(); // Apply filters and calculate balance after fetching
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load transaction data: ${e.toString()}. Please ensure data_models.dart and banking_service.dart are present.';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    if (_primaryAccount == null || _allTransactions.isEmpty) {
      setState(() {
        _displayData = [];
        _isLoading = false;
      });
      return;
    }

    // 1. Filter transactions to be only those within the selected date range
    final filteredTxs = _allTransactions
        .where((t) =>
    t.date.isAfter(_startDate.subtract(const Duration(seconds: 1))) &&
        t.date.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    // 2. Sort chronologically for correct running balance calculation
    filteredTxs.sort((a, b) => a.date.compareTo(b.date));

    // 3. Calculate the running balance
    _displayData = _calculateRunningBalance(filteredTxs);

    setState(() {
      _isLoading = false;
    });
  }

  List<TransactionRowData> _calculateRunningBalance(List<Transaction> transactions) {
    final List<TransactionRowData> data = [];
    if (transactions.isEmpty || _primaryAccount == null) return data;

    // A. Calculate the net effect of all *filtered* transactions
    double netEffect = 0;
    for (var t in transactions) {
      netEffect += (t.type == TransactionType.credit) ? t.amount : -t.amount;
    }

    // B. Determine the balance BEFORE the filtered period began
    double balanceBeforeStatement = _primaryAccount!.balance - netEffect;
    double currentStatementBalance = balanceBeforeStatement;

    // C. Iterate and calculate the running balance for the display data
    for (var t in transactions) {
      final isCredit = t.type == TransactionType.credit;

      if (isCredit) {
        currentStatementBalance += t.amount;
      } else {
        currentStatementBalance -= t.amount;
      }

      data.add(TransactionRowData(
        transaction: t,
        runningBalance: currentStatementBalance,
      ));
    }
    // We keep the list sorted chronologically here for PDF download.
    return data;
  }

  // --- UI Interactivity ---

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryNavyBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _primaryNavyBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
        _applyFilters();
      });
    }
  }

  Future<void> _handlePdfDownload() async {
    if (_primaryAccount == null || _displayData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to download or account data is missing.')),
      );
      return;
    }

    // The transactions in the PDF need to be chronologically sorted (oldest first).
    final transactionsToDownload = _displayData.map((d) => d.transaction).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating PDF statement for ${_primaryAccount!.accountNumber}...'),
      ),
    );

    final success = await generateAndSavePdf(
      transactionsToDownload,
      _primaryAccount!,
      DateFormat('dd-MM-yyyy').format(_startDate),
      DateFormat('dd-MM-yyyy').format(_endDate),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statement downloaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed. On a physical device, please ensure storage permissions are granted and **native project files are configured** (Android/iOS).'),
          backgroundColor: _accentRed,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // --- UI Components ---

  Widget _buildAccountHeader() {
    if (_primaryAccount == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Account History | Download Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Account History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (_viewMode == TransactionViewMode.Detailed)
                TextButton(
                  onPressed: _handlePdfDownload,
                  child: Text(
                    'Download',
                    style: TextStyle(
                      color: _primaryNavyBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Account Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Number: XXXX XXXX ${_primaryAccount!.accountNumber.substring(_primaryAccount!.accountNumber.length - 4)}',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Current Balance',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${_primaryAccount!.balance.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryNavyBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          _buildTabPill(TransactionViewMode.Recent, 'Recent Transactions'),
          const SizedBox(width: 8),
          _buildTabPill(TransactionViewMode.Detailed, 'Detailed Statement'),
        ],
      ),
    );
  }

  Widget _buildTabPill(TransactionViewMode mode, String label) {
    final isSelected = _viewMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _viewMode = mode;
          });
          if (mode == TransactionViewMode.Detailed) {
            _applyFilters();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? _tabSelectedColor : Colors.white,
            border: Border.all(color: isSelected ? _primaryNavyBlue : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryNavyBlue : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  // --- Detailed Statement Specific UI (Controls) ---
  Widget _buildDetailedStatementControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Pickers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Start Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 4),
                    _datePickerButton(date: _startDate, onTap: () => _selectDate(context, true)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // End Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('End Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                    const SizedBox(height: 4),
                    _datePickerButton(date: _endDate, onTap: () => _selectDate(context, false)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Showing Transactions (${_displayData.length})',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _datePickerButton({required DateTime date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.calendar_today, size: 18, color: _primaryNavyBlue),
          ],
        ),
      ),
    );
  }

  // --- Transaction List Rendering (Now uses list item for both views) ---

  Widget _buildTransactionList({required List<TransactionRowData> data, bool isDetailedView = false}) {
    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            isDetailedView
                ? 'No transactions found in this date range.'
                : 'No recent transactions found.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Always display the latest transactions first (reverse list)
    final listToDisplay = data.reversed.toList();


    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: listToDisplay.length,
      itemBuilder: (context, index) {
        final rowData = listToDisplay[index];
        final tx = rowData.transaction;
        final isDebit = tx.type == TransactionType.debit;
        final amountColor = isDebit ? _accentRed : _accentGreen;
        final sign = isDebit ? '-' : '+';
        final amountText = '$sign ₹${tx.amount.toStringAsFixed(2)}';

        // Use the unified card/list item design
        return _buildTransactionCardRow(
          tx: tx,
          isDebit: isDebit,
          amountText: amountText,
          amountColor: amountColor,
          isDetailedView: isDetailedView,
        );
      },
    );
  }

  Widget _buildTransactionCardRow({
    required Transaction tx,
    required bool isDebit,
    required String amountText,
    required Color amountColor,
    required bool isDetailedView,
  }) {
    // --- Design Change: Use solid icon background for a bolder look ---
    final iconBgColor = isDebit ? _accentRed : _accentGreen;
    final iconColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon (Transaction Type Indicator)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor, // Solid color for bolder look
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: iconColor, // White icon
                  size: 20,
                ),
              ),
              // 2. Description and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    Text(
                      // Only show Date/ID for Recent View
                      isDetailedView
                          ? DateFormat('dd MMM yyyy').format(tx.date) // Date only for Detailed
                          : 'Oct 30 | ID: t1250', // Mock data for recent view style
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // 3. Amount and Type (Aligned to the Right)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Amount (Credit/Debit)
                  Text(
                    amountText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: amountColor,
                    ),
                  ),
                  // Type (Debit/Credit Label)
                  Text(
                    isDebit ? 'Debit' : 'Credit',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDebit ? _accentRed : _accentGreen,
                    ),
                  ),
                  // *** RUNNING BALANCE REMOVED HERE AS REQUESTED ***
                ],
              ),
            ],
          ),
          Divider(height: 16, color: Colors.grey.shade200)
        ],
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {

    // Filter the raw data for the "Recent" view (Last 10, latest first)
    final List<TransactionRowData> recentTransactions;
    if (_primaryAccount != null) {
      final List<Transaction> allTxs = _allTransactions;
      allTxs.sort((a, b) => a.date.compareTo(b.date));
      final allData = _calculateRunningBalance(allTxs);
      // Take the last 10 (most recent) for the "Recent" tab
      recentTransactions = allData.length > 10
          ? allData.sublist(allData.length - 10).toList()
          : allData;
    } else {
      recentTransactions = [];
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryNavyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryNavyBlue))
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: _accentRed, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 1. Account Info Card & Download Button
          _buildAccountHeader(),

          // 2. Recent/Detailed Tabs
          _buildTabView(),

          const Divider(height: 1, color: Colors.grey),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_viewMode == TransactionViewMode.Recent) ...[
                    // Recent Transactions View
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 10.0, bottom: 5.0),
                      child: Text(
                        'Last ${recentTransactions.length} Transactions',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    _buildTransactionList(data: recentTransactions, isDetailedView: false),
                  ] else ...[
                    // Detailed Statement View
                    // 3. Date Filters (Start Date and End Date added with labels)
                    _buildDetailedStatementControls(),

                    // 4. Transactions List/Card View
                    _buildTransactionList(data: _displayData, isDetailedView: true),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
