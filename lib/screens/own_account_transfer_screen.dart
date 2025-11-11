import 'dart:async';
import 'package:flutter/material.dart';






// Placeholder for models (Replace with actual import of banking_models.dart)
enum TransferType { imps, neft, rtgs, internal }
enum AccountType { savings, current, fixedDeposit, recurringDeposit }
class Account {
  final String accountNumber;
  final AccountType accountType;
  final double balance;
  final String nickname;

  Account({required this.accountNumber, required this.accountType, required this.balance, required this.nickname});
  String get typeDisplay => accountType.toString().split('.').last.toUpperCase();
  String get maskedAccount => '****${accountNumber.substring(accountNumber.length - 4)}';
  Account copyWith({required double newBalance}) {
    return Account(accountNumber: accountNumber, accountType: accountType, balance: newBalance, nickname: nickname);
  }
}

// Placeholder for service (Replace with actual import of banking_service.dart)
class BankingService {
  static final BankingService _instance = BankingService._internal();
  factory BankingService() { return _instance; }
  BankingService._internal();

  // Mock data for initial loading of the screen
  final List<Account> _mockUserAccounts = [
    Account(accountNumber: '123456789012', accountType: AccountType.savings, balance: 55678.50, nickname: 'My Primary Savings'),
    Account(accountNumber: '987654321098', accountType: AccountType.current, balance: 152000.00, nickname: 'Business Current'),
  ];

  // Minimal stream setup to handle real-time updates when an account is changed
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onDataUpdate => _updateController.stream;

  Future<List<Account>> fetchUserAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockUserAccounts);
  }

  // Simplified signature matching the API contract
  Future<String> submitFundTransfer({
    required String recipientAccount,
    required String recipientName,
    required TransferType transferType,
    required double amount,
    String? narration,
    required String transactionPin,
    required String sourceAccountNumber,
    String? ifsCode,
  }) async {
    // This logic should be in the BankingService file, but is required here for the mock to function.
    await Future.delayed(const Duration(milliseconds: 1000));
    if (transactionPin != '123456') {
      throw 'Invalid Transaction PIN (T-PIN).';
    }

    // Simplified Balance Update (This logic confirms the integration is correct)
    final sourceIndex = _mockUserAccounts.indexWhere((acc) => acc.accountNumber == sourceAccountNumber);
    final sourceAccount = _mockUserAccounts[sourceIndex];
    final destinationIndex = _mockUserAccounts.indexWhere((acc) => acc.accountNumber == recipientAccount);
    final destinationAccount = _mockUserAccounts[destinationIndex];

    _mockUserAccounts[sourceIndex] = sourceAccount.copyWith(newBalance: sourceAccount.balance - amount);
    _mockUserAccounts[destinationIndex] = destinationAccount.copyWith(newBalance: destinationAccount.balance + amount);

    _updateController.sink.add(null);
    return 'Success! Internal Transfer of ₹${amount.toStringAsFixed(2)} completed.';
  }
}
// --------------------------------------------------------------------------


class OwnAccountTransferScreen extends StatefulWidget {
  const OwnAccountTransferScreen({super.key, required bankingService, required sourceAccount, required List userAccounts});

  @override
  State<OwnAccountTransferScreen> createState() => _OwnAccountTransferScreenState();
}

class _OwnAccountTransferScreenState extends State<OwnAccountTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final BankingService _service = BankingService();
  late StreamSubscription _dataSubscription;

  List<Account> _userAccounts = [];
  Account? _sourceAccount;
  Account? _destinationAccount;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _tpinController = TextEditingController();

  bool _isLoading = true;
  String? _statusMessage;
  bool _isTransferring = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    // Listen for balance updates from the service stream
    _dataSubscription = _service.onDataUpdate.listen((_) {
      _fetchAccounts();
    });
  }

  @override
  void dispose() {
    _dataSubscription.cancel();
    _amountController.dispose();
    _narrationController.dispose();
    _tpinController.dispose();
    super.dispose();
  }

  // Fetches accounts and ensures selected accounts are updated with new balances
  Future<void> _fetchAccounts() async {
    try {
      final accounts = await _service.fetchUserAccounts();
      if (mounted) {
   /*     setState(() {
          _userAccounts = accounts;
          // Re-find selected accounts to get updated balances
          _sourceAccount = accounts.firstWhere(
                (acc) => acc.accountNumber == (_sourceAccount?.accountNumber),
            orElse: () => accounts.isNotEmpty ? accounts.first : null,
          );
          _destinationAccount = accounts.firstWhere(
                (acc) => acc.accountNumber == (_destinationAccount?.accountNumber),
            orElse: () => accounts.length > 1 ? accounts[1] : null,
          );
          _isLoading = false;
        });*/
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Error loading accounts: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitTransfer() async {
    // Pre-checks
    if (!_formKey.currentState!.validate()) {
      setState(() { _isSuccess = false; _statusMessage = 'Please correct the highlighted errors.'; });
      return;
    }

    if (_sourceAccount == null || _destinationAccount == null) {
      setState(() { _isSuccess = false; _statusMessage = 'Please select both source and destination accounts.'; });
      return;
    }

    if (_sourceAccount!.accountNumber == _destinationAccount!.accountNumber) {
      setState(() { _isSuccess = false; _statusMessage = 'Source and Destination accounts cannot be the same.'; });
      return;
    }

    // Set Loading State
    setState(() {
      _isTransferring = true;
      _statusMessage = 'Transferring funds...';
      _isSuccess = false;
    });

    try {
      final amount = double.parse(_amountController.text);
      final tpin = _tpinController.text;

      // Call Service with TransferType.internal
      final result = await _service.submitFundTransfer(
        recipientAccount: _destinationAccount!.accountNumber,
        recipientName: _destinationAccount!.nickname,
        transferType: TransferType.internal,
        amount: amount,
        narration: _narrationController.text,
        transactionPin: tpin,
        sourceAccountNumber: _sourceAccount!.accountNumber,
      );

      // Handle Success
      if (mounted) {
        setState(() {
          _statusMessage = result;
          _isSuccess = true;
          _tpinController.clear();
          _amountController.clear();
        });
      }
    } catch (e) {
      // Handle Failure
      if (mounted) {
        setState(() {
          _statusMessage = 'Transaction Failed: ${e.toString().replaceAll('Exception: ', '')}';
          _isSuccess = false;
        });
      }
    } finally {
      // Reset Loading State
      if (mounted) {
        setState(() {
          _isTransferring = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Own Account Transfer'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildStatusMessage(),

              // Source Account Selector
              _buildAccountDropdown(
                label: 'Source Account (Debit)',
                currentValue: _sourceAccount,
                onChanged: (Account? newValue) {
                  setState(() { _sourceAccount = newValue; });
                },
                validator: (value) => value == null ? 'Please select a source account' : null,
              ),

              const SizedBox(height: 16.0),

              // Destination Account Selector
              _buildAccountDropdown(
                label: 'Destination Account (Credit)',
                currentValue: _destinationAccount,
                onChanged: (Account? newValue) {
                  setState(() { _destinationAccount = newValue; });
                },
                validator: (value) => value == null ? 'Please select a destination account' : null,
              ),

              if (_sourceAccount != null && _destinationAccount != null && _sourceAccount!.accountNumber == _destinationAccount!.accountNumber)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                  child: Text(
                    '🛑 Source and Destination accounts must be different for a transfer.',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 24.0),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Transfer Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) return 'Enter a valid amount';
                  if (_sourceAccount != null && amount > _sourceAccount!.balance) return 'Insufficient funds (Max: ₹${_sourceAccount!.balance.toStringAsFixed(2)})';
                  return null;
                },
              ),

              const SizedBox(height: 16.0),

              // Narration Field
              TextFormField(
                controller: _narrationController,
                maxLength: 50,
                decoration: const InputDecoration(
                  labelText: 'Narration (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
              ),

              const SizedBox(height: 8.0),

              // T-PIN Field
              TextFormField(
                controller: _tpinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '6-Digit Transaction PIN (T-PIN)',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length != 6) {
                    return 'T-PIN must be 6 digits';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32.0),

              // Transfer Button
              ElevatedButton.icon(
                onPressed: _isTransferring || (_sourceAccount != null && _destinationAccount != null && _sourceAccount!.accountNumber == _destinationAccount!.accountNumber)
                    ? null
                    : _submitTransfer,
                icon: _isTransferring ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ) : const Icon(Icons.send),
                label: Text(_isTransferring ? 'Processing...' : 'Complete Internal Transfer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDropdown({
    required String label,
    required Account? currentValue,
    required ValueChanged<Account?> onChanged,
    required FormFieldValidator<Account?> validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Account>(
          value: currentValue,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
          isExpanded: true,
          validator: validator,
          items: _userAccounts.map((Account account) {
            return DropdownMenuItem<Account>(
              value: account,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${account.typeDisplay} | ${account.maskedAccount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Balance: ₹${account.balance.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, color: (account.accountType == AccountType.fixedDeposit || account.accountType == AccountType.recurringDeposit) && label.contains('Source') ? Colors.red.shade700 : Colors.green.shade700),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
        if (currentValue != null && label.contains('Source') && (currentValue.accountType == AccountType.fixedDeposit || currentValue.accountType == AccountType.recurringDeposit))
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '⚠️ Policy: Funds cannot be debited from this account type.',
              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (_statusMessage == null) return const SizedBox.shrink();

    Color bgColor = _isSuccess ? Colors.green.shade100 : Colors.red.shade100;
    Color borderColor = _isSuccess ? Colors.green.shade400 : Colors.red.shade400;
    Color textColor = _isSuccess ? Colors.green.shade700 : Colors.red.shade700;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          _statusMessage!,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}