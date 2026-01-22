import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nominee_model.dart';
import '../api/nominee_service.dart';

final nomineeServiceProvider = Provider((ref) => NomineeService());

final nomineeProvider = StateNotifierProvider<NomineeNotifier, AsyncValue<List<NomineeModel>>>((ref) {
  return NomineeNotifier(ref.watch(nomineeServiceProvider));
});

// The temporary draft provider to hold local UI changes
final nomineeDraftProvider = StateProvider<List<NomineeModel>?>((ref) => null);

class NomineeNotifier extends StateNotifier<AsyncValue<List<NomineeModel>>> {
  final NomineeService _service;
  NomineeNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> fetchNominees(String type) async {
    state = const AsyncValue.loading();
    try {
      final list = await _service.fetchNomineesByAccountType(type);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> commitNomineeUpdates(List<NomineeModel> updatedList) async {
    try {
      // Logic: Here you would call your actual API
      // await _service.batchUpdate(updatedList);
      state = AsyncValue.data(updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }
}