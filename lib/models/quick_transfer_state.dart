import '../api/banking_service.dart';

class QuickTransferState {
  final List<Account> accounts;
  final Account? selectedAccount;
  final bool isLoading;
  final bool isVerifyingRecipient;
  final Map<String, String>? verifiedRecipient;
  final String? errorMessage;
  final String transactionReference;

  QuickTransferState({
    this.accounts = const [],
    this.selectedAccount,
    this.isLoading = false,
    this.isVerifyingRecipient = false,
    this.verifiedRecipient,
    this.errorMessage,
    this.transactionReference = '',
  });

  QuickTransferState copyWith({
    List<Account>? accounts,
    Account? selectedAccount,
    bool? isLoading,
    bool? isVerifyingRecipient,
    Map<String, String>? verifiedRecipient,
    String? errorMessage,
    String? transactionReference,
  }) {
    return QuickTransferState(
      accounts: accounts ?? this.accounts,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      isLoading: isLoading ?? this.isLoading,
      isVerifyingRecipient: isVerifyingRecipient ?? this.isVerifyingRecipient,
      verifiedRecipient: verifiedRecipient ?? this.verifiedRecipient,
      errorMessage: errorMessage,
      transactionReference: transactionReference ?? this.transactionReference,
    );
  }
}