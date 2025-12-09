// File: beneficiary_management_screen.dart (Refactored)

import 'package:flutter/material.dart';

// 💡 IMPORTANT: Import centralized design files
import '../api/banking_service.dart';
import '../screens/transfer_amount_entry_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// Access the shared service instance
final BankingService _bankingService = BankingService();

// --- Main Screen Class ---
class BeneficiaryManagementScreen extends StatefulWidget {
  static const String routeName = '/manageBeneficiaries';

  const BeneficiaryManagementScreen({super.key});

  @override
  State<BeneficiaryManagementScreen> createState() => _BeneficiaryManagementScreenState();
}

class _BeneficiaryManagementScreenState extends State<BeneficiaryManagementScreen> {
  List<Beneficiary> _beneficiaries = [];
  Account? _sourceAccount;
  bool _isLoading = true;



  @override
  void initState() {
    super.initState();
    _loadData();
    _bankingService.onDataUpdate.listen((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  // --- Data Loading (Unchanged) ---
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _bankingService.fetchBeneficiaries(),
        _bankingService.fetchPrimaryAccount(),
      ]);

      if (mounted) {
        setState(() {
          _beneficiaries = results[0] as List<Beneficiary>;
          _sourceAccount = results[1] as Account;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // print('Error loading data: $e'); // Removed print for cleaner code
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Show Add/Edit Modal (Payee Form) ---
  Future<void> _manageBeneficiary({Beneficiary? existingBeneficiary}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),

        child: _BeneficiaryForm(existingBeneficiary: existingBeneficiary),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  // --- Fund Transfer Navigation (Unchanged) ---
  void _navigateToFundTransfer(Beneficiary beneficiary) {
    if (_sourceAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot initiate transfer: Primary source account not loaded.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: '/transferFunds'),
        builder: (context) => TransferAmountEntryScreen(
          sourceAccount: _sourceAccount!,
          beneficiary: beneficiary,
          bankingService: _bankingService,
        ),
      ),
    );
  }

  // --- Delete Logic (Refactored Styles) ---
  Future<void> _deleteBeneficiary(Beneficiary payee) async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        // Refactored Title Style
        title: Text('Confirm Deletion', style: textTheme.titleMedium?.copyWith(color: colorScheme.error)),
        content: Text('Are you sure you want to delete payee "${payee.nickname}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            // Refactored TextButton Style
            child: Text('CANCEL', style: textTheme.labelLarge?.copyWith(color: colorScheme.primary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            // Refactored Button Style
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text('DELETE', style: textTheme.labelLarge),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bankingService.deleteBeneficiary(payee.beneficiaryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            // Refactored Snack Bar Color
            SnackBar(content: Text('Payee "${payee.nickname}" deleted successfully.'), backgroundColor: kSuccessGreen),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deletion failed: ${e.toString().split(':').last.trim()}')),
          );
        }
      }
    }
  }

  // --- UI Components: List View (Refactored Styles) ---
  Widget _buildPayeeList() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_beneficiaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Refactored Icon Style
            Icon(Icons.person_add_disabled_outlined, size: 80, color: colorScheme.onBackground.withOpacity(0.3)),
            const SizedBox(height: kPaddingMedium),
            // Refactored Text Styles
            Text('No Payees Added', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: kPaddingExtraSmall),
            Text('Tap "Add New Payee" to begin.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.6))),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _beneficiaries.length,
      padding: const EdgeInsets.only(top: kPaddingSmall, bottom: 80),
      itemBuilder: (context, index) {
        final payee = _beneficiaries[index];
        return Card(
          // Refactored Card Dimensions & Style
          margin: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall),
          elevation: kCardElevation,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
          child: ListTile(
            onTap: () => _navigateToFundTransfer(payee),

            leading: CircleAvatar(
              // Refactored Avatar Colors
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Icon(Icons.account_circle, color: colorScheme.primary),
            ),
            // Refactored Title Style
            title: Text(payee.nickname, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'A/c: ${_bankingService.maskAccountNumber(payee.accountNumber)}\nBank: ${payee.bankName} (IFSC: ${payee.ifsCode})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              // Refactored Subtitle Style
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'edit') {
                  _manageBeneficiary(existingBeneficiary: payee);
                } else if (result == 'delete') {
                  _deleteBeneficiary(payee);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                // Refactored Icons for menu
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, color: colorScheme.onSurface), const SizedBox(width: kPaddingExtraSmall), Text('Edit Nickname/Name')]),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, color: colorScheme.error), const SizedBox(width: kPaddingExtraSmall), Text('Delete Payee', style: TextStyle(color: colorScheme.error))]),
                ),
              ],
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Access Theme 💡
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // App Bar uses global AppBarTheme, but we override primary color for background/icons
      appBar: AppBar(
        title: Text('Manage Payees', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        // Refactored RefreshIndicator Color
        color: colorScheme.primary,
        child: _isLoading
        // Refactored Loading Indicator Color
            ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
            : _buildPayeeList(),
      ),

      // **ACTION:** Floating button to add new payee (Refactored Styles)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _manageBeneficiary(),
        // Refactored FAB Colors and Styles
        backgroundColor: kSuccessGreen,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.person_add),
        label: Text('Add New Payee', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ----------------------------------------------------------------------
// --- Beneficiary Add/Edit Form Component (Refactored Styles) ---
// ----------------------------------------------------------------------

class _BeneficiaryForm extends StatefulWidget {
  final Beneficiary? existingBeneficiary;
  // 💡 Refactored: Removed primaryNavyBlue parameter

  const _BeneficiaryForm({super.key, this.existingBeneficiary});

  @override
  State<_BeneficiaryForm> createState() => _BeneficiaryFormState();
}

class _BeneficiaryFormState extends State<_BeneficiaryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _confirmAccountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _nicknameController;

  bool _isSaving = false;
  String? _officialName;
  String? _bankName;

  @override
  void initState() {
    super.initState();
    // Initialization logic remains unchanged
    final payee = widget.existingBeneficiary;
    _nameController = TextEditingController(text: payee?.name ?? '');
    _accountNumberController = TextEditingController(text: payee?.accountNumber ?? '');
    _confirmAccountNumberController = TextEditingController(text: payee?.accountNumber ?? '');
    _ifscController = TextEditingController(text: payee?.ifsCode ?? '');
    _nicknameController = TextEditingController(text: payee?.nickname ?? '');
    if (payee != null) {
      _officialName = payee.name;
      _bankName = payee.bankName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountNumberController.dispose();
    _ifscController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // --- Validators (Unchanged) ---
  String? _validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) return 'Account number is required.';
    if (!RegExp(r'^\d{9,18}$').hasMatch(value)) return 'Account number must be 9-18 digits long.';
    return null;
  }

  String? _validateIFSC(String? value) {
    if (value == null || value.isEmpty) return 'IFSC code is required.';
    if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value.toUpperCase())) return 'Invalid IFSC format (e.g., SBIN0001234).';
    return null;
  }

  // --- Recipient Lookup Logic (Unchanged) ---
  Future<void> _lookupRecipient() async {
    // Logic remains unchanged
    if (_validateAccountNumber(_accountNumberController.text) != null ||
        _validateIFSC(_ifscController.text) != null ||
        (widget.existingBeneficiary == null && _confirmAccountNumberController.text != _accountNumberController.text))
    {
      _formKey.currentState?.validate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please correct the account and IFSC details.')));
      return;
    }

    setState(() { _isSaving = true; _officialName = null; _bankName = null; });

    try {
      final results = await _bankingService.lookupRecipient(
        recipientAccount: _accountNumberController.text.trim(),
        ifsCode: _ifscController.text.toUpperCase().trim(),
      );

      if (mounted) {
        setState(() {
          _officialName = results['officialName'];
          _bankName = results['bankName'];
          _nameController.text = _officialName!;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recipient Verified: $_officialName'), backgroundColor: kSuccessGreen));
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSaving = false; _officialName = null; _bankName = null; _nameController.clear(); });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification Failed: ${e.toString().split(':').last.trim()}')));
      }
    }
  }

  // --- Submission Logic (Unchanged) ---
  Future<void> _submitForm() async {
    // Logic remains unchanged
    if (!_formKey.currentState!.validate()) return;
    final isNew = widget.existingBeneficiary == null;
    final isVerified = _officialName != null;

    if (isNew && !isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify the account details first.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Beneficiary payeeToSubmit = Beneficiary(
        beneficiaryId: widget.existingBeneficiary?.beneficiaryId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifsCode: _ifscController.text.toUpperCase().trim(),
        bankName: isNew ? _bankName! : (widget.existingBeneficiary?.bankName ?? 'Unknown Bank'),
        nickname: _nicknameController.text.trim().isNotEmpty ? _nicknameController.text.trim() : _nameController.text.trim(),
      );

      if (isNew) {
        await _bankingService.addBeneficiary(
          name: payeeToSubmit.name, accountNumber: payeeToSubmit.accountNumber, ifsCode: payeeToSubmit.ifsCode,
          bankName: payeeToSubmit.bankName, nickname: payeeToSubmit.nickname,
        );
      } else {
        await _bankingService.updateBeneficiary(payeeToSubmit);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${isNew ? 'Added' : 'Updated'} Payee successfully!'), backgroundColor: kSuccessGreen));
        Navigator.of(context).pop(true); // Signal success to the parent screen
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: ${e.toString().split(':').last.trim()}')));
      }
    }
  }

  // --- UI Build (Refactored Styles) ---
  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingBeneficiary != null;
    final bool isVerified = _officialName != null;

    // 💡 Access Theme 💡
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      // Refactored Container Colors/Radius
      decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadiusLarge))
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Refactored Header Text Style
                Text(isEditing ? 'Edit Payee' : 'Add New Payee', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: kPaddingMedium),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // TextFormFields use the global InputDecorationTheme
                    TextFormField(controller: _accountNumberController, decoration: const InputDecoration(labelText: 'Account Number', prefixIcon: Icon(Icons.credit_card)), keyboardType: TextInputType.number, validator: _validateAccountNumber, readOnly: isEditing || isVerified),
                    const SizedBox(height: kPaddingMedium),
                    if (!isEditing)
                      TextFormField(controller: _confirmAccountNumberController, decoration: const InputDecoration(labelText: 'Confirm Account Number', prefixIcon: Icon(Icons.check_circle_outline)), keyboardType: TextInputType.number, validator: (value) => (value != _accountNumberController.text) ? 'Account numbers do not match.' : null, readOnly: isVerified),
                    if (!isEditing) const SizedBox(height: kPaddingMedium),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TextFormField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC Code', prefixIcon: Icon(Icons.account_balance), hintText: 'e.g., SBIN0001234'), textCapitalization: TextCapitalization.characters, validator: _validateIFSC, readOnly: isEditing || isVerified, onChanged: (_) { if (isVerified && !isEditing) { setState(() { _officialName = null; _bankName = null; _nameController.clear(); }); } })),
                        Padding(
                          padding: const EdgeInsets.only(left: kPaddingExtraSmall),
                          child: ElevatedButton(
                            onPressed: _isSaving || isVerified ? null : _lookupRecipient,
                            // Refactored Verify Button Style
                            style: ElevatedButton.styleFrom(
                                backgroundColor: isVerified ? kSuccessGreen : colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: kPaddingMedium, horizontal: kPaddingSmall),
                                elevation: isVerified ? 0 : 2
                            ),
                            child: _isSaving
                                ? const SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(color: kLightSurface, strokeWidth: 3))
                            // Refactored Text Style
                                : Text(isVerified ? 'VERIFIED' : 'VERIFY', style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kPaddingMedium),
                    TextFormField(controller: _nameController, decoration: InputDecoration(labelText: isEditing ? 'Payee Name' : 'Payee Name (Auto-filled on Verify)', prefixIcon: const Icon(Icons.person)), validator: (value) => (value == null || value.isEmpty) ? 'Payee name is required.' : null, readOnly: !isEditing && isVerified, textCapitalization: TextCapitalization.words),
                    if (_bankName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: kPaddingSmall),
                        child: Row(children: [
                          // Refactored Icon and Text Styles
                          Icon(Icons.check_circle, color: colorScheme.primary, size: kIconSizeSmall),
                          const SizedBox(width: kPaddingExtraSmall),
                          Text('Bank: $_bankName', style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600))
                        ]),
                      ),
                    const SizedBox(height: kPaddingMedium),
                    TextFormField(controller: _nicknameController, decoration: const InputDecoration(labelText: 'Nickname (Optional)', prefixIcon: Icon(Icons.label_outline)), textCapitalization: TextCapitalization.sentences),
                    const SizedBox(height: kPaddingLarge),
                  ],
                ),
              ),
            ),

            // Add Payee Button (Fixed at bottom of modal)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForm,
                // The global ElevatedButtonThemeData handles most styling,
                // but we explicitly define colors and padding for this unique button size.
                icon: _isSaving ? const SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(color: kLightSurface, strokeWidth: 3)) : Icon(isEditing ? Icons.save : Icons.person_add_alt_1, color: colorScheme.onPrimary),
                // Refactored Text Style
                label: Text(isEditing ? 'Save Changes' : 'Add Payee', style: textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall))
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}