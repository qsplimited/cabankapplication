import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/own_account_api.dart';
import '../models/accountmodel.dart' as model;

final ownAccountApiProvider = Provider((ref) => OwnAccountApi());

// The Return type is now explicitly List<model.Account>
final accountsProvider = FutureProvider<List<model.Account>>((ref) async {
  final api = ref.watch(ownAccountApiProvider);
  return await api.fetchAccounts();
});

final userProfileProvider = FutureProvider<model.UserProfile>((ref) async {
  return await ref.watch(ownAccountApiProvider).fetchUserProfile();
});

final sourceAccountProvider = StateProvider<model.Account?>((ref) => null);
final destAccountProvider = StateProvider<model.Account?>((ref) => null);