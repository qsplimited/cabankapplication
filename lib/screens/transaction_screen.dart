import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/pin_provider.dart';

class TransactionScreen extends ConsumerWidget {
  final String fromAccount;
  final String mpin;
  final double amount;

  const TransactionScreen({super.key, required this.fromAccount, required this.mpin, required this.amount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(pinNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Confirm")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.info, color: Colors.orange, size: 50),
            const Text("Review Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Account"), Text(fromAccount)]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Amount"), Text("₹$amount", style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: pinState.isLoading ? null : () async {
                  final success = await ref.read(pinNotifierProvider.notifier).setTransactionPin(fromAccount, mpin);
                  if (success) {
                    showModalBottomSheet(context: context, builder: (context) => Container(
                        height: 200,
                        child: Center(child: Text("Transaction Successful!"))
                    ));
                  }
                },
                child: pinState.isLoading ? const CircularProgressIndicator() : const Text("CONFIRM"),
              ),
            )
          ],
        ),
      ),
    );
  }
}