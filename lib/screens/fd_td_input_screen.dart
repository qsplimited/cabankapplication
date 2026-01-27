import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/fd_api_service.dart';
import '../models/fd_models.dart';
import '../models/nominee_model.dart';
import '../providers/nominee_provider.dart';
import '../providers/fd_opening_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'fd_confirmation_screen.dart';
import 'add_nominee_screen.dart';

class FdTdInputScreen extends ConsumerStatefulWidget {
  final FdApiService apiService;
  const FdTdInputScreen({super.key, required this.apiService});

  @override
  ConsumerState<FdTdInputScreen> createState() => _FdTdInputScreenState();
}

class _FdTdInputScreenState extends ConsumerState<FdTdInputScreen> {
  late Future<SourceAccount> _accountFuture;
  late Future<List<DepositScheme>> _schemesFuture;

  DepositScheme? _selectedScheme;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();
  final TextEditingController _monthsController = TextEditingController();
  final TextEditingController _daysController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _accountFuture = widget.apiService.fetchSourceAccount();
    _schemesFuture = widget.apiService.fetchDepositSchemes();
    Future.microtask(() => ref.read(nomineeProvider.notifier).fetchNominees('Savings'));
  }

  // --- RESTORED PROCEED LOGIC ---
  Future<void> _handleProceed(SourceAccount account, NomineeModel nominee) async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final yy = int.tryParse(_yearsController.text) ?? 0;
    final mm = int.tryParse(_monthsController.text) ?? 0;
    final dd = int.tryParse(_daysController.text) ?? 0;

    if (amount <= 0) return _showMsg("Please enter a valid amount");
    if (yy == 0 && mm == 0 && dd == 0) return _showMsg("Please enter tenure");
    if (mm > 11) return _showMsg("Months must be 0-11");
    if (dd > 30) return _showMsg("Days must be 0-30");

    setState(() => _isLoading = true);

    try {
      final maturity = await widget.apiService.calculateMaturity(
        amount: amount,
        schemeId: _selectedScheme!.id,
        tenureYears: yy,
        tenureMonths: mm,
        tenureDays: dd,
        nomineeName: nominee.fullName,
        sourceAccountId: account.accountNumber,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FdConfirmationScreen(
              apiService: widget.apiService,
              maturityDetails: maturity,
              inputData: FdInputData(
                amount: amount,
                sourceAccount: account,
                selectedScheme: _selectedScheme!,
                selectedNominee: nominee.fullName,
                tenureYears: yy,
                tenureMonths: mm,
                tenureDays: dd,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      _showMsg("Calculation Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showNomineeOptions() {
    final fdNotifier = ref.read(fdOpeningProvider.notifier);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
      ),
      builder: (context) => Consumer(builder: (context, ref, _) {
        final nomineeState = ref.watch(nomineeProvider);

        return Container(
          padding: const EdgeInsets.all(kPaddingLarge),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Nominee Selection",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: kPaddingMedium),
              ListTile(
                leading: const Icon(Icons.person_add_alt_1, color: kAccentOrange),
                title: const Text("Add New Nominee",
                    style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.pop(context); // Close sheet
                  final result = await Navigator.push(
                    this.context,
                    MaterialPageRoute(builder: (_) => const AddNomineeScreen()),
                  );

                  if (result != null && result is NomineeModel) {
                    fdNotifier.selectNominee(result);
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
                      title: Text(list[i].fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(list[i].relationship),
                      onTap: () {
                        fdNotifier.selectNominee(list[i]);
                        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final fdState = ref.watch(fdOpeningProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Fixed Deposit'),
        backgroundColor: kAccentOrange,
      ),
      body: FutureBuilder(
        future: Future.wait([_accountFuture, _schemesFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final account = snapshot.data![0] as SourceAccount;
          final schemes = snapshot.data![1] as List<DepositScheme>;

          return ListView(
            padding: const EdgeInsets.all(kPaddingMedium),
            children: [
              Card(
                elevation: kCardElevation,
                color: kInfoBlue.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Source Account',
                          style: textTheme.bodySmall?.copyWith(color: kInfoBlue)),
                      Text(account.accountNumber,
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Balance: ₹${account.availableBalance.toStringAsFixed(2)}',
                          style: textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('Daily Limit: ₹${account.dailyLimit.toStringAsFixed(2)}',
                    style: textTheme.bodySmall),
              ),
              const SizedBox(height: kPaddingLarge),
              DropdownButtonFormField<DepositScheme>(
                decoration: const InputDecoration(
                    labelText: 'Scheme', border: OutlineInputBorder()),
                value: _selectedScheme,
                items: schemes
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedScheme = val),
              ),
              const SizedBox(height: kPaddingMedium),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: kPaddingLarge),
              Text('Tenure',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTenureBox(_yearsController, 'YY'),
                  _buildTenureBox(_monthsController, 'MM'),
                  _buildTenureBox(_daysController, 'DD'),
                ],
              ),
              const SizedBox(height: kPaddingLarge),
              Text('Nominee Details',
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showNomineeOptions,
                child: Container(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin, color: kAccentOrange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fdState.selectedNominee?.fullName ?? "Select or Add Nominee",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: fdState.selectedNominee == null
                                      ? Colors.grey
                                      : Colors.black),
                            ),
                            if (fdState.selectedNominee != null)
                              Text(
                                  "${fdState.selectedNominee!.relationship} | Share: 100%",
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Row(
                children: [
                  Checkbox(
                      value: fdState.isTermsAccepted,
                      activeColor: kAccentOrange,
                      onChanged: (v) =>
                          ref.read(fdOpeningProvider.notifier).setTerms(v!)),
                  const Text('I accept the terms & conditions'),
                ],
              ),
              const SizedBox(height: kPaddingLarge),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (fdState.isTermsAccepted &&
                      _selectedScheme != null &&
                      fdState.selectedNominee != null &&
                      !_isLoading)
                      ? () => _handleProceed(account, fdState.selectedNominee!)
                      : null,
                  child: Text(_isLoading ? 'CALCULATING...' : 'PROCEED'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTenureBox(TextEditingController controller, String hint) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
              labelText: hint, hintText: hint, border: const OutlineInputBorder()),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2)
          ],
        ),
      ),
    );
  }
}