import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/beneficiary_model.dart';
import '../providers/beneficiary_provider.dart';

class AddBeneficiaryScreen extends ConsumerStatefulWidget {
  final Beneficiary? existingBeneficiary;
  const AddBeneficiaryScreen({super.key, this.existingBeneficiary});

  @override
  ConsumerState<AddBeneficiaryScreen> createState() => _AddBeneficiaryScreenState();
}

class _AddBeneficiaryScreenState extends ConsumerState<AddBeneficiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _acc, _confirmAcc, _ifsc, _name, _nick;
  String? _bank;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existingBeneficiary;
    _acc = TextEditingController(text: b?.accountNumber ?? '');
    _confirmAcc = TextEditingController(text: b?.accountNumber ?? '');
    _ifsc = TextEditingController(text: b?.ifsCode ?? '');
    _name = TextEditingController(text: b?.name ?? '');
    _nick = TextEditingController(text: b?.nickname ?? '');
    _bank = b?.bankName;
  }

  Future<void> _handleVerify() async {
    if (_ifsc.text.isEmpty) return;
    setState(() => _verifying = true);
    final res = await ref.read(apiProvider).verifyIFSC(_ifsc.text);
    setState(() {
      _bank = res['bankName'];
      _name.text = "Verified Holder";
      _verifying = false;
    });
  }

  void _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Verify IFSC first")));
      return;
    }

    final b = Beneficiary(
      beneficiaryId: widget.existingBeneficiary?.beneficiaryId ?? DateTime.now().toString(),
      name: _name.text,
      accountNumber: _acc.text,
      ifsCode: _ifsc.text,
      bankName: _bank!,
      nickname: _nick.text.isEmpty ? _name.text : _nick.text,
    );

    if (widget.existingBeneficiary != null) {
      await ref.read(beneficiaryListProvider.notifier).editBeneficiary(b.beneficiaryId, b);
    } else {
      await ref.read(beneficiaryListProvider.notifier).addBeneficiary(b);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingBeneficiary != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Payee' : 'ADD Payee'),
        backgroundColor: kAccentOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(kPaddingMedium),
          children: [
            TextFormField(
              controller: _acc,
              decoration: const InputDecoration(labelText: 'A/c Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: kSpacingMedium),
            if (!isEdit) ...[
              TextFormField(
                controller: _confirmAcc,
                decoration: const InputDecoration(labelText: 'Confirm A/c Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v != _acc.text ? 'Numbers do not match' : null,
              ),
              const SizedBox(height: kSpacingMedium),
            ],
            Row(
              children: [
                Expanded(child: TextFormField(controller: _ifsc, decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder()))),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _verifying ? null : _handleVerify,
                  style: TextButton.styleFrom(foregroundColor: kAccentOrange),
                  child: _verifying ? const CircularProgressIndicator() : const Text('VERIFY'),
                ),
              ],
            ),
            if (_bank != null) Text('Bank: $_bank', style: const TextStyle(color: kSuccessGreen, fontWeight: FontWeight.bold)),
            const SizedBox(height: kSpacingMedium),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Official Name'), readOnly: true),
            const SizedBox(height: kSpacingMedium),
            TextFormField(controller: _nick, decoration: const InputDecoration(labelText: 'Nickname')),
            const SizedBox(height: kSpacingLarge),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange, minimumSize: const Size(double.infinity, kButtonHeight)),
              onPressed: _onConfirm,
              child: const Text('CONFIRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}