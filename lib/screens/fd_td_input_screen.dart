// File: lib/screens/fd_td_input_screen.dart (Final Code with All Design Fixes and Nominee Flow)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../api/fd_api_service.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'fd_confirmation_screen.dart'; // Import confirmation screen
import 'nominee_list_screen.dart'; // 🌟 NEW: Import the external nominee list screen

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

class FdTdInputScreen extends StatefulWidget {
  final FdApiService apiService;

  const FdTdInputScreen({super.key, required this.apiService});

  @override
  State<FdTdInputScreen> createState() => _FdTdInputScreenState();
}

class _FdTdInputScreenState extends State<FdTdInputScreen> {
  late Future<SourceAccount> _accountFuture;
  late Future<List<DepositScheme>> _schemesFuture;
  DepositScheme? _selectedScheme;
  String? _selectedNominee;
  bool _isTermsAccepted = false;
  bool _isLoading = false;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tenureYearsController = TextEditingController();
  final TextEditingController _tenureMonthsController = TextEditingController();
  final TextEditingController _tenureDaysController = TextEditingController();

  int _tenureYears = 0;
  int _tenureMonths = 0;
  int _tenureDays = 0;

  @override
  void initState() {
    super.initState();
    _accountFuture = widget.apiService.fetchSourceAccount();
    _schemesFuture = widget.apiService.fetchDepositSchemes();

    _accountFuture.then((account) {
      if (account.nomineeNames.isNotEmpty) {
        setState(() {
          _selectedNominee = account.nomineeNames.first;
        });
      }
    });

    _tenureYearsController.text = '';
    _tenureYears = 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tenureYearsController.dispose();
    _tenureMonthsController.dispose();
    _tenureDaysController.dispose();
    super.dispose();
  }

  TextInputFormatter _numericFormatter() => FilteringTextInputFormatter.digitsOnly;

  Future<void> _handleProceed(SourceAccount account) async {
    if (_selectedScheme == null || _selectedNominee == null) {
      _showErrorSnackbar('Please select a scheme and a nominee.');
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 100 || amount > account.availableBalance) {
      _showErrorSnackbar('Amount must be between ₹100 and your available balance.');
      return;
    }

    if (_tenureYears + _tenureMonths + _tenureDays == 0) {
      _showErrorSnackbar('Deposit tenure must be at least 1 day.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final maturityDetails = await widget.apiService.calculateMaturity(
        amount: amount,
        schemeId: _selectedScheme!.id,
        tenureYears: _tenureYears,
        tenureMonths: _tenureMonths,
        tenureDays: _tenureDays,
        nomineeName: _selectedNominee!,
        sourceAccountId: account.accountNumber,
      );

      final inputData = FdInputData(
        amount: amount,
        sourceAccount: account,
        selectedScheme: _selectedScheme!,
        selectedNominee: _selectedNominee!,
        tenureYears: _tenureYears,
        tenureMonths: _tenureMonths,
        tenureDays: _tenureDays,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FdConfirmationScreen(
            apiService: widget.apiService,
            inputData: inputData,
            maturityDetails: maturityDetails,
          ),
        ),
      );

    } catch (e) {
      _showErrorSnackbar('Failed to calculate maturity. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  Widget _buildSchemeDropdown(List<DepositScheme> schemes, TextTheme textTheme, ColorScheme colorScheme) {
    return DropdownButtonFormField<DepositScheme>(
      decoration: const InputDecoration(labelText: 'Select Deposit Scheme', border: OutlineInputBorder()),
      value: _selectedScheme,
      hint: const Text('Choose a scheme'),
      items: schemes.map((scheme) {
        return DropdownMenuItem(
          value: scheme,
          child: Text(
            '${StringExtension(scheme.name).titleCase()} (${scheme.interestRate.toStringAsFixed(2)}% p.a.)',
            style: textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis, // Ensure long scheme names don't overflow
          ),
        );
      }).toList(),
      onChanged: (scheme) {
        setState(() {
          _selectedScheme = scheme;
        });
      },
    );
  }

  Widget _buildTenureInput(TextEditingController controller, String label, Function(String) onChanged, TextTheme textTheme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: kPaddingExtraSmall),
        child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [_numericFormatter()],
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              hintText: '0',
              contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium, horizontal: kPaddingSmall),
              border: const OutlineInputBorder(),
            ),
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            onChanged: (val) {
              if (label == 'Months' && (int.tryParse(val) ?? 0) > 11) {
                controller.text = '11';
              }
              if (label == 'Days' && (int.tryParse(val) ?? 0) > 30) {
                controller.text = '30';
              }
              onChanged(controller.text);
            }
        ),
      ),
    );
  }

  Widget _buildNominationSection(BuildContext context, SourceAccount account) {
    final textTheme = Theme.of(context).textTheme;

    final updateNomineeAction = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.amber[700],
        padding: const EdgeInsets.symmetric(horizontal: kPaddingSmall, vertical: kPaddingExtraSmall),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () {
        // Navigating to the imported NomineeListScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NomineeListScreen(accountType: '',),
          ),
        );
      },
      child: const Text('Update Nominee List'),
    );

    if (account.nomineeNames.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: kPaddingMedium),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('ADD NOMINEE'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NomineeListScreen(accountType: '',),
                ),
              );
            },
          ),
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
                decoration: const InputDecoration(labelText: 'Select Nominee', border: OutlineInputBorder()),
                value: _selectedNominee,
                hint: const Text('Choose a nominee'),
                isExpanded: true, // 🌟 IMPORTANT: This ensures the dropdown items (long names) fit
                items: account.nomineeNames.map((name) {
                  return DropdownMenuItem(
                    value: name,
                    child: Text(
                      name,
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis, // Ensures long names are truncated with '...'
                    ),
                  );
                }).toList(),
                onChanged: (name) {
                  setState(() {
                    _selectedNominee = name;
                  });
                },
              ),
            ),
            const SizedBox(width: kPaddingSmall),
            // FIX: Wrap TextButton in Flexible to solve the RenderFlex overflow
            Flexible(
              child: updateNomineeAction,
            ),
          ],
        ),
        const SizedBox(height: kPaddingMedium),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('New Fixed Deposit', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: kLightSurface),
      ),
      body: FutureBuilder(
        future: Future.wait([_accountFuture, _schemesFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final SourceAccount account = snapshot.data![0];
          final List<DepositScheme> schemes = snapshot.data![1];

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_selectedScheme == null && schemes.isNotEmpty) {
              setState(() {
                _selectedScheme = schemes.first;
              });
            }
          });

          return ListView(
            padding: const EdgeInsets.all(kPaddingMedium),
            children: [
              // 1. Source Account Balance Card
              Card(
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: kPaddingSmall),
              // Daily Limit as separate text
              Padding(
                padding: const EdgeInsets.only(left: kPaddingSmall),
                child: Text(
                  'Daily Limit: ₹${account.dailyLimit.toStringAsFixed(2)}',
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: kPaddingLarge),

              // 2. Deposit Scheme Dropdown
              _buildSchemeDropdown(schemes, textTheme, colorScheme),
              const SizedBox(height: kPaddingLarge),

              // 3. Deposit Amount Input
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (Min ₹100)',
                  hintText: 'Enter Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                style: textTheme.titleLarge?.copyWith(color: kFixedDepositCardColor),
              ),
              const SizedBox(height: kPaddingLarge),

              // 4. Tenure Input Fields
              Text('Tenure (Duration of Deposit)', style: textTheme.titleSmall),
              const SizedBox(height: kPaddingSmall),
              Row(
                children: [
                  _buildTenureInput(_tenureYearsController, 'Years', (val) {
                    setState(() => _tenureYears = int.tryParse(val) ?? 0);
                  }, textTheme),
                  _buildTenureInput(_tenureMonthsController, 'Months', (val) {
                    setState(() => _tenureMonths = int.tryParse(val) ?? 0);
                  }, textTheme),
                  _buildTenureInput(_tenureDaysController, 'Days', (val) {
                    setState(() => _tenureDays = int.tryParse(val) ?? 0);
                  }, textTheme),
                ],
              ),
              const SizedBox(height: kPaddingLarge),

              // 5. Nomination Field & Flow
              _buildNominationSection(context, account),
              const Divider(height: kDividerHeight),
              const SizedBox(height: kPaddingMedium),

              // 6. Terms & Conditions Checkbox
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
                      onTap: () {
                        setState(() => _isTermsAccepted = !_isTermsAccepted);
                      },
                      child: Text(
                        'I accept the terms & conditions',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kPaddingXXL),

              // 7. Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isTermsAccepted && !_isLoading && _selectedScheme != null && _selectedNominee != null) ? () => _handleProceed(account) : null,
                      child: Text(_isLoading ? 'Calculating...' : 'PROCEED'),
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
          );
        },
      ),
    );
  }
}