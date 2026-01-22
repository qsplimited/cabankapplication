import 'dart:async';
import 'banking_service.dart' as service; // Referring to your existing mock service

class BankingRepository {
  final service.BankingService _mockService = service.BankingService();

  // This method bridges your existing mock service to the new architecture
  Future<List<service.Transaction>> fetchAllTransactions() async {
    return await _mockService.fetchAllTransactions();
  }

  Future<service.Account?> fetchAccountSummary() async {
    return await _mockService.fetchAccountSummary();
  }
}