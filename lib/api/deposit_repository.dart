// lib/api/deposit_repository.dart

import '../models/deposit_account.dart';

class DepositRepository {
  // 🌟 STATIC DATA: This ensures changes like 'Lien Marking' persist across screens
  static List<DepositAccount> _mockDeposits = [
    DepositAccount(
      id: "FD-101",
      accountNumber: "9812XXXX4433",
      accountType: "Fixed Deposit",
      principalAmount: 100000.0,
      accruedInterest: 4250.0,
      interestRate: 8.0,
      openingDate: DateTime(2024, 1, 15),
      maturityDate: DateTime(2025, 1, 15),
      linkedAccountNumber: "SAV-009988",
      nominees: [Nominee(name: "Jane Watson", relationship: "Spouse", share: 100.0)],
      status: DepositStatus.running,
      lienStatus: "Nil",
    ),
    DepositAccount(
      id: "FD-554",
      accountNumber: "9812XXXX9900",
      accountType: "Fixed Deposit",
      principalAmount: 50000.0,
      accruedInterest: 3150.0,
      interestRate: 8.0,
      openingDate: DateTime(2023, 11, 10),
      maturityDate: DateTime(2024, 11, 10),
      linkedAccountNumber: "SAV-009988",
      nominees: [Nominee(name: "Jane Watson", relationship: "Spouse", share: 100.0)],
      status: DepositStatus.matured,
      lienStatus: "Nil",
    ),
    DepositAccount(
      id: "RD-202",
      accountNumber: "RD-XXXX-7766",
      accountType: "Recurring Deposit",
      principalAmount: 25000.0,
      accruedInterest: 1100.0,
      interestRate: 8.0,
      openingDate: DateTime(2024, 5, 20),
      maturityDate: DateTime(2026, 5, 20),
      linkedAccountNumber: "SAV-009988",
      nominees: [Nominee(name: "Jane Watson", relationship: "Spouse", share: 100.0)],
      status: DepositStatus.running,
      lienStatus: "Nil",
    ),
    // Case 4: Initially has a lien marked for testing the block logic
    DepositAccount(
      id: "dep-04",
      accountNumber: "FD-LIEN-7788",
      accountType: "Fixed Deposit",
      principalAmount: 75000.0,
      accruedInterest: 3200.0,
      interestRate: 7.0,
      openingDate: DateTime.now().subtract(const Duration(days: 180)),
      maturityDate: DateTime.now().add(const Duration(days: 180)),
      linkedAccountNumber: "SAV-1234",
      status: DepositStatus.running,
      nominees: [Nominee(name: "Amit Shah", relationship: "Brother", share: 100)],
      lienStatus: "Marked",
    ),
  ];

  void markAsLien(String depositId) {
    int index = _mockDeposits.indexWhere((d) => d.id == depositId);
    if (index != -1) {
      // Create a new version of the object with "Marked" status
      _mockDeposits[index] = _mockDeposits[index].copyWith(lienStatus: "Marked");
      print("System: Deposit $depositId is now LOCKED.");
    }
  }

  // 1. FETCH ALL DEPOSITS
  Future<List<DepositAccount>> fetchAllDeposits() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockDeposits;
  }

/*  // 🌟 NEW LOGIC: Update lien status when a loan is applied
  Future<void> markLienStatus(String depositId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    int index = _mockDeposits.indexWhere((d) => d.id == depositId);
    if (index != -1) {
      _mockDeposits[index] = _mockDeposits[index].copyWith(lienStatus: "Marked");
    }
  }*/

  // 2. PREMATURE CLOSURE PREVIEW
  Future<Map<String, dynamic>> calculatePrematureClosure(String depositId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    double principal = 100000.0;
    double baseRate = 8.0;
    double penaltyRate = 1.0;
    double effectiveRate = baseRate - penaltyRate;
    double revisedInterest = principal * (effectiveRate / 100) * 0.5;
    double penaltyAmount = principal * (penaltyRate / 100) * 0.5;
    double taxDeducted = revisedInterest * 0.10;
    double finalPayout = principal + revisedInterest - taxDeducted;

    return {
      "originalRate": baseRate,
      "effectiveRate": effectiveRate,
      "penaltyAmount": penaltyAmount,
      "revisedInterest": revisedInterest,
      "taxDeducted": taxDeducted,
      "finalPayout": finalPayout,
    };
  }

  // 3. SECURITY VERIFICATION
  Future<bool> verifyTPin(String tPin) async {
    await Future.delayed(const Duration(seconds: 1));
    return tPin == "123456";
  }

  // 4. UPDATE ACTIONS
  Future<bool> updateNominees({required String depositId, required List<Nominee> updatedNominees}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> submitMaturityAction({required String depositId, required String actionType, required String tenure}) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}