import '../models/deposit_account.dart';

class DepositRepository {

  // 1. Fetch Details (Your existing code)
  Future<DepositAccount> fetchDepositDetails() async {
    await Future.delayed(const Duration(seconds: 1));
    return DepositAccount(
      id: "FD-55442",
      accountNumber: "9812XXXX4433",
      accountType: "Fixed Deposit",
      principalAmount: 100000.0,
      accruedInterest: 8250.0,
      interestRate: 7.5,
      openingDate: DateTime(2023, 12, 15),
      maturityDate: DateTime(2024, 12, 15),
      linkedAccountNumber: "SAV-009988",
      nominees: [
        Nominee(name: "Jane Watson", relationship: "Spouse", share: 100.0),
      ],
    );
  }

  // 2. THE UNIVERSAL T-PIN VERIFIER
  // This will be used by Fund Transfer, Nominee Change, and Maturity Actions
  Future<bool> verifyTPin(String tPin) async {
    await Future.delayed(const Duration(seconds: 2));
    // Mock Logic: Only '123456' works
    return tPin == "123456";
  }

  // 3. NOMINEE SUBMISSION
  // Called only after T-PIN is verified
  Future<bool> updateNominees({
    required String depositId,
    required List<Nominee> updatedNominees,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    print("API SUCCESS: Nominees updated in database for $depositId");
    return true;
  }

  // 4. MATURITY ACTION (Your existing code)
  Future<bool> submitMaturityAction({
    required String depositId,
    required String actionType,
    required String tenure,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    return true;
  }
}