import 'package:cabankapplication/screens/pdf_download_logic.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. CORE MODELS
import 'package:cabankapplication/models/data_models.dart';

// 2. CRITICAL FIX: Use an alias 'as service' for the service import.
import '../api/banking_service.dart' as service;

// THEME IMPORTS
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
// Note: AppSizes and AppDimensions are often used interchangeably in different files.
// Using k-prefixed constants from app_dimensions.dart for spacing.

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

  // --- Theme variables (Removed hardcoded colors) ---

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
    final colorScheme = Theme.of(context).colorScheme;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary, // Used colorScheme.primary
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary, // Used colorScheme.primary
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
          backgroundColor: kSuccessGreen, // Used kSuccessGreen
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF generation failed. On a physical device, please ensure storage permissions are granted and **native project files are configured** (Android/iOS).'),
          backgroundColor: kErrorRed, // Used kErrorRed
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  // --- UI Components ---

  Widget _buildAccountHeader() {
    if (_primaryAccount == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium), // Used kPaddingMedium (16.0)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Account History | Download Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Account History',
                style: theme.textTheme.headlineSmall?.copyWith( // Approx 24pt
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground, // Used onBackground
                ),
              ),
              if (_viewMode == TransactionViewMode.Detailed)
                TextButton(
                  onPressed: _handlePdfDownload,
                  child: Text(
                    'Download',
                    style: theme.textTheme.bodyLarge?.copyWith( // Approx 16pt
                      color: colorScheme.primary, // Used primary color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: kPaddingTen), // Used kPaddingTen (10.0)

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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.6), // Used onBackground with opacity
                      ),
                    ),
                    const SizedBox(height: kPaddingExtraSmall), // Used kPaddingExtraSmall (4.0)
                    Text(
                      'Current Balance',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600), // Used titleMedium (16pt)
                    ),
                  ],
                ),
              ),
              Text(
                '₹${_primaryAccount!.balance.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith( // Used titleLarge (20pt, approx 22pt)
                  fontWeight: FontWeight.w900,
                  color: colorScheme.primary, // Used primary color
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall), // Used kPaddingMedium (16.0), kPaddingSmall (8.0)
      child: Row(
        children: [
          _buildTabPill(TransactionViewMode.Recent, 'Recent Transactions'),
          const SizedBox(width: kPaddingSmall), // Used kPaddingSmall (8.0)
          _buildTabPill(TransactionViewMode.Detailed, 'Detailed Statement'),
        ],
      ),
    );
  }

  Widget _buildTabPill(TransactionViewMode mode, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _viewMode == mode;
    final selectedColor = colorScheme.primary.withOpacity(0.1); // Dynamic selected color

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
          padding: const EdgeInsets.symmetric(vertical: kPaddingTen, horizontal: kPaddingSmall), // Used kPaddingTen (10.0), kPaddingSmall (8.0)
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : colorScheme.surface, // Used dynamic selected/surface color
            border: Border.all(color: isSelected ? colorScheme.primary : theme.dividerColor), // Used primary/divider color
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith( // Used titleSmall (14pt, approx 13pt)
                color: isSelected ? colorScheme.primary : colorScheme.onSurface, // Used primary/onSurface color
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13, // Keeping 13 for precise look
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Pickers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingTen), // Used kPaddingMedium (16.0), kPaddingTen (10.0)
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface), // Used bodyMedium (14pt)
                    ),
                    const SizedBox(height: kPaddingExtraSmall), // Used kPaddingExtraSmall (4.0)
                    _datePickerButton(date: _startDate, onTap: () => _selectDate(context, true)),
                  ],
                ),
              ),
              const SizedBox(width: kPaddingMedium - kPaddingExtraSmall), // Used kPaddingMedium (12.0)
              // End Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Date',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface), // Used bodyMedium (14pt)
                    ),
                    const SizedBox(height: kPaddingExtraSmall), // Used kPaddingExtraSmall (4.0)
                    _datePickerButton(date: _endDate, onTap: () => _selectDate(context, false)),
                  ],
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall), // Used kPaddingMedium (16.0), kPaddingSmall (8.0)
          child: Text(
            'Showing Transactions (${_displayData.length})',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Used titleMedium (16pt)
          ),
        ),
        const SizedBox(height: kPaddingTen), // Used kPaddingTen (10.0)
      ],
    );
  }

  Widget _datePickerButton({required DateTime date, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kRadiusSmall), // Used kRadiusSmall (8.0)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: kPaddingSmall + kPaddingExtraSmall, vertical: kPaddingTen), // Used 12, 10
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor), // Used theme dividerColor
          borderRadius: BorderRadius.circular(kRadiusSmall), // Used kRadiusSmall (8.0)
          color: colorScheme.surface, // Used surface color
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd-MM-yyyy').format(date),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold), // Used bodyMedium (14pt)
            ),
            Icon(Icons.calendar_today, size: 18, color: colorScheme.primary), // Used 18, primary color
          ],
        ),
      ),
    );
  }

  // --- Transaction List Rendering (Now uses list item for both views) ---

  Widget _buildTransactionList({required List<TransactionRowData> data, bool isDetailedView = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingExtraLarge), // Used kPaddingExtraLarge (32.0)
          child: Text(
            isDetailedView
                ? 'No transactions found in this date range.'
                : 'No recent transactions found.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onBackground.withOpacity(0.6), // Used onBackground with opacity
            ),
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
        final amountColor = isDebit ? kErrorRed : kSuccessGreen; // Used kErrorRed/kSuccessGreen
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
    final theme = Theme.of(context);

    // --- Design Change: Use solid icon background for a bolder look ---
    final iconBgColor = isDebit ? kErrorRed : kSuccessGreen; // Used kErrorRed/kSuccessGreen
    const iconColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall), // Used kPaddingMedium (16.0), kPaddingSmall (8.0)
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon (Transaction Type Indicator)
              Container(
                margin: const EdgeInsets.only(right: kPaddingSmall + kPaddingExtraSmall), // Used 12.0
                padding: const EdgeInsets.all(kPaddingSmall), // Used kPaddingSmall (8.0)
                decoration: BoxDecoration(
                  color: iconBgColor, // Solid color for bolder look
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                  color: iconColor, // White icon
                  size: kIconSizeSmall, // Used kIconSizeSmall (20.0)
                ),
              ),
              // 2. Description and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.description,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), // Used titleSmall (14pt)
                    ),
                    Text(
                      // Only show Date/ID for Recent View
                      isDetailedView
                          ? DateFormat('dd MMM yyyy').format(tx.date) // Date only for Detailed
                          : 'Oct 30 | ID: t1250', // Mock data for recent view style
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6), // Used onBackground with opacity
                      ),
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
                    style: theme.textTheme.titleSmall?.copyWith( // Used titleSmall (14pt)
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  // Type (Debit/Credit Label)
                  Text(
                    isDebit ? 'Debit' : 'Credit',
                    style: theme.textTheme.bodySmall?.copyWith( // Used bodySmall (12pt)
                      color: amountColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Divider(height: kPaddingMedium, color: theme.dividerColor) // Used kPaddingMedium (16.0), theme.dividerColor
        ],
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      backgroundColor: colorScheme.background, // Used background color
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: theme.textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold), // Used onPrimary text color
        ),
        backgroundColor: colorScheme.primary, // Used primary color
        iconTheme: IconThemeData(color: colorScheme.onPrimary), // Used onPrimary icon color
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) // Used primary color
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingExtraLarge), // Used kPaddingExtraLarge (32.0)
          child: Text(
            _errorMessage!,
            style: theme.textTheme.bodyLarge?.copyWith(color: kErrorRed), // Used kErrorRed
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

          const Divider(height: 1, color: kDividerColor), // Used kDividerColor

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_viewMode == TransactionViewMode.Recent) ...[
                    // Recent Transactions View
                    Padding(
                      padding: const EdgeInsets.only(left: kPaddingMedium, top: kPaddingTen, bottom: kPaddingExtraSmall + 1.0), // Used 16.0, 10.0, 5.0
                      child: Text(
                        'Last ${recentTransactions.length} Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), // Used titleMedium (16pt)
                      ),
                    ),
                    _buildTransactionList(data: recentTransactions, isDetailedView: false),
                  ] else ...[
                    // Detailed Statement View
                    // 3. Date Filters
                    _buildDetailedStatementControls(),

                    // 4. Transactions List/Card View
                    _buildTransactionList(data: _displayData, isDetailedView: true),
                  ],
                  const SizedBox(height: kPaddingLarge), // Used kPaddingLarge (24.0)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}