import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/beneficiary_provider.dart';
import 'add_beneficiary_screen.dart';

class BeneficiaryManagementScreen extends ConsumerWidget {
  const BeneficiaryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(beneficiaryListProvider);
    final api = ref.read(apiProvider); // Logic preserved

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Payees'),
        backgroundColor: kAccentOrange, // UPDATED COLOR
        foregroundColor: Colors.white,
      ),
      body: state.when(
        data: (list) => ListView.builder(
          padding: const EdgeInsets.all(kPaddingMedium),
          itemCount: list.length,
          itemBuilder: (context, i) => Card(
            margin: const EdgeInsets.only(bottom: kPaddingSmall),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: kAccentOrange.withOpacity(0.1),
                child: const Icon(Icons.person, color: kAccentOrange),
              ),
              title: Text(list[i].nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${api.maskAccountNumber(list[i].accountNumber)}\n${list[i].bankName}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddBeneficiaryScreen(existingBeneficiary: list[i])));
                  } else {
                    ref.read(beneficiaryListProvider.notifier).removeBeneficiary(list[i].beneficiaryId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: kErrorRed))),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kAccentOrange, // UPDATED COLOR
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBeneficiaryScreen())),
        label: const Text('ADD PAYEE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}