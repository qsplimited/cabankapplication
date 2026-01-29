import '../api/banking_service.dart' show AccountType;

class Account {
  final String uId;
  final String accountNumber;
  final String nickname;
  final AccountType accountType;
  final double balance;

  Account({
    required this.uId,
    required this.accountNumber,
    required this.nickname,
    required this.accountType,
    required this.balance,
  });

  String get maskedDisplay => "$nickname (...${accountNumber.substring(accountNumber.length - 4)})";
}

class UserProfile {
  final String fullName;
  final String mobileNumber;
  final String userId;

  UserProfile({required this.fullName, required this.mobileNumber, required this.userId});
}