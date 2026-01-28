import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/beneficiary_api.dart';
import '../models/beneficiary_model.dart';

final apiProvider = Provider((ref) => BeneficiaryApi());

class BeneficiaryNotifier extends AsyncNotifier<List<Beneficiary>> {
  @override
  Future<List<Beneficiary>> build() async {
    // This loads the 3 initial cases
    return ref.read(apiProvider).fetchBeneficiaries();
  }

  Future<void> addBeneficiary(Beneficiary b) async {
    state = const AsyncLoading();
    ref.read(apiProvider).addLocal(b);
    ref.invalidateSelf(); // REFRESH UI
  }

  Future<void> editBeneficiary(String id, Beneficiary b) async {
    state = const AsyncLoading();
    ref.read(apiProvider).updateLocal(id, b);
    ref.invalidateSelf(); // REFRESH UI
  }

  Future<void> removeBeneficiary(String id) async {
    ref.read(apiProvider).deleteLocal(id);
    ref.invalidateSelf(); // REFRESH UI
  }
}

final beneficiaryListProvider = AsyncNotifierProvider<BeneficiaryNotifier, List<Beneficiary>>(BeneficiaryNotifier.new);