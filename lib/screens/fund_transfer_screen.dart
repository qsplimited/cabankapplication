import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_account_model.dart';
import '../api/transaction_service.dart';
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

  String _recipientName = "";
  bool _isFetchingName = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _toAccController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Automatically fetches the recipient name once a valid account length is typed
  void _onAccountChanged(String value) async {
    // Assuming 10 digits is the minimum for your bank's account numbers
    if (value.length >= 10) {
      setState(() {
        _isFetchingName = true;
        _recipientName = "";
      });

      try {
        final name = await ref.read(transServiceProvider).getRecipientName(value);
        setState(() {
          _recipientName = name;
          _isFetchingName = false;
        });
      } catch (e) {
        setState(() {
          _recipientName = "Account not found";
          _isFetchingName = false;
        });
      }
    } else {
      if (_recipientName.isNotEmpty) setState(() => _recipientName = "");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Transfer Funds"),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sender Info Section
              _buildSenderCard(),
              const SizedBox(height: 30),

              // 2. Recipient Input Field
              const Text("Recipient Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _toAccController,
                onChanged: _onAccountChanged,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "To Account Number",
                  prefixIcon: const Icon(Icons.account_balance_outlined),
                  suffixIcon: _isFetchingName
                      ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => (val == null || val.isEmpty) ? "Enter account number" : null,
              ),

              // Recipient Name Feedback
              if (_recipientName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(
                    "Recipient: $_recipientName",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _recipientName.contains("not found") ? Colors.red : Colors.green[700],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // 3. Amount Input Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixText: "₹ ",
                  prefixStyle: const TextStyle(fontSize: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return "Enter amount";
                  if (double.tryParse(val) == null) return "Enter a valid number";
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // 4. Continue Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_recipientName.isEmpty || _recipientName.contains("not found"))
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
                  child: const Text(
                    "CONTINUE",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom UI for the "From Account" display
  Widget _buildSenderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Transfer From", style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(widget.account.savingAccountNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),

          // Use FutureBuilder to fetch the real balance from your API
          FutureBuilder<double>(
            future: ref.read(dashboardApiServiceProvider).fetchCurrentBalance(widget.account.savingAccountNumber),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text("Balance: Loading...", style: TextStyle(fontSize: 13));
              }
              final balance = snapshot.data ?? 0.0;
              return Text(
                "Balance: ₹ ${balance.toStringAsFixed(2)}",
                style: TextStyle(color: Colors.blue[800], fontSize: 13, fontWeight: FontWeight.w500),
              );
            },
          ),
        ],
      ),
    );
  }
}