import 'package:flutter/material.dart';
import '../api/banking_service.dart';

class AddBeneficiaryScreen extends StatefulWidget {
  final Beneficiary? existingBeneficiary;
  const AddBeneficiaryScreen({super.key, this.existingBeneficiary});

  @override
  State<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends State<AddBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final BankingService _service = BankingService();

  late TextEditingController _accController;
  late TextEditingController _confirmAccController;
  late TextEditingController _ifscController;
  late TextEditingController _nameController;
  late TextEditingController _nickController;

  bool _isVerifying = false;
  bool _isSaving = false;
  String? _detectedBank;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBeneficiary;
    _accController = TextEditingController(text: b?.accountNumber ?? '');
    _confirmAccController = TextEditingController(text: b?.accountNumber ?? '');
    _ifscController = TextEditingController(text: b?.ifsCode ?? '');
    _nameController = TextEditingController(text: b?.name ?? '');
    _nickController = TextEditingController(text: b?.nickname ?? '');
    if (b != null) _detectedBank = b.bankName;
  }

  // Robust Verification Logic
  Future<void> _handleVerify() async {
    if (_accController.text != _confirmAccController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account numbers do not match')));
      return;
    }

    setState(() => _isVerifying = true);
    try {
      final res = await _service.lookupRecipient(
        recipientAccount: _accController.text.trim(),
        ifsCode: _ifscController.text.trim().toUpperCase(),
      );
      setState(() {
        _nameController.text = res['officialName']!;
        _detectedBank = res['bankName'];
        _isVerifying = false;
      });
    } catch (e) {
      setState(() => _isVerifying = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_detectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify first')));
      return;
    }

    setState(() => _isSaving = true);
    final payload = AddBeneficiaryPayload(
      name: _nameController.text.trim(),
      accountNumber: _accController.text.trim(),
      ifsCode: _ifscController.text.trim(),
      bankName: _detectedBank!,
      nickname: _nickController.text.isEmpty ? _nameController.text : _nickController.text,
    );

    try {
      if (widget.existingBeneficiary != null) {
        await _service.updateBeneficiary(widget.existingBeneficiary!.beneficiaryId as String, payload);
      } else {
        await _service.addBeneficiary(payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingBeneficiary != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Payee' : 'Add Payee')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _accController, decoration: const InputDecoration(labelText: 'Account Number'), keyboardType: TextInputType.number),
            if (!isEdit) const SizedBox(height: 16),
            if (!isEdit) TextFormField(controller: _confirmAccController, decoration: const InputDecoration(labelText: 'Confirm Account Number'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _ifscController, decoration: const InputDecoration(labelText: 'IFSC Code'))),
                TextButton(onPressed: _isVerifying ? null : _handleVerify, child: _isVerifying ? const CircularProgressIndicator() : const Text('VERIFY')),
              ],
            ),
            if (_detectedBank != null) Text('Bank: $_detectedBank', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Official Name'), readOnly: true),
            const SizedBox(height: 16),
            TextFormField(controller: _nickController, decoration: const InputDecoration(labelText: 'Nickname')),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _isSaving ? null : _save, child: Text(isEdit ? 'UPDATE' : 'SAVE')),
          ],
        ),
      ),
    );
  }
}