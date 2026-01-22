import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/profile_api_service.dart';
import '../models/profile_model.dart';

final profileApiProvider = Provider((ref) => ProfileApiService());

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<ProfileData>>((ref) {
  return ProfileNotifier(ref.read(profileApiProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<ProfileData>> {
  final ProfileApiService _api;

  ProfileNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    state = const AsyncValue.loading();
    try {
      final data = await _api.getProfile();
      state = AsyncValue.data(data);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateProfileField(String key, String value) async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      final success = await _api.updateField(key, value);
      if (success) {
        state = AsyncValue.data(
            key == 'emailId'
                ? currentState.copyWith(emailId: value)
                : currentState.copyWith(communicationAddress: value)
        );
      }
    } catch (e) {
      // Handle error
    }
  }
}