// File: saved_beneficiary_transfer_screen.dart (UPDATED with Source Account Dropdown)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 💡 IMPORTANT: Import all models and the service from the canonical API file.
import 'package:cabankapplication/api/banking_service.dart';
import 'package:cabankapplication/screens/transfer_amount_entry_screen.dart';
// Import the actual Payee Management screen
import 'package:cabankapplication/screens/beneficiary_management_screen.dart';

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

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFF003366); // Using Primary Color for consistency

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
  Widget _buildAccountDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Source Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryColor, width: 1.5),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Account>(
                value: _selectedSource,
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: _primaryColor),
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14),
                hint: const Text('No debit accounts available', style: TextStyle(color: Colors.red)),
                onChanged: (Account? newValue) {
                  setState(() {
                    _selectedSource = newValue;
                  });
                },
                items: _sourceAccounts.map((Account item) {
                  return DropdownMenuItem<Account>(
                    value: item,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
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


  // Helper to build the list item (initiates transfer, passes selected source)
  Widget _buildBeneficiaryItem(Beneficiary payee) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: _primaryColor,
          child: Text(payee.nickname[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(payee.nickname, style: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor)),
        subtitle: Text(
          'A/c: ${widget.bankingService.maskAccountNumber(payee.accountNumber)} | IFSC: ${payee.ifsCode}',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: Icon(Icons.send_outlined, color: _accentColor),
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
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer to Saved Payee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: Source Account Selection Dropdown
            _buildAccountDropdown(),

            // Display error message if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
              ),

            const SizedBox(height: 16),

            // Heading for Beneficiary List
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 10),
              child: Text(
                'Select a Payee (${_beneficiaries.length} found)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor),
              ),
            ),
            const SizedBox(height: 16),

            // List of Beneficiaries
            Expanded(
              child: _beneficiaries.isEmpty || _selectedSource == null
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_disabled_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    if (_selectedSource == null)
                      const Text('No source account available for transfer.', style: TextStyle(fontSize: 16, color: Colors.grey))
                    else
                      const Text('No Payees. Tap "Manage / Add Payee" below.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _beneficiaries.length,
                itemBuilder: (context, index) {
                  return _buildBeneficiaryItem(_beneficiaries[index]);
                },
                padding: const EdgeInsets.only(bottom: 80), // Space for FAB
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
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}