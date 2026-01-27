import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nominee_model.dart';
import '../providers/nominee_provider.dart';
import '../theme/app_colors.dart'; // Ensure kAccentOrange and kLightBackground are here

class NomineeListScreen extends ConsumerStatefulWidget {
  final String accountType;
  const NomineeListScreen({super.key, required this.accountType});

  @override
  ConsumerState<NomineeListScreen> createState() => _NomineeListScreenState();
}

class _NomineeListScreenState extends ConsumerState<NomineeListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(nomineeProvider.notifier).fetchNominees(widget.accountType)
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(nomineeProvider);
    final draftNominees = ref.watch(nomineeDraftProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // Clean light background
      appBar: AppBar(
        title: Text('Manage Nominees', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        elevation: 0,
        centerTitle: true,
      ),
      body: serverState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Unable to load nominees")),
        data: (nominees) {
          // Initialize Draft
          if (draftNominees == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(nomineeDraftProvider.notifier).state = nominees.map((n) => n.copyWith()).toList();
            });
            return const Center(child: CircularProgressIndicator());
          }

          double totalShare = draftNominees.fold(0, (sum, n) => sum + n.sharePercentage);
          bool isFullyAllocated = totalShare == 100.0;

          return Column(
            children: [
              // Header Instruction
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: kAccentOrange.withOpacity(0.1),
                child: Text(
                  "Total allocation must be exactly 100% to save.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.w600),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: draftNominees.length,
                  itemBuilder: (context, index) {
                    final nominee = draftNominees[index];
                    return _buildNomineeCard(nominee, index);
                  },
                ),
              ),

              // Redesigned Summary and Action Section
              _buildBottomSummary(totalShare, isFullyAllocated, draftNominees),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNomineeCard(NomineeModel nominee, int index) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      // 1. Wrap the child with InkWell to make it clickable
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // 2. THIS IS WHERE YOU PASTE THE CODE
          // It sends the selected nominee back to the FD Input Screen
          Navigator.pop(context, nominee);
        },
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
              nominee.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text("${nominee.relationship} • ${nominee.sharePercentage.toStringAsFixed(0)}% Share"),
          ),
          // Keep your edit button as is for actual editing
          trailing: Container(
            decoration: BoxDecoration(
                color: kAccentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)
            ),
            child: IconButton(
              icon: Icon(Icons.edit_outlined, color: kAccentOrange),
              onPressed: () => _showEditDialog(index),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSummary(double total, bool isValid, List<NomineeModel> draft) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Current Allocation", style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text(
                  "${total.toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: isValid ? () => _handleConfirm(draft) : null,
                child: const Text(
                  "CONFIRM & SAVE",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(int index) async {
    final list = ref.read(nomineeDraftProvider);
    if (list == null) return;

    final updated = await showDialog<NomineeModel>(
      context: context,
      barrierDismissible: false,
      builder: (context) => NomineeUpdateDialog(nominee: list[index]),
    );

    if (updated != null) {
      final newList = List<NomineeModel>.from(list);
      newList[index] = updated;
      ref.read(nomineeDraftProvider.notifier).state = newList;
    }
  }

  void _handleConfirm(List<NomineeModel> draft) async {
    final success = await ref.read(nomineeProvider.notifier).commitNomineeUpdates(draft);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nominee preferences updated successfully"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// --- Dialog: Tightly Aligned ---
class NomineeUpdateDialog extends StatefulWidget {
  final NomineeModel nominee;
  const NomineeUpdateDialog({super.key, required this.nominee});

  @override
  State<NomineeUpdateDialog> createState() => _NomineeUpdateDialogState();
}

class _NomineeUpdateDialogState extends State<NomineeUpdateDialog> {
  late TextEditingController _shareController;
  late String _relationship;

  @override
  void initState() {
    super.initState();
    _shareController = TextEditingController(text: widget.nominee.sharePercentage.toStringAsFixed(0));
    _relationship = widget.nominee.relationship;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Edit ${widget.nominee.fullName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min, // 🌟 Fixes alignment
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Relationship", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _relationship,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: ['Spouse', 'Son', 'Daughter', 'Parent', 'Sibling', 'Other']
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _relationship = v!),
          ),
          const SizedBox(height: 16),
          const Text("Benefit Share (%)", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _shareController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: "%",
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey))
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          onPressed: () {
            final val = double.tryParse(_shareController.text) ?? 0;
            Navigator.pop(context, widget.nominee.copyWith(relationship: _relationship, sharePercentage: val));
          },
          child: const Text("SAVE DRAFT", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}