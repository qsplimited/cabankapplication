// lib/api/deposit_repository.dart

import '../models/deposit_account.dart';

class DepositRepository {
  // 1. FETCH ALL DEPOSITS (FOR THE LIST SCREEN)
  Future<List<DepositAccount>> fetchAllDeposits() async {
    await Future.delayed(const Duration(milliseconds: 800));

    // All deposits are now set to 8.0% as requested
    return [
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
      ),
    ];
  }

  // 2. PREMATURE CLOSURE PREVIEW
  // Logic: Original 8% -> Penalty 1% -> Effective 7%
  Future<Map<String, dynamic>> calculatePrematureClosure(String depositId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Simulation for FD-101 (Principal: 100,000)
    double principal = 100000.0;
    double baseRate = 8.0;
    double penaltyRate = 1.0;
    double effectiveRate = baseRate - penaltyRate; // 7%

    // Calculation for 6 months (0.5 years)
    double revisedInterest = principal * (effectiveRate / 100) * 0.5;
    double penaltyAmount = principal * (penaltyRate / 100) * 0.5;

    // Tax/GST simulation (10% of earned interest)
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