import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_account_model.dart';
import '../api/transaction_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'transfer_confirm_screen.dart';
import '../providers/dashboard_provider.dart';

// Provider for the transaction service logic
final transServiceProvider = Provider((ref) => TransactionService());

class FundTransferScreen extends ConsumerStatefulWidget {
  final CustomerAccount account;
  const FundTransferScreen({super.key, required this.account});

  @override
  ConsumerState<FundTransferScreen> createState() => _FundTransferScreenState();
}

class _FundTransferScreenState extends ConsumerState<FundTransferScreen> {
  final _toAccController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _recipientName = "";
  bool _isFetchingName = false;
  String? _accountError;

  @override
  void dispose() {
    _toAccController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onAccountChanged(String value) async {
    setState(() {
      _accountError = null;
      _recipientName = "";
    });

    if (value.length == 12) { // Assuming standard 12-digit account
      setState(() => _isFetchingName = true);
      try {
        final name = await ref.read(transServiceProvider).getRecipientName(value);
        setState(() {
          _recipientName = name;
          _isFetchingName = false;
        });
      } catch (e) {
        setState(() {
          _accountError = "Beneficiary not found";
          _isFetchingName = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground, // Using professional light grey
      appBar: AppBar(
        title: const Text("Intra-Bank Transfer"),
        backgroundColor: kAccentOrange, // Brand Orange
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingLarge), // Standardized padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactSourceCard(),
              const SizedBox(height: kSpacingLarge),

              _buildSectionHeader("PAYEE DETAILS"),
              const SizedBox(height: kSpacingSmall),
              TextFormField(
                controller: _toAccController,
                onChanged: _onAccountChanged,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Beneficiary Account Number",
                  hintText: "Enter 12-digit account number",
                  errorText: _accountError,
                  prefixIcon: const Icon(Icons.account_balance_outlined, color: kBrandNavy),
                  suffixIcon: _isFetchingName
                      ? const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                ),
              ),

              // Enhanced Verified Recognition Badge
              if (_recipientName.isNotEmpty) _buildVerifiedBadge(),

              const SizedBox(height: kSpacingLarge),

              _buildSectionHeader("TRANSACTION AMOUNT"),
              const SizedBox(height: kSpacingSmall),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandNavy),
                decoration: const InputDecoration(
                  labelText: "Transfer Amount",
                  prefixText: "₹ ",
                  prefixStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandNavy),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Please enter an amount";
                  if (double.tryParse(val) == null) return "Invalid amount format";
                  return null;
                },
              ),

              const SizedBox(height: 60),

              // Styled Primary Action Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                ),
                onPressed: (_recipientName.isEmpty || _accountError != null)
                    ? null
                    : () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransferConfirmScreen(
                          fromAccount: widget.account.savingAccountNumber,
                          toAccount: _toAccController.text,
                          recipientName: _recipientName,
                          amount: double.parse(_amountController.text),
                        ),
                      ),
                    );
                  }
                },
                child: const Text("PROCEED TO REVIEW"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: kLightTextSecondary,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildCompactSourceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(kPaddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusMedium),
        border: Border.all(color: kBrandNavy.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: kBrandNavy.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SOURCE ACCOUNT",
              style: TextStyle(color: kLightTextSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            widget.account.savingAccountNumber,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandNavy, letterSpacing: 1.2),
          ),
          const Divider(height: 20),
          FutureBuilder<double>(
            future: ref.read(dashboardApiServiceProvider).fetchCurrentBalance(widget.account.savingAccountNumber),
            builder: (context, snapshot) {
              final balance = snapshot.data ?? 0.0;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Available Balance", style: TextStyle(color: kLightTextSecondary, fontSize: 13)),
                  Text(
                    "₹ ${balance.toStringAsFixed(2)}",
                    style: const TextStyle(color: kBrandNavy, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      margin: const EdgeInsets.only(top: kPaddingSmall),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kSuccessGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(color: kSuccessGreen.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user, color: kSuccessGreen, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              "Verified Payee: $_recipientName",
              style: const TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}