// We use 'as model' to tell Flutter exactly which Account class to use
import '../models/accountmodel.dart' as model;
import '../api/banking_service.dart';

class OwnAccountApi {
  // Use the alias 'model.Account'
  final List<model.Account> _mockAccounts = [
    model.Account(
      uId: 'ACC001',
      accountNumber: '123456789012',
      accountType: AccountType.savings,
      balance: 55678.50,
      nickname: 'Primary Savings',
    ),
    model.Account(
      uId: 'ACC002',
      accountNumber: '987654321098',
      accountType: AccountType.current,
      balance: 152000.00,
      nickname: 'Business Current',
    ),
  ];

  // Explicitly return Future<List<model.Account>> to avoid 'dynamic' errors
  Future<List<model.Account>> fetchAccounts() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockAccounts;
  }

  Future<model.UserProfile> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return model.UserProfile(
      fullName: 'Arjun Reddy',
      userId: 'ARJUN12345',
      mobileNumber: '9876541234', // Dynamic mobile for OTP
    );
  }
}