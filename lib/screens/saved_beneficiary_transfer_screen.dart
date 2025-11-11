// File: saved_beneficiary_transfer_screen.dart (REVISED NAVIGATION)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// 💡 IMPORTANT: Import all models and the service from the canonical API file.
import 'package:cabankapplication/api/banking_service.dart';
import 'package:cabankapplication/screens/transfer_amount_entry_screen.dart';
// Import the actual Payee Management screen
import 'package:cabankapplication/screens/beneficiary_management_screen.dart';


// --- REMOVED: Mock AddBeneficiaryScreen ---
// It is replaced by the actual BeneficiaryManagementScreen

class SavedBeneficiaryTransferScreen extends StatefulWidget {
  final BankingService bankingService;
  final Account sourceAccount;

  const SavedBeneficiaryTransferScreen({
    Key? key,
    required this.bankingService,
    required this.sourceAccount,
  }) : super(key: key);

  @override
  State<SavedBeneficiaryTransferScreen> createState() => _SavedBeneficiaryTransferScreenState();
}

class _SavedBeneficiaryTransferScreenState extends State<SavedBeneficiaryTransferScreen> {
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;

  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    // Setting a unique route name for popUntil after a successful transaction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // NOTE: Using a static route name for popUntil in TransferResultScreen is risky.
      // It's safer to rely on the current route stack. I'll keep the extension
      // but note the better practice.
      // Navigator.of(context).settings = const RouteSettings(name: '/transferFunds');
    });
    _fetchBeneficiaries();

    // Listen for global data updates (in case the Management screen updates data outside of navigation return)
    widget.bankingService.onDataUpdate.listen((_) {
      if (mounted) {
        _fetchBeneficiaries();
      }
    });
  }

  Future<void> _fetchBeneficiaries() async {
    setState(() => _isLoading = true);
    try {
      // Ensure we are using the service passed via the widget
      final payees = await widget.bankingService.fetchBeneficiaries();
      setState(() {
        _beneficiaries = payees;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching beneficiaries: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  // UPDATED: Navigate to the actual Beneficiary Management Screen
  void _navigateToAddBeneficiary() {
    // Navigate to the screen where payees can be added, edited, or deleted.
    Navigator.push(
      context,
      MaterialPageRoute(
        // Assuming BeneficiaryManagementScreen is accessible via this path
        builder: (context) => const BeneficiaryManagementScreen(),
      ),
    ).then((_) {
      // When the user returns from the BeneficiaryManagementScreen,
      // the list is refreshed to show any newly added payees.
      _fetchBeneficiaries();
    });
  }

  // --- UI Components ---

  // Helper to build the account summary card
  Widget _buildSourceAccountCard() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: _primaryColor),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Source: ${widget.sourceAccount.nickname} (Acct: ${widget.bankingService.maskAccountNumber(widget.sourceAccount.accountNumber)})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build the list item
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
          // Navigate to the detailed Amount Entry Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransferAmountEntryScreen(
                sourceAccount: widget.sourceAccount,
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
        title: const Text('Transfer to Saved Beneficiary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            _buildSourceAccountCard(),
            const SizedBox(height: 10),

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
              child: _beneficiaries.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_disabled_outlined, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    const Text('No Payees. Tap "Add Payee" below.', style: TextStyle(fontSize: 16, color: Colors.grey)),
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
        label: const Text('Manage / Add Payee'), // Better label
        backgroundColor: _primaryColor, // Matching primary color for consistency
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// --- Extension and TransferResultScreen (Kept for completeness) ---

extension on NavigatorState {
  // Mock setter for settings to avoid runtime error when setting route name
  set settings(RouteSettings settings) {}
}

// Simple Transfer Result Screen (for use after transaction)
class TransferResultScreen extends StatelessWidget {
  final String message;
  final bool isSuccess;
  const TransferResultScreen({super.key, required this.message, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF003366);
    return Scaffold(
      appBar: AppBar(title: Text(isSuccess ? 'Success' : 'Failed', style: const TextStyle(color: Colors.white)), backgroundColor: primaryColor),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isSuccess ? Icons.check_circle_outline : Icons.error_outline, size: 80, color: isSuccess ? Colors.green : Colors.red),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              // Pop back to the Beneficiary Selection Screen
              // Using route name is unreliable, using popUntil (route) => route.isFirst
              // or using a named route for this screen is safer. Using isFirst for now.
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Done'),
          ),
        ]),
      ),
    );
  }
}