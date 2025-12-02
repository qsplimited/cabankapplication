import 'package:flutter/material.dart';
import '../api/cheque_service.dart'; // Import the Mock API
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';
import 'cheque_request_review_screen.dart'; // Import the Review Screen

// Initialize the service
final ChequeService _chequeService = ChequeService();

class RequestChequeBookScreen extends StatefulWidget {
  const RequestChequeBookScreen({super.key});

  @override
  State<RequestChequeBookScreen> createState() => _RequestChequeBookScreenState();
}

class _RequestChequeBookScreenState extends State<RequestChequeBookScreen> {
  final _formKey = GlobalKey<FormState>();

  Account? _selectedAccount;
  int? _selectedLeaves = _chequeService.mockBookLeaves.first; // Default to first option (25)
  int _quantity = 1;
  String? _selectedAddress;
  String? _selectedReason;

  late Future<List<Account>> _accountsFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _chequeService.fetchEligibleAccounts();
  }

  // Dynamic Fee Calculation based on Account History
  double get _currentFee {
    if (_selectedAccount == null || _selectedLeaves == null) return 0.0;
    return _chequeService.getFee(
        accountNo: _selectedAccount!.accountNo,
        leaves: _selectedLeaves!,
        quantity: _quantity
    );
  }

  // Checks if the request is free for UI display
  bool get _isFirstRequestFree {
    if (_selectedAccount == null) return false;
    return _chequeService.isFirstRequest(_selectedAccount!.accountNo);
  }

  void _navigateToReview() {
    if (_formKey.currentState!.validate() && _selectedAccount != null && _selectedLeaves != null && _selectedAddress != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChequeRequestReviewScreen(
            account: _selectedAccount!,
            leaves: _selectedLeaves!,
            quantity: _quantity,
            deliveryAddress: _selectedAddress!,
            reason: _selectedReason,
            totalFee: _currentFee,
          ),
        ),
      );
    }
  }

  // Helper for Cheque Leaves Selection Dropdown
  Widget _buildLeavesSelection(TextTheme textTheme, ColorScheme colorScheme) {
    return DropdownButtonFormField<int>(
      decoration: const InputDecoration(
        labelText: 'Cheque Leaves per Book',
        prefixIcon: Icon(Icons.description_outlined),
      ),
      value: _selectedLeaves,
      items: _chequeService.mockBookLeaves.map((int leaves) {
        return DropdownMenuItem<int>(
          value: leaves,
          child: Text('$leaves leaves'),
        );
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _selectedLeaves = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select the number of leaves' : null,
    );
  }

  // Helper for Delivery Address Dropdown
  Widget _buildAddressDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Delivery Method',
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      value: _selectedAddress,
      items: _chequeService.mockDeliveryAddresses.map((String address) {
        // Use only the label for display (e.g., "Registered Address")
        final displayLabel = address.split(':').first;
        return DropdownMenuItem<String>(
          value: address,
          child: Text(displayLabel),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedAddress = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a delivery method' : null,
    );
  }

  // Helper for Reason Dropdown
  Widget _buildReasonDropdown(ColorScheme colorScheme) {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Reason for Request (Optional)',
        prefixIcon: Icon(Icons.text_fields),
      ),
      value: _selectedReason,
      items: _chequeService.mockReasons.map((String reason) {
        return DropdownMenuItem<String>(
          value: reason,
          child: Text(reason),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedReason = newValue;
        });
      },
      // Note: This is optional, so no validator
    );
  }

  // Helper for Quantity Input (Number Picker style)
  Widget _buildQuantityInput(ColorScheme colorScheme) {
    final bool isSavings = _selectedAccount?.accountType == AccountType.savings;
    final int maxQuantity = isSavings ? 1 : ChequeService.maxCurrentAccountBooks;

    if (_selectedAccount == null) {
      return const Text('Select an account to view cheque book quantity options.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    // --- Display Restriction for Savings (Quantity fixed at 1) ---
    if (isSavings) {
      // Force quantity to 1 and display informative text
      _quantity = 1;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kInfoBlue),
          const SizedBox(width: kPaddingSmall),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Number of Cheque Books: 1', style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Savings accounts are strictly limited to one cheque book per request.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(color: kInfoBlue),
              ),
            ],
          )),
        ],
      );
    }

    // --- Enabled Input for Current (Max 3) ---
    return Row(
      children: [
        const Icon(Icons.add_box_outlined, color: kLightTextSecondary),
        const SizedBox(width: kPaddingSmall),
        Text('Number of Cheque Books:', style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),

        // Decrement Button
        IconButton(
          icon: Icon(Icons.remove_circle_outline, color: _quantity > 1 ? colorScheme.secondary : kLightDivider),
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
        ),

        // Quantity Display
        Text('$_quantity', style: Theme.of(context).textTheme.titleLarge),

        // Increment Button
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: _quantity < maxQuantity ? colorScheme.secondary : kLightDivider),
          onPressed: _quantity < maxQuantity ? () => setState(() => _quantity++) : null,
        ),
      ],
    );
  }


  // Custom widget to display fee details attractively (Updated for requested text size changes)
  Widget _buildFeeSummary(ColorScheme colorScheme, TextTheme textTheme) {
    if (_selectedAccount == null || _selectedLeaves == null) return const SizedBox.shrink();

    final bool isFree = _isFirstRequestFree;
    final double feeBeforeGst = isFree ? 0.0 : _currentFee / 1.18;
    final double gstAmount = isFree ? 0.0 : _currentFee - feeBeforeGst;

    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated Fee Details', style: textTheme.titleMedium),
            const Divider(height: kPaddingMedium),

            // --- START: FEE FREE DISPLAY (Updated for smaller, clearer text) ---
            if (isFree)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: kPaddingSmall),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.card_giftcard, color: kSuccessGreen, size: kIconSizeLarge),
                      const SizedBox(height: kPaddingSmall),
                      Text(
                        // Smaller, informative text as requested
                        'This is your first cheque book request and is complimentary.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleSmall!.copyWith(
                          color: kSuccessGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            // --- END: FEE FREE DISPLAY ---
            else ...[
              // Regular Fee Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Book Charge (${_selectedLeaves} leaves x $_quantity)', style: textTheme.bodyMedium),
                  Text('₹${feeBeforeGst.toStringAsFixed(2)}', style: textTheme.bodyMedium),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('GST (18% Mock)', style: textTheme.bodyMedium),
                  Text('₹${gstAmount.toStringAsFixed(2)}', style: textTheme.bodyMedium),
                ],
              ),
              const Divider(height: kPaddingMedium),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount to be Debited', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  isFree ? '₹0.00' : '₹${_currentFee.toStringAsFixed(2)}',
                  // --- START: PAID AMOUNT DISPLAY (Updated to use a smaller, less aggressive size) ---
                  style: textTheme.titleLarge!.copyWith( // Using titleLarge (~20pt) for prominence
                    fontWeight: FontWeight.w900,
                    color: isFree ? kSuccessGreen : colorScheme.error,
                    letterSpacing: -0.5,
                  ),
                  // --- END: PAID AMOUNT DISPLAY ---
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper for Account Dropdown
  Widget _buildAccountDropdown(List<Account> accounts, ColorScheme colorScheme) {
    return DropdownButtonFormField<Account>(
      decoration: const InputDecoration(
        labelText: 'Debit Account',
        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
      ),
      value: _selectedAccount,
      items: accounts.map((Account acc) {
        return DropdownMenuItem<Account>(
          value: acc,
          child: Text('${acc.accountName} (...${acc.accountNo.substring(acc.accountNo.length - 4)})'),
        );
      }).toList(),
      onChanged: (Account? newValue) {
        setState(() {
          _selectedAccount = newValue;
          // Reset quantity to 1 when account changes, so SA rule is applied correctly
          _quantity = 1;
        });
      },
      validator: (value) => value == null ? 'Please select an account' : null,
    );
  }

  // ====================================================================
  // 2. MAIN BUILD METHOD
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text('Request Cheque Book', style: textTheme.titleLarge!.copyWith(color: colorScheme.onPrimary)),
      ),
      body: FutureBuilder<List<Account>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading accounts: ${snapshot.error.toString()}'));
          }

          final eligibleAccounts = snapshot.data ?? [];

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(kPaddingMedium),
              children: <Widget>[
                Text('Select the details for your new cheque book.', style: textTheme.bodyLarge),
                const SizedBox(height: kPaddingLarge),

                _buildAccountDropdown(eligibleAccounts, colorScheme),
                const SizedBox(height: kPaddingMedium),

                _buildLeavesSelection(textTheme, colorScheme),
                const SizedBox(height: kPaddingMedium),

                _buildQuantityInput(colorScheme),
                const SizedBox(height: kPaddingMedium),

                _buildAddressDropdown(colorScheme),
                const SizedBox(height: kPaddingMedium),

                _buildReasonDropdown(colorScheme),
                const SizedBox(height: kPaddingLarge),

                // Fee Summary Card (Conditional visibility and logic updated)
                if (_selectedAccount != null && _selectedLeaves != null && _selectedAddress != null)
                  _buildFeeSummary(colorScheme, textTheme),

                const SizedBox(height: kPaddingExtraLarge),

                // Submit Button
                ElevatedButton(
                  onPressed: (_selectedAccount != null && _selectedLeaves != null && _selectedAddress != null)
                      ? _navigateToReview
                      : null,
                  child: const Text('Review & Proceed to Payment'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}