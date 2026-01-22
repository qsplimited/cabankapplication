import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_transfer_state.dart';
import '../providers/quick_transfer_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../api/banking_service.dart';
import '../api/mock_otp_service.dart';
import 'otp_verification_dialog.dart';

class QuickTransferScreen extends ConsumerStatefulWidget {
  const QuickTransferScreen({super.key});
  @override
  ConsumerState<QuickTransferScreen> createState() => _QuickTransferScreenState();
}

class _QuickTransferScreenState extends ConsumerState<QuickTransferScreen> {
  final _acNoController = TextEditingController();
  final _confirmAcNoController = TextEditingController();
  final _ifscController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickTransferProvider);
    final notifier = ref.read(quickTransferProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Transfer (IMPS)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange, // Matches your original design
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ACCOUNT DROPDOWN (Shows Savings/Current + Balance)
            _buildSourceCard(state, notifier),
            const SizedBox(height: 20),

            // 2. RECIPIENT FIELDS
            const Text('Recipient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            _buildTextField('Recipient Account Number', _acNoController, Icons.account_balance, isNum: true),
            _buildTextField('Confirm A/C Number', _confirmAcNoController, Icons.check_circle_outline, isNum: true),
            _buildTextField('IFSC Code', _ifscController, Icons.code),

            const SizedBox(height: 15),

            // 3. VERIFY BUTTON (Same color as AppBar)
            if (state.verifiedRecipient == null)
              _buildVerifyButton(state, notifier)
            else
              _buildSuccessCard(state.verifiedRecipient!),

            // 4. AMOUNT & REMARKS (Visible only after verification)
            if (state.verifiedRecipient != null) ...[
              const SizedBox(height: 20),
              const Text('Transaction Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildTextField('Amount', _amountController, Icons.currency_rupee, isNum: true),
              _buildTextField('Remarks', _remarksController, Icons.notes),
            ],

            // ERROR MESSAGE
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(state.errorMessage!, style: const TextStyle(color: kErrorRed, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 30),

            // 5. PROCEED BUTTON (Triggers Generic OTP Dialog)
            if (state.verifiedRecipient != null)
              _buildProceedButton(notifier),
          ],
        ),
      ),
    );
  }

  // UI Helper for the Account Dropdown Card
  Widget _buildSourceCard(QuickTransferState state, QuickTransferNotifier notifier) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Transfer From", style: TextStyle(color: kBrandNavy, fontWeight: FontWeight.bold)),
            DropdownButtonFormField<Account>(
              value: state.selectedAccount,
              isExpanded: true,
              items: state.accounts.map((acc) => DropdownMenuItem(
                value: acc,
                child: Text("${acc.accountType.name.toUpperCase()} - ${acc.accountNumber}"),
              )).toList(),
              onChanged: (val) => notifier.selectAccount(val),
              decoration: const InputDecoration(labelText: 'Select Source Account'),
            ),
            const SizedBox(height: 12),
            // Balance Display
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(kRadiusSmall)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Available Balance:"),
                  Text("₹${state.selectedAccount?.balance.toStringAsFixed(2) ?? '0.00'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyButton(QuickTransferState state, QuickTransferNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: state.isVerifyingRecipient ? null : () =>
            notifier.verifyRecipient(_acNoController.text, _confirmAcNoController.text, _ifscController.text),
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentOrange, // MATCHED COLOR
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
        ),
        child: state.isVerifyingRecipient
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("VERIFY RECIPIENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildProceedButton(QuickTransferNotifier notifier) {
    return SizedBox(
      width: double.infinity,
      height: kButtonHeight,
      child: ElevatedButton(
        onPressed: () async {
          final mobile = await notifier.validateTransfer(_amountController.text);
          if (mobile != null && mounted) {
            // TRIGGERS THE GENERIC OTP DIALOG
            showDialog(
              context: context,
              builder: (ctx) => OtpVerificationDialog(
                otpService: MockOtpService(),
                mobileNumber: mobile,
                screenId: "QUICK_TRANSFER",
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccentOrange, // MATCHED COLOR
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
        ),
        child: const Text("PROCEED & REQUEST OTP", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kBrandNavy),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: kAccentOrange)),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(Map<String, String> details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text("Verified: ${details['officialName']}", style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}