// File: transfer_funds_screen.dart (MODIFIED)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 💡 ASSUMPTION: Replace the relative path with the correct one for your project.
import 'package:cabankapplication/api/banking_service.dart';

// Import necessary screens for navigation
import 'package:cabankapplication/screens/saved_beneficiary_transfer_screen.dart' as saved_screen show SavedBeneficiaryTransferScreen;
import 'package:cabankapplication/screens/own_account_transfer_screen.dart' as own_screen show OwnAccountTransferScreen;
import 'package:cabankapplication/screens/beneficiary_management_screen.dart' as manage_screen show BeneficiaryManagementScreen;


// --- ENUM FOR TRANSFER CATEGORY (Unchanged) ---
enum TransferCategory {
  ownAccount,
  savedBeneficiary, // Used for 'Pay Saved Payee'
  newAccount,       // Used for 'Manage / Add Payee'
}


class TransferFundsScreen extends StatefulWidget {
  final BankingService bankingService;

  const TransferFundsScreen({Key? key, required this.bankingService}) : super(key: key);

  @override
  State<TransferFundsScreen> createState() => _TransferFundsScreenState();
}

class _TransferFundsScreenState extends State<TransferFundsScreen> {
  List<Account> _userAccounts = [];
  Account? _selectedSourceAccount;
  bool _isLoading = true;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _tileColor = Colors.white;
  final Color _borderColor = Colors.grey.shade300;

  @override
  void initState() {
    super.initState();
    _fetchAccountData();
  }

  // --- Data Fetching Logic (Unchanged) ---
  Future<void> _fetchAccountData() async {
    // ... (logic remains the same) ...
    try {
      final accounts = await widget.bankingService.fetchUserAccounts();
      final primaryAccount = accounts.first;

      setState(() {
        _userAccounts = accounts;
        _selectedSourceAccount = primaryAccount;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching accounts: $e');
      }
      _showSnackBar('Failed to load accounts. See debug console.', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // ... (Snackbar implementation unchanged) ...
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- NAVIGATION LOGIC (Modified to reflect new flow) ---
  void _navigateToDetailsScreen(TransferCategory category) {
    if (_selectedSourceAccount == null) {
      _showSnackBar('Source account data is still loading. Please wait.', isError: true);
      return;
    }

    Widget targetScreen;

    switch (category) {
      case TransferCategory.ownAccount:
        targetScreen = own_screen.OwnAccountTransferScreen(
          bankingService: widget.bankingService,
          sourceAccount: _selectedSourceAccount!,
          userAccounts: _userAccounts,
        );
        break;

      case TransferCategory.savedBeneficiary:
      // Flow 1: Pay Saved Payee -> Navigates to screen listing all payees
        targetScreen = saved_screen.SavedBeneficiaryTransferScreen(
          bankingService: widget.bankingService,
          sourceAccount: _selectedSourceAccount!,
        );
        break;

      case TransferCategory.newAccount:
      // Flow 2: Manage / Add Payee -> Navigates to the central management screen
        targetScreen = const manage_screen.BeneficiaryManagementScreen();
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
  }

  // --- WIDGET BUILDER: Single Tile (Unchanged) ---
  Widget _buildTransferOptionTile({
    required TransferCategory category,
    required String title,
    required IconData icon,
  }) {
    // ... (Tile building logic unchanged) ...
    return InkWell(
      onTap: _isLoading ? null : () => _navigateToDetailsScreen(category),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _tileColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: _primaryColor.withOpacity(0.8)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _primaryColor.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- UPDATED Menu Options ---
    final List<Map<String, dynamic>> coreTransferOptions = [
      {
        'category': TransferCategory.ownAccount,
        'title': 'Own Accounts',
        'icon': Icons.account_circle,
      },
      {
        'category': TransferCategory.savedBeneficiary,
        // Renamed for clarity: handles both internal and external saved payees
        'title': 'Pay Saved Payee',
        'icon': Icons.account_balance,
      },
      {
        'category': TransferCategory.newAccount,
        // Renamed for clarity: leads to the management screen
        'title': 'Manage / Add Payee',
        'icon': Icons.person_add_alt_1,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Transfer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Transfer Options Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.85,
              ),
              itemCount: coreTransferOptions.length,
              itemBuilder: (context, index) {
                final option = coreTransferOptions[index];
                return _buildTransferOptionTile(
                  category: option['category'],
                  title: option['title'],
                  icon: option['icon'],
                );
              },
            ),

            // Optional: Placeholder for the rest of the menu items shown in the image
            const SizedBox(height: 20),
            const Divider(thickness: 1, color: Colors.grey),
            const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Other Banking Options (Not Implemented)', style: TextStyle(color: Colors.grey)),
            )),
          ],
        ),
      ),
    );
  }
}