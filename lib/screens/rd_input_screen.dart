// File: lib/screens/rd_input_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // REQUIRED: For implementing debouncing logic

import '../api/rd_api_service.dart';
import '../models/fd_models.dart';
import '../models/rd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'nominee_list_screen.dart'; // REQUIRED IMPORT
import 'rd_confirmation_screen.dart';

// Utility extension for title casing scheme names
extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

class RdInputScreen extends StatefulWidget {
  final RdApiService apiService;

  const RdInputScreen({super.key, required this.apiService});

  @override
  State<RdInputScreen> createState() => _RdInputScreenState();
}

class _RdInputScreenState extends State<RdInputScreen> {
  final _formKey = GlobalKey<FormState>();

  // State Management
  late Future<SourceAccount> _accountFuture;
  late Future<List<DepositScheme>> _schemesFuture;

  // Debouncing Timer
  Timer? _debounce; // Correctly declared as a nullable Timer

  // Input Controllers (No default text)
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tenureYearsController = TextEditingController(text: '1');
  final TextEditingController _tenureMonthsController = TextEditingController(text: '0');

  // Input State
  DepositScheme? _selectedScheme;
  String? _selectedNominee;
  String _selectedFrequencyMode = 'Monthly';
  bool _isTermsAccepted = false;
  bool _isLoading = false;

  // Data State
  SourceAccount? _sourceAccount;
  RdMaturityDetails? _maturityDetails;

  @override
  void initState() {
    super.initState();
    _accountFuture = widget.apiService.fetchSourceAccount();
    _schemesFuture = widget.apiService.fetchDepositSchemes();

    _accountFuture.then((account) {
      if (mounted) {
        setState(() {
          _sourceAccount = account;
          _selectedNominee = account.nomineeNames.isNotEmpty ? account.nomineeNames.first : null;
        });
        _calculateMaturity();
      }
    });

    // Listener for input changes to trigger recalculation
    _amountController.addListener(_onInputChanged);
    _tenureYearsController.addListener(_onInputChanged);
    _tenureMonthsController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    // IMPORTANT: Cancel the debounce timer to prevent errors if the user closes the screen while a timer is running
    _debounce?.cancel();

    _amountController.removeListener(_onInputChanged);
    _tenureYearsController.removeListener(_onInputChanged);
    _tenureMonthsController.removeListener(_onInputChanged);
    _amountController.dispose();
    _tenureYearsController.dispose();
    _tenureMonthsController.dispose();
    super.dispose();
  }

  // --- CORE LOGIC ---

  void _onInputChanged() {
    // 1. Cancel the previous timer if it's active
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // 2. Start a new timer for 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // 3. Only proceed with calculation if validation passes after the pause
      if (_formKey.currentState?.validate() == true) {
        _calculateMaturity();
      } else {
        // Only trigger setState if state needs changing (e.g., clearing maturity)
        if (_maturityDetails != null) {
          setState(() {
            _maturityDetails = null;
          });
        }
      }
    });
  }

  Future<void> _calculateMaturity() async {
    // Prevent starting calculation if one is already in progress
    if (_sourceAccount == null || _selectedScheme == null || _isLoading) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final tenureYears = int.tryParse(_tenureYearsController.text) ?? 0;
    final tenureMonths = int.tryParse(_tenureMonthsController.text) ?? 0;

    if (amount < 100 || (tenureYears * 12 + tenureMonths) < 1) {
      if (mounted) setState(() { _maturityDetails = null; });
      return;
    }

    if (mounted) setState(() { _isLoading = true; });

    try {
      final details = await widget.apiService.calculateMaturity(
        installmentAmount: amount,
        schemeId: _selectedScheme!.id,
        tenureYears: tenureYears,
        tenureMonths: tenureMonths,
        tenureDays: 0,
        nomineeName: _selectedNominee ?? 'Self',
        sourceAccountId: _sourceAccount!.accountNumber,
        frequencyMode: _selectedFrequencyMode,
      );

      if (mounted) setState(() {
        _maturityDetails = details;
      });
    } catch (e) {
      _showErrorSnackbar('Failed to calculate maturity. Please check inputs.');
      if (mounted) setState(() { _maturityDetails = null; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _handleProceed() async {
    if (_formKey.currentState?.validate() != true || !_isTermsAccepted || _isLoading || _maturityDetails == null) {
      _showErrorSnackbar('Please ensure all fields are valid, T&C accepted, and maturity calculated.');
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final tenureYears = int.tryParse(_tenureYearsController.text) ?? 0;
    final tenureMonths = int.tryParse(_tenureMonthsController.text) ?? 0;

    final inputData = RdInputData(
      installmentAmount: amount,
      sourceAccount: _sourceAccount!,
      selectedScheme: _selectedScheme!,
      selectedNominee: _selectedNominee ?? 'Self',
      tenureYears: tenureYears,
      tenureMonths: tenureMonths,
      tenureDays: 0,
      frequencyMode: _selectedFrequencyMode,
    );

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RdConfirmationScreen(
          apiService: widget.apiService,
          inputData: inputData,
          maturityDetails: _maturityDetails!,
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSchemeDropdown(List<DepositScheme> schemes, TextTheme textTheme) {
    return DropdownButtonFormField<DepositScheme>(
      decoration: const InputDecoration(labelText: 'Select Deposit Scheme', prefixIcon: Icon(Icons.star)),
      value: _selectedScheme,
      hint: const Text('Choose a scheme'),
      items: schemes.map((scheme) {
        return DropdownMenuItem(
          value: scheme,
          child: Text(
            '${StringExtension(scheme.name).titleCase()} (${scheme.interestRate.toStringAsFixed(2)}% p.a.)',
            style: textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (scheme) {
        setState(() {
          _selectedScheme = scheme;
          _calculateMaturity();
        });
      },
      validator: (value) => value == null ? 'Please select a scheme.' : null,
    );
  }

  Widget _buildTenureInput(TextTheme textTheme) {
    Widget buildField(String label, TextEditingController controller, int maxLength, bool isYears) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
              right: isYears ? kPaddingSmall : 0.0,
              left: isYears ? 0.0 : kPaddingSmall
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(maxLength)],
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium, horizontal: kPaddingSmall),
              border: const OutlineInputBorder(),
            ),
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            validator: (val) {
              final years = int.tryParse(_tenureYearsController.text) ?? 0;
              final months = int.tryParse(_tenureMonthsController.text) ?? 0;
              final totalMonths = (years * 12) + months;

              if (!isYears && months > 11) return 'Max 11 months.';
              if (totalMonths < 1) return 'Min 1 month tenure.';
              return null;
            },
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tenure (Duration of Deposit)', style: textTheme.titleSmall),
        const SizedBox(height: kPaddingSmall),
        Row(
          children: [
            buildField('Years', _tenureYearsController, 2, true),
            buildField('Months', _tenureMonthsController, 2, false),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencySelection(TextTheme textTheme) {
    final modes = ['Monthly', 'Quarterly', 'Half-Yearly'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Installment Frequency', style: textTheme.titleSmall),
        const SizedBox(height: kPaddingSmall),
        Wrap(
          spacing: kPaddingSmall,
          children: modes.map((mode) {
            final isSelected = _selectedFrequencyMode == mode;
            return ChoiceChip(
              label: Text(mode),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFrequencyMode = mode;
                    _calculateMaturity();
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: textTheme.bodyMedium?.copyWith(
                color: isSelected ? Theme.of(context).colorScheme.primary : textTheme.bodyMedium!.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusLarge),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : kLightDivider,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- ASYNC NOMINEE NAVIGATION HANDLER ---
  Future<void> _handleNomineeNavigation() async {
    // Navigate and wait for a result (assuming NomineeListScreen returns a result
    // or we just need to refresh the data)
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NomineeListScreen(accountType: 'RD',),
      ),
    );

    // If a result is returned or if the screen was just closed,
    // we should refresh the source account data to update the nominee list.
    if (result != null || result == true) {
      // Re-fetch the source account details
      final newAccountFuture = widget.apiService.fetchSourceAccount();

      // Update the widget state with the new future
      setState(() {
        _accountFuture = newAccountFuture;
        _isLoading = true; // Show loading while fetching new account data
      });

      // Once the new data is available, update state
      newAccountFuture.then((newAccount) {
        if (mounted) {
          setState(() {
            _sourceAccount = newAccount;
            // Attempt to keep the existing nominee if still present, otherwise select the first new one
            if (_selectedNominee == null || !newAccount.nomineeNames.contains(_selectedNominee)) {
              _selectedNominee = newAccount.nomineeNames.isNotEmpty ? newAccount.nomineeNames.first : null;
            }
            _isLoading = false;
          });
          _calculateMaturity();
        }
      });
    }
  }

  Widget _buildNominationSection(BuildContext context, SourceAccount account, TextTheme textTheme) {
    // FIX: Updated TextButton onPressed to use the async handler
    final updateNomineeAction = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: kBrandLightBlue,
        padding: const EdgeInsets.symmetric(horizontal: kPaddingSmall, vertical: kPaddingExtraSmall),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: _isLoading ? null : _handleNomineeNavigation,
      child: const Text('Update Nominee List'),
    );

    if (account.nomineeNames.isEmpty) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('ADD NOMINEE'),
          // FIX: Updated OutlinedButton onPressed to use the async handler
          onPressed: _isLoading ? null : _handleNomineeNavigation,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Nominee', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                value: _selectedNominee,
                hint: const Text('Choose a nominee'),
                isExpanded: true,
                items: account.nomineeNames.map((name) {
                  return DropdownMenuItem(
                    value: name,
                    child: Text(name, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (name) {
                  setState(() => _selectedNominee = name);
                  _calculateMaturity(); // Recalculate if nominee changes
                },
              ),
            ),
            const SizedBox(width: kPaddingSmall),
            Flexible(child: updateNomineeAction),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceAccountCard(TextTheme textTheme, SourceAccount account) {
    return Card(
      elevation: kCardElevation,
      color: kInfoBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source Account', style: textTheme.bodySmall?.copyWith(color: kInfoBlue)),
            const SizedBox(height: kPaddingExtraSmall),
            Text(
              account.accountNumber,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: kBrandNavy),
            ),
            const SizedBox(height: kPaddingSmall),
            Text(
              'Available Balance: ₹${account.availableBalance.toStringAsFixed(2)}',
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              'Max Installment Limit: ₹${account.dailyLimit.toStringAsFixed(2)}',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  // --- MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Recurring Deposit (RD)', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: kLightSurface),
      ),
      body: FutureBuilder(
        future: Future.wait([_accountFuture, _schemesFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            // Display loading indicator if data is initially loading OR if _isLoading is true (e.g., refreshing nominee)
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          }

          final SourceAccount account = snapshot.data![0];
          final List<DepositScheme> schemes = snapshot.data![1];

          if (_selectedScheme == null && schemes.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedScheme = schemes.first;
                _calculateMaturity();
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Source Account Card
                  _buildSourceAccountCard(textTheme, account),
                  const SizedBox(height: kPaddingLarge),

                  // 2. Deposit Scheme Dropdown
                  _buildSchemeDropdown(schemes, textTheme),
                  const SizedBox(height: kPaddingLarge),

                  // 3. Installment Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    decoration: const InputDecoration(
                      labelText: 'Monthly Installment Amount (Min ₹100)',
                      hintText: 'Enter Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '0') ?? 0.0;
                      if (amount < 100) return 'Minimum installment is ₹100.';
                      if (amount > account.dailyLimit) return 'Exceeds limit of ₹${account.dailyLimit.toStringAsFixed(0)}';
                      return null;
                    },
                  ),
                  const SizedBox(height: kPaddingLarge),

                  // 4. Tenure Input (Years/Months)
                  _buildTenureInput(textTheme),
                  const SizedBox(height: kPaddingLarge),

                  // 5. Frequency Selection
                  _buildFrequencySelection(textTheme),
                  const SizedBox(height: kPaddingLarge),

                  // 6. Nomination Field & Flow
                  _buildNominationSection(context, account, textTheme),
                  const SizedBox(height: kPaddingMedium),

                  // 7. Loading Indicator (Only for maturity calculation, main loading is handled by FutureBuilder/Scaffold)
                  if (_isLoading && _maturityDetails == null)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: kPaddingLarge),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // 7. Maturity Details Card (Placeholder for the calculation result)
                  if (_maturityDetails != null && !_isLoading)
                    Padding(
                        padding: const EdgeInsets.only(top: kPaddingMedium),
                        child: Card(
                            color: kInputBackgroundColor,
                            elevation: kCardElevation / 2,
                            child: Padding(
                                padding: const EdgeInsets.all(kPaddingMedium),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Estimated Maturity', style: textTheme.titleSmall),
                                      const SizedBox(height: kPaddingExtraSmall),
                                      Text(
                                          '₹${_maturityDetails!.maturityAmount.toStringAsFixed(2)}',
                                          style: textTheme.headlineMedium?.copyWith(color: kBrandNavy)
                                      ),
                                      Text(
                                          'On ${_maturityDetails!.maturityDate}',
                                          style: textTheme.bodyMedium?.copyWith(color: kSuccessGreen)
                                      ),
                                    ]
                                )
                            )
                        )
                    ),


                  const SizedBox(height: kPaddingLarge),

                  // 8. Terms & Conditions Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _isTermsAccepted,
                        onChanged: (bool? newValue) => setState(() => _isTermsAccepted = newValue ?? false),
                        activeColor: colorScheme.primary,
                      ),
                      Flexible(
                        child: InkWell(
                          onTap: () => setState(() => _isTermsAccepted = !_isTermsAccepted),
                          child: Text(
                            'I accept the terms & conditions',
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kPaddingXXL),

                  // 9. Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_isTermsAccepted && !_isLoading && _selectedScheme != null && _sourceAccount != null && _maturityDetails != null)
                              ? _handleProceed : null,
                          child: Text(_isLoading ? 'CALCULATING...' : 'PROCEED'),
                        ),
                      ),
                      const SizedBox(width: kPaddingMedium),
                      Expanded(
                        child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('CANCEL')
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: kPaddingMedium),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}