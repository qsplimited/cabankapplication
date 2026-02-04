import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_colors.dart';
import '../models/customer_account_model.dart';

class DetailedAccountViewScreen extends ConsumerWidget {
  final String customerId;
  const DetailedAccountViewScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(accountDetailProvider(customerId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Account Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        foregroundColor: Colors.white,
      ),
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (account) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildProfileHeader(account),
            const SizedBox(height: 25),

            _sectionHeader("Personal Details"),
            _infoRow(Icons.email, "Email Address", account.email),
            _infoRow(Icons.phone, "Mobile Number", account.mobileNo),
            _infoRow(Icons.badge, "Document (${account.documentType})", account.documentNumber),

            const Divider(height: 40),

            _sectionHeader("Banking Information"),
            _infoRow(Icons.numbers, "Account Number", account.savingAccountNumber),
            _infoRow(Icons.account_tree, "Branch Code", account.branchCode),
            _infoRow(Icons.category, "Account Type", account.accountType),
            _infoRow(Icons.calendar_today, "Created On", account.createdDate),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(CustomerAccount account) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kAccentOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kAccentOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundColor: kAccentOrange,
              child: Text(account.firstName[0], style: const TextStyle(color: Colors.white, fontSize: 24))),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(account.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Customer ID: ${account.customerId}", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kAccentOrange)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}