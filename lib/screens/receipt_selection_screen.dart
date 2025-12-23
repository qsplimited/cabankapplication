import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../api/mock_fd_api_service.dart';
import '../api/mock_rd_api_service.dart';
import 'deposit_receipt_screen.dart';

class ReceiptSelectionScreen extends StatelessWidget {
  const ReceiptSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Re-using the same mock services
    final fdApiService = MockFdApiService();
    final rdApiService = MockRdApiService();

    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text('View Receipts', style: TextStyle(color: kLightSurface)),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: kLightSurface),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: kPaddingSmall),
            child: Text(
              "Select the type of transaction receipt you wish to view or download.",
              style: TextStyle(color: kLightTextSecondary),
            ),
          ),
          const SizedBox(height: kPaddingSmall),

          // 1. NEW DEPOSIT RECEIPT
          _buildSelectionCard(
            context,
            title: 'New Deposit Receipt',
            subtitle: 'Receipt for your initial account opening and funding.',
            icon: Icons.note_add_outlined,
            accentColor: kBrandLightBlue,
            onTap: () => _navigateToReceipt(context, 'NEW', fdApiService, rdApiService),
          ),

          // 2. RENEWAL ADVICE
          _buildSelectionCard(
            context,
            title: 'Renewal Advice',
            subtitle: 'Details of your most recent maturity renewal instruction.',
            icon: Icons.published_with_changes_outlined,
            accentColor: kBrandPurple,
            onTap: () => _navigateToReceipt(context, 'RENEWAL', fdApiService, rdApiService),
          ),

          // 3. PREMATURE CLOSE ADVICE
          _buildSelectionCard(
            context,
            title: 'Premature Close Advice',
            subtitle: 'Final payout details for accounts closed before maturity.',
            icon: Icons.door_back_door_outlined,
            accentColor: kErrorRed,
            onTap: () => _navigateToReceipt(context, 'PREMATURE_CLOSE', fdApiService, rdApiService),
          ),
        ],
      ),
    );
  }

  void _navigateToReceipt(BuildContext context, String actionType, dynamic fdApi, dynamic rdApi) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DepositReceiptScreen(
          transactionId: 'FD-TXN-12345', // In a real app, you'd fetch the latest ID
          depositType: 'FD',
          actionType: actionType, // Passing the specific type to your main screen
          fdApiService: fdApi,
          rdApiService: rdApi,
        ),
      ),
    );
  }

  Widget _buildSelectionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color accentColor,
        required VoidCallback onTap,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(kPaddingMedium),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: accentColor.withOpacity(0.1),
          child: Icon(icon, color: accentColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: kDividerColor),
      ),
    );
  }
}