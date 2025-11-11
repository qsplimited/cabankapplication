// File: transfer_funds_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 💡 ASSUMPTION: Replace the relative path with the correct one for your project.
// We are importing all necessary models and service definitions from the single API file.
import 'package:cabankapplication/api/banking_service.dart';

// Namespaced imports for other screens to prevent class name conflicts
// (especially if those screens also internally define Account/BankingService, which is bad practice)
// This structure is correct if your screens are in separate files.
import 'package:cabankapplication/screens/saved_beneficiary_transfer_screen.dart' as saved_screen show SavedBeneficiaryTransferScreen;
import 'package:cabankapplication/screens/own_account_transfer_screen.dart' as own_screen show OwnAccountTransferScreen;
import 'package:cabankapplication/screens/new_account_transfer_screen.dart' as new_screen show NewAccountTransferScreen;


// --- ENUM FOR TRANSFER CATEGORY ---
// (Defined globally in banking_service.dart or accessible here)
enum TransferCategory {
  ownAccount,       // Maps to 'Own Accounts'
  savedBeneficiary, // Maps to 'Within Bank' (for simplicity)
  newAccount,       // Maps to 'Other Bank' (for simplicity)
}


class TransferFundsScreen extends StatefulWidget {
  // Use the actual BankingService type defined in banking_service.dart
  final BankingService bankingService;

  const TransferFundsScreen({Key? key, required this.bankingService}) : super(key: key);

  @override
  State<TransferFundsScreen> createState() => _TransferFundsScreenState();
}

class _TransferFundsScreenState extends State<TransferFundsScreen> {
  // Use the actual Account type defined in banking_service.dart
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

  // --- Data Fetching Logic (Now correctly calling the new API method) ---
  Future<void> _fetchAccountData() async {
    try {
      // The BankingService now has fetchUserAccounts(), resolving the previous compile error.
      final accounts = await widget.bankingService.fetchUserAccounts();
      final primaryAccount = accounts.first;

      setState(() {
        _userAccounts = accounts;
        _selectedSourceAccount = primaryAccount;
        _isLoading = false;
      });
    } catch (e) {
      // Use kDebugMode from flutter/foundation.dart to ensure this only prints in debug builds
      if (kDebugMode) {
        print('Error fetching accounts: $e');
      }
      _showSnackBar('Failed to load accounts. See debug console.', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // ... (Snackbar implementation unchanged)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- NAVIGATION LOGIC ---
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
      // This is the screen we were testing, correctly called here:
        targetScreen = saved_screen.SavedBeneficiaryTransferScreen(
          bankingService: widget.bankingService,
          sourceAccount: _selectedSourceAccount!,
        );
        break;

      case TransferCategory.newAccount:
        targetScreen = new_screen.NewAccountTransferScreen(
          bankingService: widget.bankingService,
          sourceAccount: _selectedSourceAccount!,
        );
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen));
  }

  // --- WIDGET BUILDER: Single Tile ---
  Widget _buildTransferOptionTile({
    required TransferCategory category,
    required String title,
    required IconData icon,
  }) {
    // ... (Tile building logic unchanged)
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
    // ... (Build method implementation unchanged)
    final List<Map<String, dynamic>> coreTransferOptions = [
      {
        'category': TransferCategory.ownAccount,
        'title': 'Own Accounts',
        'icon': Icons.account_circle,
      },
      {
        'category': TransferCategory.savedBeneficiary,
        'title': 'Within Bank',
        'icon': Icons.account_balance,
      },
      {
        'category': TransferCategory.newAccount,
        'title': 'Other Bank',
        'icon': Icons.currency_rupee,
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