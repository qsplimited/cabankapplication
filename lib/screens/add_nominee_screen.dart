import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/nominee_model.dart';
import '../api/nominee_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class AddNomineeScreen extends StatefulWidget {
  const AddNomineeScreen({super.key});

  @override
  State<AddNomineeScreen> createState() => _AddNomineeScreenState();
}

class _AddNomineeScreenState extends State<AddNomineeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedRelationship;
  bool _isSaving = false;
  final NomineeService _service = NomineeService();

  final List<String> _relationships = [
    'Spouse', 'Son', 'Daughter', 'Father', 'Mother', 'Brother', 'Sister', 'Guardian'
  ];

  Future<void> _saveNomineeToDatabase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newNominee = NomineeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: _nameController.text.trim(),
      relationship: _selectedRelationship!,
      sharePercentage: 100.0,
      accountType: 'Savings',
    );

    try {
      await _service.addNominee(newNominee);
      if (mounted) {
        Navigator.pop(context, newNominee); // SEND DATA BACK
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Nominee Details"),
        backgroundColor: kAccentOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Enter details of the nominee.", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: kPaddingLarge),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person_outline)),
                validator: (val) => (val == null || val.isEmpty) ? "Please enter name" : null,
              ),
              const SizedBox(height: kPaddingMedium),

              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: const InputDecoration(labelText: "Relationship", prefixIcon: Icon(Icons.family_restroom_outlined)),
                items: _relationships.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) => setState(() => _selectedRelationship = val),
                validator: (val) => val == null ? "Select relationship" : null,
              ),
              const SizedBox(height: kPaddingMedium),

              Container(
                padding: const EdgeInsets.all(kPaddingSmall),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text("Share Percentage: 100% (Fixed)", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: kPaddingXXL),

              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveNomineeToDatabase,
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("SAVE NOMINEE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}