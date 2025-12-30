import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../models/deposit_account.dart';
import '../api/deposit_repository.dart';
import 'manage_deposit_screen.dart';
import 'tpin_verification_screen.dart';

class EditNomineeScreen extends StatefulWidget {
  final DepositAccount deposit;
  const EditNomineeScreen({Key? key, required this.deposit}) : super(key: key);

  @override
  _EditNomineeScreenState createState() => _EditNomineeScreenState();
}

class _EditNomineeScreenState extends State<EditNomineeScreen> {
  late List<Nominee> _tempNominees;
  final List<String> _relationships = ['Spouse', 'Son', 'Daughter', 'Parent', 'Sibling', 'Other'];

  @override
  void initState() {
    super.initState();
    // Creates a fresh copy so we don't modify the original data until T-PIN is verified
    _tempNominees = widget.deposit.nominees.map((e) => e.copyWith()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightBackground,
      appBar: AppBar(
        title: const Text("Edit Nominees"),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                children: List.generate(_tempNominees.length, (index) => _buildEditCard(index)),
              ),
            ),
          ),
          _buildProceedButton(),
        ],
      ),
    );
  }

  Widget _buildEditCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nominee ${index + 1}", style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy)),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _tempNominees[index].name,
              decoration: const InputDecoration(labelText: "Legal Name", border: OutlineInputBorder()),
              onChanged: (v) => _tempNominees[index] = _tempNominees[index].copyWith(name: v),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _relationships.contains(_tempNominees[index].relationship) ? _tempNominees[index].relationship : 'Other',
              decoration: const InputDecoration(labelText: "Relationship", border: OutlineInputBorder()),
              items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (v) => setState(() => _tempNominees[index] = _tempNominees[index].copyWith(relationship: v)),
            ),
            const SizedBox(height: 15),
            TextFormField(
              initialValue: _tempNominees[index].share.toString(),
              decoration: const InputDecoration(labelText: "Share %", border: OutlineInputBorder(), suffixText: "%"),
              keyboardType: TextInputType.number,
              onChanged: (v) => _tempNominees[index] = _tempNominees[index].copyWith(share: double.tryParse(v) ?? 0.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium),
      color: Colors.white,
      child: SizedBox(
        height: kButtonHeight,
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange, elevation: 0),
          onPressed: _validateAndProceed,
          child: const Text("PROCEED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

// Inside EditNomineeScreen.dart

  void _validateAndProceed() {
    double total = _tempNominees.fold(0, (sum, item) => sum + item.share);

    if (total != 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total share must be exactly 100%"), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => TPinVerificationScreen(
          title: "Update Nominees",
          subTitle: "Enter T-PIN to authorize nominee changes",
          onAuthorize: (pin) async {
            // 1. Verify PIN
            bool isPinValid = await DepositRepository().verifyTPin(pin);
            if (!isPinValid) return false;

            // 2. Perform Update API Call
            bool isSuccess = await DepositRepository().updateNominees(
              depositId: widget.deposit.id,
              updatedNominees: _tempNominees,
            );

            if (isSuccess) {
              // 3. Show Success Toast
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Nominees updated successfully!"),
                  backgroundColor: kSuccessGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => ManageDepositScreen(
                    // 🌟 CHANGE: Pass the deposit with the new nominees
                    deposit: widget.deposit.copyWith(nominees: _tempNominees),
                  ),
                ),
                    (route) => route.isFirst,
              );
            }
            return isSuccess;
          },
        ),
      ),
    );
  }
}