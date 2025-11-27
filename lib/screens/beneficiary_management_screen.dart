// File: beneficiary_management_screen.dart (UNCHANGED - Already Robust)

import 'package:flutter/material.dart';

// 💡 IMPORTANT: Import all necessary types and screens
import '../api/banking_service.dart';
import '../screens/transfer_amount_entry_screen.dart'; // For fund transfer navigation

// Access the shared service instance
final BankingService _bankingService = BankingService();

// --- Main Screen Class ---
class BeneficiaryManagementScreen extends StatefulWidget {
  // Use a named route for easy navigation back from the Fund Transfer flow
  static const String routeName = '/manageBeneficiaries';

  const BeneficiaryManagementScreen({super.key});

  @override
  State<BeneficiaryManagementScreen> createState() => _BeneficiaryManagementScreenState();
}

class _BeneficiaryManagementScreenState extends State<BeneficiaryManagementScreen> {


  List<Beneficiary> _beneficiaries = [];
  Account? _sourceAccount;
  bool _isLoading = true;

  final Color _primaryNavyBlue = const Color(0xFF003366);
  final Color _accentGreen = const Color(0xFF4CAF50);
  final Color _darkGrey = Colors.grey.shade700;

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
        print('Error loading data: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _manageBeneficiary({Beneficiary? existingBeneficiary}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _BeneficiaryForm(
          existingBeneficiary: existingBeneficiary,
          primaryNavyBlue: _primaryNavyBlue,
        ),
      ),

    );

    if (result == true) {
      _loadData();
    }
  }

  // --- Fund Transfer Navigation (Crucial point: Routes to the smart screen) ---
  void _navigateToFundTransfer(Beneficiary beneficiary) {
    if (_sourceAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot initiate transfer:source account not loaded.')),
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


  Future<void> _deleteBeneficiary(Beneficiary payee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to delete payee "${payee.nickname}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL', style: TextStyle(color: _primaryNavyBlue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _bankingService.deleteBeneficiary(payee.beneficiaryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payee "${payee.nickname}" deleted successfully.'), backgroundColor: _accentGreen),
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


  Widget _buildPayeeList() {
    if (_beneficiaries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_disabled_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No Payees Added', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tap "Add New Payee" to begin.', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _beneficiaries.length,
      padding: const EdgeInsets.only(top: 10, bottom: 80),
      itemBuilder: (context, index) {
        final payee = _beneficiaries[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(

            onTap: () => _navigateToFundTransfer(payee),

            leading: CircleAvatar(
              backgroundColor: _primaryNavyBlue.withOpacity(0.1),
              child: Icon(Icons.account_circle, color: _primaryNavyBlue),
            ),
            title: Text(payee.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
              'A/c: ${_bankingService.maskAccountNumber(payee.accountNumber)}\nBank: ${payee.bankName} (IFSC: ${payee.ifsCode})',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: _darkGrey),
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
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, color: Colors.black54), SizedBox(width: 8), Text('Edit Nickname/Name')]),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete Payee', style: TextStyle(color: Colors.red))]),
                ),
              ],
              icon: Icon(Icons.more_vert, color: _primaryNavyBlue),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryNavyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 1,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: _primaryNavyBlue,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: _primaryNavyBlue))
            : _buildPayeeList(),
      ),

      // **ACTION:** Floating button to add new payee
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _manageBeneficiary(),
        backgroundColor: _accentGreen,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add New Payee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

// ----------------------------------------------------------------------
// --- Beneficiary Add/Edit Form Component (Unchanged) ---
// ----------------------------------------------------------------------

class _BeneficiaryForm extends StatefulWidget {
  final Beneficiary? existingBeneficiary;
  final Color primaryNavyBlue;

  const _BeneficiaryForm({this.existingBeneficiary, required this.primaryNavyBlue});

  @override
  State<_BeneficiaryForm> createState() => _BeneficiaryFormState();
}

class _BeneficiaryFormState extends State<_BeneficiaryForm> {
  // ... (All form logic and UI remain the same) ...
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

  // --- Validators (same as before) ---
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

  // --- Recipient Lookup Logic (VERIFY Button) (Unchanged) ---
  Future<void> _lookupRecipient() async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recipient Verified: $_officialName'), backgroundColor: Colors.green.shade600));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${isNew ? 'Added' : 'Updated'} Payee successfully!'), backgroundColor: Colors.green.shade600));
        Navigator.of(context).pop(true); // Signal success to the parent screen
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Operation failed: ${e.toString().split(':').last.trim()}')));
      }
    }
  }

  // --- UI Build (Unchanged) ---
  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.existingBeneficiary != null;
    final bool isVerified = _officialName != null;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                Text(isEditing ? 'Edit Payee' : 'Add New Payee', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.primaryNavyBlue)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(height: 20),

            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextFormField(controller: _accountNumberController, decoration: const InputDecoration(labelText: 'Account Number', prefixIcon: Icon(Icons.credit_card), border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: _validateAccountNumber, readOnly: isEditing || isVerified),
                    const SizedBox(height: 16),
                    if (!isEditing)
                      TextFormField(controller: _confirmAccountNumberController, decoration: const InputDecoration(labelText: 'Confirm Account Number', prefixIcon: Icon(Icons.check_circle_outline), border: OutlineInputBorder()), keyboardType: TextInputType.number, validator: (value) => (value != _accountNumberController.text) ? 'Account numbers do not match.' : null, readOnly: isVerified),
                    if (!isEditing) const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: TextFormField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC Code', prefixIcon: Icon(Icons.account_balance), border: const OutlineInputBorder(), hintText: 'e.g., SBIN0001234'), textCapitalization: TextCapitalization.characters, validator: _validateIFSC, readOnly: isEditing || isVerified, onChanged: (_) { if (isVerified && !isEditing) { setState(() { _officialName = null; _bankName = null; _nameController.clear(); }); } })),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ElevatedButton(
                            onPressed: _isSaving || isVerified ? null : _lookupRecipient,
                            style: ElevatedButton.styleFrom(backgroundColor: isVerified ? Colors.green : widget.primaryNavyBlue, padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10), elevation: isVerified ? 0 : 2),
                            child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Text(isVerified ? 'VERIFIED' : 'VERIFY', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _nameController, decoration: InputDecoration(labelText: isEditing ? 'Payee Name' : 'Payee Name (Auto-filled on Verify)', prefixIcon: const Icon(Icons.person), border: const OutlineInputBorder()), validator: (value) => (value == null || value.isEmpty) ? 'Payee name is required.' : null, readOnly: !isEditing && isVerified, textCapitalization: TextCapitalization.words),
                    if (_bankName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(children: [Icon(Icons.check_circle, color: widget.primaryNavyBlue, size: 16), const SizedBox(width: 8), Text('Bank: $_bankName', style: TextStyle(color: widget.primaryNavyBlue, fontWeight: FontWeight.w600))]),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(controller: _nicknameController, decoration: const InputDecoration(labelText: 'Nickname (Optional)', prefixIcon: Icon(Icons.label_outline), border: OutlineInputBorder()), textCapitalization: TextCapitalization.sentences),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Add Payee Button (Fixed at bottom of modal)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _submitForm,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : Icon(isEditing ? Icons.save : Icons.person_add_alt_1, color: Colors.white),
                label: Text(isEditing ? 'Save Changes' : 'Add Payee', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: widget.primaryNavyBlue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}