// File: saved_beneficiary_transfer_screen.dart (UPDATED with Source Account Dropdown)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 💡 IMPORTANT: Import all models and the service from the canonical API file.
import 'package:cabankapplication/api/banking_service.dart';
import 'package:cabankapplication/screens/transfer_amount_entry_screen.dart';
// Import the actual Payee Management screen
import 'package:cabankapplication/screens/beneficiary_management_screen.dart';
// 1. Import Dimensions for Padding/Spacing
import 'package:cabankapplication/theme/app_dimensions.dart';
// 2. Import Colors for specialized use (like error)
import 'package:cabankapplication/theme/app_colors.dart';


class SavedBeneficiaryTransferScreen extends StatefulWidget {
  final BankingService bankingService;
  // NOTE: sourceAccount is REMOVED from the constructor to allow user selection.
  // The screen now fetches all available debit accounts internally.

  const SavedBeneficiaryTransferScreen({
    Key? key,
    required this.bankingService, required Account sourceAccount,
  }) : super(key: key);

  @override
  State<SavedBeneficiaryTransferScreen> createState() => _SavedBeneficiaryTransferScreenState();
}

class _SavedBeneficiaryTransferScreenState extends State<SavedBeneficiaryTransferScreen> {
  // New state variables for source account management
  List<Account> _sourceAccounts = [];
  Account? _selectedSource;

  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;
  String? _errorMessage; // To handle API loading errors

  @override
  void initState() {
    super.initState();
    // Start fetching both accounts and beneficiaries
    _fetchData();

    // Listen for global data updates (in case the Management screen updates data outside of navigation return)
    widget.bankingService.onDataUpdate.listen((_) {
      if (mounted) {
        _fetchData();
      }
    });
  }

  // --- DATA FETCHING & UI LOGIC ---

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Source Accounts
      final debitAccounts = await widget.bankingService.fetchDebitAccounts();

      // 2. Fetch Beneficiaries
      final payees = await widget.bankingService.fetchBeneficiaries();

      setState(() {
        _sourceAccounts = debitAccounts;

        // Auto-select the first account or re-validate the current selection
        if (_selectedSource == null && debitAccounts.isNotEmpty) {
          _selectedSource = debitAccounts.first;
        } else if (_selectedSource != null && !debitAccounts.any((a) => a.accountNumber == _selectedSource!.accountNumber)) {
          // If the previously selected account is no longer available, select the first one.
          _selectedSource = debitAccounts.isNotEmpty ? debitAccounts.first : null;
        }

        _beneficiaries = payees;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching data: $e');
      }
      setState(() {
        _errorMessage = 'Failed to load accounts or payees. Please try again.';
        _isLoading = false;
      });
    }
  }

  // UPDATED: Navigate to the actual Beneficiary Management Screen
  void _navigateToAddBeneficiary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Navigate to the central management hub
        builder: (context) => const BeneficiaryManagementScreen(),
      ),
    ).then((_) {
      // When the user returns, refresh the list.
      _fetchData();
    });
  }

  // --- UI Components ---

  // Helper function to convert Account object to display string
  String _accountToDisplayString(Account account) {
    String typeLabel = account.accountType.name.splitMapJoin(
      RegExp(r'[A-Z]'),
      onMatch: (m) => ' ${m.group(0)}',
      onNonMatch: (n) => n,
    ).trim();
    typeLabel = typeLabel.substring(0, 1).toUpperCase() + typeLabel.substring(1);

    final maskedNumber = widget.bankingService.maskAccountNumber(account.accountNumber);
    final balance = '₹${account.balance.toStringAsFixed(2)}';

    return '${account.nickname} ($typeLabel - $maskedNumber) | Bal: $balance';
  }

  // NEW: Dropdown builder for the Source Account
  Widget _buildAccountDropdown(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingTen, vertical: kPaddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Source Account',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: kSpacingSmall),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: 0),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(kRadiusMedium),
              border: Border.all(color: colorScheme.primary.withOpacity(0.5), width: 1.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Account>(
                value: _selectedSource,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                hint: Text(
                  'No debit accounts available',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
                onChanged: (Account? newValue) {
                  setState(() {
                    _selectedSource = newValue;
                  });
                },
                items: _sourceAccounts.map((Account item) {
                  return DropdownMenuItem<Account>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall),
                      child: Text(_accountToDisplayString(item), overflow: TextOverflow.ellipsis),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // UPDATED: Replaced Card with a styled Container/ListTile
  Widget _buildBeneficiaryItem(BuildContext context, Beneficiary payee) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingExtraSmall, horizontal: kPaddingTen),
      child: Container(
        // Custom styling to mimic Card, using theme constants
        decoration: BoxDecoration(
          color: colorScheme.surface, // Background color
          borderRadius: BorderRadius.circular(kRadiusSmall), // Border radius
          boxShadow: [ // Shadow to mimic elevation
            BoxShadow(
              color: colorScheme.onBackground.withOpacity(0.08), // Subtle shadow color
              spreadRadius: 1,
              blurRadius: kCardElevation, // Using elevation constant for blur
              offset: const Offset(0, 1), // Light lift
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingExtraSmall),
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary, // Themed color
            child: Text(
              payee.nickname[0].toUpperCase(),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary, // Text color on primary
              ),
            ),
          ),
          title: Text(
            payee.nickname,
            style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface), // Themed style
          ),
          subtitle: Text(
            'A/c: ${widget.bankingService.maskAccountNumber(payee.accountNumber)} | IFSC: ${payee.ifsCode}',
            style: textTheme.bodyMedium, // Themed style
          ),
          trailing: Icon(Icons.send_outlined, color: colorScheme.secondary), // Use secondary/accent color
          onTap: () {
            if (_selectedSource == null) return; // Cannot transfer without a source

            // Navigate to the detailed Amount Entry Screen, passing the SELECTED Source Account
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransferAmountEntryScreen(
                  sourceAccount: _selectedSource!, // PASSES THE SELECTED ACCOUNT
                  beneficiary: payee,
                  bankingService: widget.bankingService,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // Letting AppBarTheme handle color and title style
        title: const Text('Transfer to Saved Payee'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : Padding(
        padding: const EdgeInsets.only(top: kPaddingSmall, left: kPaddingSmall, right: kPaddingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: Source Account Selection Dropdown
            _buildAccountDropdown(context),

            // Display error message if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kPaddingTen, vertical: kPaddingSmall),
                child: Text(
                  _errorMessage!,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w500),
                ),
              ),

            const SizedBox(height: kSpacingMedium),

            // Heading for Beneficiary List
            Padding(
              padding: const EdgeInsets.only(left: kPaddingTen, right: kPaddingTen),
              child: Text(
                'Select a Payee (${_beneficiaries.length} found)',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
              ),
            ),
            const SizedBox(height: kSpacingSmall),

            // List of Beneficiaries
            Expanded(
              child: _beneficiaries.isEmpty || _selectedSource == null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_disabled_outlined, size: kIconSizeExtraLarge, color: colorScheme.onBackground.withOpacity(0.4)),
                    const SizedBox(height: kSpacingSmall),
                    if (_selectedSource == null)
                      Text('No source account available for transfer.', style: textTheme.bodyMedium)
                    else
                      Text('No Payees. Tap "Manage / Add Payee" below.', style: textTheme.bodyMedium),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _beneficiaries.length,
                itemBuilder: (context, index) {
                  // Using the new Container builder
                  return _buildBeneficiaryItem(context, _beneficiaries[index]);
                },
                padding: const EdgeInsets.only(bottom: kButtonHeight + kPaddingLarge),
              ),
            ),
          ],
        ),
      ),
      // --- Floating Action Button ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddBeneficiary,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Manage / Add Payee'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}