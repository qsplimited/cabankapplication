import 'package:flutter_bloc/flutter_bloc.dart';
import '../api/loan_repository.dart';
import '../models/loan_model.dart';

// --- Events ---
abstract class LoanEvent {}
class FetchLoanData extends LoanEvent {}

// --- States ---
abstract class LoanState {}
class LoanLoading extends LoanState {}
class LoanLoaded extends LoanState {
  final List<ActiveLoan> activeLoans;
  final List<LoanProduct> products;
  LoanLoaded(this.activeLoans, this.products);
}
class LoanError extends LoanState {
  final String message;
  LoanError(this.message);
}

// --- Bloc ---
class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final LoanRepository repository;

  // Fix: Pass LoanLoading() to the super constructor
  LoanBloc(this.repository) : super(LoanLoading()) {

    // Modern BLoC syntax using 'on'
    on<FetchLoanData>((event, emit) async {
      try {
        emit(LoanLoading());
        final data = await repository.fetchLoanData();

        // Ensure your repository returns the correct keys
        emit(LoanLoaded(
            data['activeLoans'] as List<ActiveLoan>,
            data['products'] as List<LoanProduct>
        ));
      } catch (e) {
        emit(LoanError("Failed to fetch loan data"));
      }
    });
  }
}