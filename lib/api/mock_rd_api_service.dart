import 'rd_api_service.dart';
import '../models/fd_models.dart';
import '../models/rd_models.dart';

class MockRdApiService implements RdApiService {
  @override
  Future<SourceAccount> fetchSourceAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return SourceAccount(
      accountNumber: 'XXX-1234567890',
      availableBalance: 98567.50,
      dailyLimit: 50000.00, // Max single installment amount
      nomineeNames: ['Suresh Kumar', 'Aarti Sharma'],
    );
  }

  @override
  Future<List<DepositScheme>> fetchDepositSchemes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      DepositScheme(id: 'RD-001', name: 'Standard Recurring Deposit', interestRate: 6.85),
      DepositScheme(id: 'RD-002', name: 'Senior Citizen RD Scheme', interestRate: 7.50),
      DepositScheme(id: 'RD-003', name: 'Flexi RD (High Interest)', interestRate: 7.05),
    ];
  }

  @override
  Future<RdMaturityDetails> calculateMaturity({
    required double installmentAmount,
    required String schemeId,
    required int tenureYears,
    required int tenureMonths,
    required int tenureDays,
    required String nomineeName,
    required String sourceAccountId,
    required String frequencyMode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final totalMonths = (tenureYears * 12) + tenureMonths;
    double frequencyFactor = 1.0;
    if (frequencyMode == 'Quarterly') frequencyFactor = 1.0 / 3.0;
    if (frequencyMode == 'Half-Yearly') frequencyFactor = 1.0 / 6.0;

    final totalInstallments = (totalMonths * frequencyFactor).round();
    final rate = schemeId == 'RD-002' ? 0.075 : 0.0685;

    final totalPrincipal = installmentAmount * totalInstallments;
    // Simple linear projection for mock interest calculation
    final estimatedInterest = totalPrincipal * rate * (totalMonths / 12.0) * 0.55;

    return RdMaturityDetails(
      totalPrincipalAmount: totalPrincipal,
      interestEarned: estimatedInterest,
      maturityAmount: totalPrincipal + estimatedInterest,
      maturityDate: '24-Mar-${DateTime.now().year + tenureYears + (tenureMonths > 0 ? 1 : 0)}',
    );
  }
}