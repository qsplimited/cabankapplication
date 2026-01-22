import '../api/banking_service.dart' as service;

class DashboardRepository {
  final service.BankingService _service;
  DashboardRepository(this._service);

  Future<service.UserProfile> getProfile() => _service.fetchUserProfile();

  Future<List<service.Account>> getDashboardAccounts() async {
    final all = await _service.fetchUserAccounts();
    // Filters only Savings, Current, and RD for the UI
    return all.where((acc) =>
    acc.accountType == service.AccountType.savings ||
        acc.accountType == service.AccountType.current ||
        acc.accountType == service.AccountType.recurringDeposit
    ).toList();
  }
}