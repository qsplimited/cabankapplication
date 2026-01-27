import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../api/rd_api_service.dart';
import '../models/fd_models.dart';
import '../models/rd_models.dart';
import '../models/nominee_model.dart';
import '../providers/nominee_provider.dart';
import '../providers/rd_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'rd_confirmation_screen.dart'; // REQUIRED IMPORT
import 'add_nominee_screen.dart';

extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
}

class RdInputScreen extends ConsumerStatefulWidget {
  final RdApiService apiService;
  const RdInputScreen({super.key, required this.apiService});

  @override
  ConsumerState<RdInputScreen> createState() => _RdInputScreenState();
}

class _RdInputScreenState extends ConsumerState<RdInputScreen> {
  late Future<SourceAccount> _accountFuture;
  late Future<List<DepositScheme>> _schemesFuture;

  DepositScheme? _selectedScheme;
  SourceAccount? _sourceAccount; // To store the fetched account
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController(text: '1');
  final TextEditingController _monthsController = TextEditingController(text: '0');

  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _accountFuture = widget.apiService.fetchSourceAccount();
    _schemesFuture = widget.apiService.fetchDepositSchemes();
    Future.microtask(() => ref.read(nomineeProvider.notifier).fetchNominees('Savings'));
  }

  void _onInputChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _calculateMaturity);
  }

  Future<void> _calculateMaturity() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final years = int.tryParse(_yearsController.text) ?? 0;
    final months = int.tryParse(_monthsController.text) ?? 0;

    if (amount < 100 || _selectedScheme == null || (years == 0 && months == 0)) return;

    setState(() => _isLoading = true);
    try {
      final account = await _accountFuture;
      _sourceAccount = account;
      final rdState = ref.read(rdOpeningProvider);

      final details = await widget.apiService.calculateMaturity(
        installmentAmount: amount,
        schemeId: _selectedScheme!.id,
        tenureYears: years,
        tenureMonths: months,
        tenureDays: 0,
        nomineeName: rdState.selectedNominee?.fullName ?? 'Self',
        sourceAccountId: account.accountNumber,
        frequencyMode: 'Monthly',
      );
      ref.read(rdOpeningProvider.notifier).setMaturity(details);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleProceed() {
    final rdState = ref.read(rdOpeningProvider);

    // Safety checks
    if (_sourceAccount == null || _selectedScheme == null || rdState.maturityDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please complete all fields")));
      return;
    }

    final inputData = RdInputData(
      installmentAmount: double.parse(_amountController.text),
      sourceAccount: _sourceAccount!,
      selectedScheme: _selectedScheme!,
      selectedNominee: rdState.selectedNominee?.fullName ?? 'Self',
      tenureYears: int.parse(_yearsController.text),
      tenureMonths: int.parse(_monthsController.text),
      tenureDays: 0,
      frequencyMode: 'Monthly',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RdConfirmationScreen(
          apiService: widget.apiService,
          inputData: inputData,
          maturityDetails: rdState.maturityDetails!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rdState = ref.watch(rdOpeningProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open RD Account', style: TextStyle(color: Colors.white)),
        backgroundColor: kAccentOrange, // YOUR REQUESTED COLOR
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder(
        future: Future.wait([_accountFuture, _schemesFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final account = snapshot.data![0] as SourceAccount;
          final schemes = snapshot.data![1] as List<DepositScheme>;
          _sourceAccount = account;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Savings Account Details Card
                Card(
                  elevation: 2,
                  color: kAccentOrange.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(kPaddingMedium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('From Account', style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(account.accountNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandNavy)),
                        Text('Balance: ₹${account.availableBalance.toStringAsFixed(2)}', style: const TextStyle(color: kBrandNavy)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: kPaddingLarge),

                _buildLabel('Monthly Installment Amount'),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _onInputChanged(),
                  decoration: const InputDecoration(prefixText: '₹ ', border: OutlineInputBorder()),
                ),
                const SizedBox(height: kPaddingLarge),

                _buildLabel('Tenure (Years & Months)'),
                Row(
                  children: [
                    Expanded(child: _buildTenureField(_yearsController, 'Years')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTenureField(_monthsController, 'Months')),
                  ],
                ),
                const SizedBox(height: kPaddingLarge),

                _buildLabel('RD Scheme'),
                DropdownButtonFormField<DepositScheme>(
                  value: _selectedScheme,
                  items: schemes.map((s) => DropdownMenuItem(value: s, child: Text(s.name.titleCase()))).toList(),
                  onChanged: (val) {
                    setState(() => _selectedScheme = val);
                    _onInputChanged();
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
                const SizedBox(height: kPaddingLarge),

                if (rdState.maturityDetails != null) _buildSummaryCard(rdState.maturityDetails!),

                const SizedBox(height: kPaddingLarge),

                _buildLabel('Nominee'),
                InkWell(
                  onTap: _showNomineeOptions,
                  child: Container(
                    padding: const EdgeInsets.all(kPaddingMedium),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: kAccentOrange),
                        const SizedBox(width: 12),
                        Expanded(child: Text(rdState.selectedNominee?.fullName ?? "Select Nominee", style: const TextStyle(fontWeight: FontWeight.bold))),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: kPaddingXXL),

                Row(
                  children: [
                    Checkbox(
                      value: rdState.isTermsAccepted,
                      activeColor: kAccentOrange,
                      onChanged: (v) => ref.read(rdOpeningProvider.notifier).setTerms(v!),
                    ),
                    const Text('I accept the terms & conditions'),
                  ],
                ),
                const SizedBox(height: kPaddingMedium),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange), // PROCEED BUTTON COLOR
                        onPressed: (rdState.isTermsAccepted && rdState.selectedNominee != null && !_isLoading) ? _handleProceed : null,
                        child: Text(_isLoading ? 'CALCULATING...' : 'PROCEED', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: kPaddingMedium),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // REUSING YOUR NOMINEE SHEET LOGIC
  void _showNomineeOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLarge))),
      builder: (context) => Consumer(builder: (context, ref, _) {
        final nomineeState = ref.watch(nomineeProvider);
        return Container(
          padding: const EdgeInsets.all(kPaddingLarge),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select Nominee", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kBrandNavy)),
              const SizedBox(height: kPaddingMedium),
              ListTile(
                leading: const Icon(Icons.person_add, color: kAccentOrange),
                title: const Text("Add New Nominee", style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddNomineeScreen()));
                  if (result != null && result is NomineeModel) {
                    ref.read(rdOpeningProvider.notifier).selectNominee(result);
                    _calculateMaturity();
                  }
                },
              ),
              const Divider(),
              Expanded(
                child: nomineeState.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text("Error: $err")),
                  data: (list) => ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(list[i].fullName),
                      onTap: () {
                        ref.read(rdOpeningProvider.notifier).selectNominee(list[i]);
                        Navigator.pop(context);
                        _calculateMaturity();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildTenureField(TextEditingController controller, String label) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    onChanged: (_) => _onInputChanged(),
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  );

  Widget _buildSummaryCard(RdMaturityDetails details) => Container(
    padding: const EdgeInsets.all(kPaddingMedium),
    decoration: BoxDecoration(color: kBrandNavy.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
    child: Column(
      children: [
        _buildRow('Monthly Debit:', '₹${_amountController.text}'),
        _buildRow('Total Investment:', '₹${details.totalPrincipalAmount.toStringAsFixed(0)}'),
        const Divider(),
        _buildRow('Maturity Amount:', '₹${details.maturityAmount.toStringAsFixed(2)}', isBold: true),
      ],
    ),
  );

  Widget _buildRow(String label, String value, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Expanded(child: Text(value, textAlign: TextAlign.right, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 18 : 14, color: isBold ? kBrandNavy : Colors.black))),
      ],
    ),
  );

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)));
}