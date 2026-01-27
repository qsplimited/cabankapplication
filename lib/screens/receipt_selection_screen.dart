import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/receipt_provider.dart';
import 'deposit_receipt_screen.dart';

class ReceiptSelectionScreen extends ConsumerStatefulWidget {
  const ReceiptSelectionScreen({super.key});

  @override
  ConsumerState<ReceiptSelectionScreen> createState() => _ReceiptSelectionScreenState();
}

class _ReceiptSelectionScreenState extends ConsumerState<ReceiptSelectionScreen> {

  // --- CORE NAVIGATION LOGIC WITH RIVERPOD ---
  Future<void> _handleNavigation(String type) async {
    // Fetches data via the StateNotifierProvider
    await ref.read(receiptProvider.notifier).fetchReceipt(type);

    final state = ref.read(receiptProvider);

    if (state.hasValue && state.value != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DepositReceiptScreen(),
        ),
      );
    } else if (state.hasError && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching receipt: ${state.error}")),
      );
    }



  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);
    final isLoading = receiptState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("Select Receipt Type"),
        backgroundColor: kAccentOrange,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(kPaddingMedium),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: kPaddingMedium),
                child: Text(
                  "Which receipt would you like to view?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),

              _buildSelectionCard(
                context,
                title: "New Deposit Receipt",
                subtitle: "View the official receipt for your recently opened FD/RD.",
                icon: Icons.add_circle_outline_rounded,
                color: kSuccessGreen,
                onTap: () => _handleNavigation('NEW'),
              ),

              _buildSelectionCard(
                context,
                title: "Renewal Advice",
                subtitle: "View details of your renewed deposit and linked history.",
                icon: Icons.history_rounded,
                color: kBrandPurple,
                onTap: () => _handleNavigation('RENEWAL'),
              ),

              _buildSelectionCard(
                context,
                title: "Closure Advice",
                subtitle: "View final settlement, interest earned, and payout tax.",
                icon: Icons.account_balance_wallet_outlined,
                color: kErrorRed,
                onTap: () => _handleNavigation('CLOSE'),
              ),
            ],
          ),

          // Loading Overlay matches your original design
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: kAccentOrange),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(kPaddingSmall),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: kPaddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kBrandNavy),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}