// lib/api/mock_chat_repository.dart
import 'i_chat_repository.dart';

class MockChatRepository implements IChatRepository {
  @override
  Future<String> getBotResponse(String userQuery) async {
    // Simulate real API delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // 1. Normalization: Convert everything to lowercase for case-insensitive matching
    final String s = userQuery.toLowerCase();

    // 2. Intent Detection using Keywords (Handles long sentences)

    // Profile Management
    if (_contains(s, ['profile', 'kyc', 'my details', 'address', 'email', 'ವಿಳಾಸ'])) {
      return "I can help you with Profile Management. You can update your email, address, and KYC details there. Shall I open it for you?";
    }

    // Fund Transfer & Payees
    if (_contains(s, ['transfer', 'payee', 'send money', 'beneficiary', 'ವರ್ಗಾವಣೆ'])) {
      if (s.contains('quick')) {
        return "I've opened 'Quick Transfer' for you. You can send up to ₹25,000 instantly without adding a payee.";
      }
      return "For regular payments, use 'Manage Payees'. For instant small amounts, 'Quick Transfer' is better. Which should I open?";
    }

    // Deposit Management
    if (_contains(s, ['deposit', 'fd', 'rd', 'fixed deposit', 'ಠೇವಣಿ'])) {
      return "In 'Deposit Management', you can open new Fixed or Recurring Deposits and view your interest certificates.";
    }

    // Transaction History
    if (_contains(s, ['history', 'statement', 'transactions', 'passbook', 'ಹಿಂದಿನ'])) {
      return "You can view all your recent credits and debits in the 'Transaction History' section. Would you like to see it?";
    }

    // T-PIN Management
    if (_contains(s, ['pin', 'tpin', 't-pin', 'security', 'ಪಿನ್'])) {
      return "You can reset your 4-digit T-PIN in 'T-PIN Management'. Remember, never share your PIN with anyone.";
    }

    // Service Management
    if (_contains(s, ['service', 'cheque', 'nominee', 'pan', 'tds', 'ಚೆಕ್'])) {
      return "Under 'Service Management', you can request a Cheque Book, update your Nominee, or update your PAN card.";
    }

    // Fallback for unrecognized long sentences
    return "I'm still learning! You can ask me about 'Transferring money', 'Updating my Profile', or 'Checking History'.";
  }

  // Helper method: Robust enough to find a keyword anywhere in a long sentence
  bool _contains(String sentence, List<String> keywords) {
    return keywords.any((key) => sentence.contains(key));
  }
}