// lib/api/chat_repository.dart

import 'dart:async';

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp
  });
}

// lib/api/chat_repository.dart

class ChatRepository {
  Future<String> getBotResponse(String userQuery) async {
    // Simulate thinking time
    await Future.delayed(const Duration(milliseconds: 1500));

    // Normalize: lowercase handles "Transfer", "TRANSFER", and "transfer"
    String s = userQuery.toLowerCase();

    // 1. Fund Transfer & Payees
    if (_match(s, ["transfer", "send money", "payee", "beneficiary", "ವರ್ಗಾವಣೆ"])) {
      return "I can help you with that. You can use 'Quick Transfer' for small amounts or 'Manage Payees' for regular transfers. Which one should I open?";
    }

    // 2. T-PIN Management
    if (_match(s, ["pin", "tpin", "t-pin", "password", "ಪಿನ್"])) {
      return "Security Tip: You can reset your T-PIN anytime in the 'T-PIN Management' section under Profile. Never share your PIN with anyone.";
    }

    // 3. Service Management (Cheque, PAN, Nominee, TDS)
    if (_match(s, ["nominee", "pan", "tds", "update", "ನೋಮಿನಿ"])) {
      return "In 'Service Management', you can update your Nominee details, update your PAN card, or request a TDS certificate. Shall I guide you there?";
    }
    if (_match(s, ["cheque", "check", "stop", "ಚೆಕ್"])) {
      return "You can request a new 25-leaf Cheque Book or 'Stop Cheque Payment' instantly under the Service Management menu.";
    }

    // 4. Deposits (FD/RD & Loan against Deposit)
    if (_match(s, ["fd", "rd", "deposit", "receipt", "ಠೇವಣಿ"])) {
      if (s.contains("loan") || s.contains("against")) {
        return "You can apply for a 'Loan Against Deposit' using your active FD/RD as collateral. It's instant and requires no paperwork!";
      }
      return "In 'Deposit Management', you can view your FD/RD receipts, check maturity dates, or open a new Fixed Deposit.";
    }

    // 5. Profile & KYC
    if (_match(s, ["profile", "address", "email", "kyc", "ವಿಳಾಸ"])) {
      return "You can edit your Email and Address or view your fetched KYC details in the 'Profile Management' section.";
    }

    // 6. ATM & Location
    if (_match(s, ["atm", "branch", "locate", "nearby", "ಹತ್ತಿರದ"])) {
      return "I can find the nearest ATM or Branch for you. Please check the 'Locate Us' feature on your dashboard.";
    }

    // 7. Transaction History
    if (_match(s, ["history", "statement", "transactions", "ಹಿಂದಿನ"])) {
      return "You can view all your recent credits and debits in the 'Transaction History' screen. Would you like to see it now?";
    }

    // Fallback for unrecognized sentences
    return "I'm still learning! Try asking me about 'Fund Transfer', 'Check Balance', or 'Update Nominee'.";
  }

  // Helper logic: Check if ANY keyword from the list is present in the long sentence
  bool _match(String sentence, List<String> keywords) {
    return keywords.any((key) => sentence.contains(key));
  }
}