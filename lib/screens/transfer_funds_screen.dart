import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// 💡 ASSUMPTION: Replace the relative path with the correct one for your project.
import 'package:cabankapplication/api/banking_service.dart';

// Import Theme constants
import 'package:cabankapplication/theme/app_dimensions.dart';
import 'package:cabankapplication/theme/app_colors.dart'; // Used for kErrorRed

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

  // REMOVED hardcoded colors and replaced them with:
  // final Color _primaryColor = const Color(0xFF003366);
  // final Color _tileColor = Colors.white;
  // final Color _borderColor = Colors.grey.shade300;


  @override
  void initState() {
    super.initState();
    _fetchAccountData();
  }

  // --- Data Fetching Logic (Unchanged) ---
  Future<void> _fetchAccountData() async {
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Use the theme's colors for the SnackBar
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          // Text color on SnackBar surface (using surface for background here)
          style: TextStyle(color: colorScheme.onSurface),
        ),
        // Use kErrorRed or primary color for status indication
        backgroundColor: isError ? kErrorRed : colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- NAVIGATION LOGIC (Unchanged) ---
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

  // --- WIDGET BUILDER: Single Tile (Refactored) ---
  Widget _buildTransferOptionTile({
    required TransferCategory category,
    required String title,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: _isLoading ? null : () => _navigateToDetailsScreen(category),
      child: Container(
        // Using kPaddingSmall for padding inside the tile
        padding: const EdgeInsets.all(kPaddingSmall),
        decoration: BoxDecoration(
          // Tile color now uses theme's surface color
          color: colorScheme.surface,
          // Tile radius uses kRadiusSmall
          borderRadius: BorderRadius.circular(kRadiusSmall),
          border: Border.all(
            // Border color uses a lower opacity of the background text color for a subtle look
            color: colorScheme.onBackground.withOpacity(0.1),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onBackground.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: kCardElevation, // Reusing elevation constant for depth
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              // Icon size from constants and color from primary
              size: kIconSizeExtraLarge,
              color: colorScheme.primary,
            ),
            // Spacing from constants
            const SizedBox(height: kPaddingSmall),
            Text(
              title,
              textAlign: TextAlign.center,
              // Using theme's titleSmall for tile text
              style: textTheme.titleSmall?.copyWith(
                // Ensure text color is easily readable on the surface
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // --- Menu Options (Unchanged) ---
    final List<Map<String, dynamic>> coreTransferOptions = [
      {
        'category': TransferCategory.ownAccount,
        'title': 'Own Accounts',
        'icon': Icons.account_circle,
      },
      {
        'category': TransferCategory.savedBeneficiary,
        'title': 'Pay Saved Payee',
        'icon': Icons.account_balance,
      },
      {
        'category': TransferCategory.newAccount,
        'title': 'Manage / Add Payee',
        'icon': Icons.person_add_alt_1,
      },
    ];

    return Scaffold(
      // Background color uses theme's background color
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Fund Transfer',
          // AppBar title uses theme's titleLarge style
          style: textTheme.titleLarge?.copyWith(
            // Explicitly setting color to onPrimary (text color on primary/appbar)
            color: colorScheme.onPrimary,
          ),
        ),
        // AppBar color uses theme's primary color
        backgroundColor: colorScheme.primary,
        // Icon color uses theme's onPrimary color
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          // Progress indicator color uses theme's primary color
          color: colorScheme.primary,
        ),
      )
          : SingleChildScrollView(
        // Padding from constants
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 1. Transfer Options Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                // Spacing from constants
                crossAxisSpacing: kPaddingMedium,
                mainAxisSpacing: kPaddingMedium,
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
            // Spacing from constants
            const SizedBox(height: kPaddingLarge),
            // Divider color uses a subtle color
            Divider(thickness: 1, color: colorScheme.onBackground.withOpacity(0.1)),
            Center(child: Padding(
              // Padding from constants
              padding: const EdgeInsets.all(kPaddingSmall),
              child: Text(
                'Other Banking Options (Not Implemented)',
                // Using theme's bodyMedium with secondary text color
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}