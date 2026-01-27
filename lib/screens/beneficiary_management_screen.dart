// File: beneficiary_management_screen.dart

import 'package:flutter/material.dart';
import '../api/banking_service.dart';
import 'add_beneficiary_screen.dart';

class BeneficiaryManagementScreen extends StatefulWidget {
  static const String routeName = '/manageBeneficiaries';

  const BeneficiaryManagementScreen({super.key});

  @override
  State<BeneficiaryManagementScreen> createState() => _BeneficiaryManagementScreenState();
}

class _BeneficiaryManagementScreenState extends State<BeneficiaryManagementScreen> {
  final BankingService _bankingService = BankingService(); //
  List<Beneficiary> _beneficiaries = [];
  bool _isLoading = true;

  final Color _primaryNavyBlue = const Color(0xFF003366);
  final Color _accentGreen = const Color(0xFF4CAF50);

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen for changes from the mock service to refresh UI automatically
    _bankingService.onDataUpdate.listen((_) {
      if (mounted) _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _bankingService.fetchBeneficiaries(); //
      if (mounted) {
        setState(() {
          _beneficiaries = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Handle Navigation to Add/Edit Screen
  void _navigateToAddEdit({Beneficiary? beneficiary}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddBeneficiaryScreen(existingBeneficiary: beneficiary),
      ),
    );
    if (result == true) _loadData();
  }

  // Delete Logic with Confirmation Dialog
  Future<void> _deletePayee(Beneficiary payee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payee', style: TextStyle(color: Colors.red)),
        content: Text('Remove "${payee.nickname}" from your list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bankingService.deleteBeneficiary(payee.beneficiaryId); //
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payee deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payees', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryNavyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: _beneficiaries.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          itemCount: _beneficiaries.length,
          padding: const EdgeInsets.only(bottom: 80),
          itemBuilder: (context, index) {
            final payee = _beneficiaries[index];
            return _buildPayeeCard(payee);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        backgroundColor: _accentGreen,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add New Payee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Payees Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text('Tap "Add New Payee" to get started.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPayeeCard(Beneficiary payee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _primaryNavyBlue.withOpacity(0.1),
          child: Icon(Icons.account_balance, color: _primaryNavyBlue),
        ),
        title: Text(payee.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          'A/c: ${_bankingService.maskAccountNumber(payee.accountNumber)}\n${payee.bankName}', //
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _navigateToAddEdit(beneficiary: payee);
            if (value == 'delete') _deletePayee(payee);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit Nickname')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Payee', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}