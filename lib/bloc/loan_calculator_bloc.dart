// lib/bloc/loan_calculator_bloc.dart
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';

class CalculatorEvent {
  final double amount;
  final int months;
  final double annualRate;
  CalculatorEvent(this.amount, this.months, this.annualRate);
}

class CalculatorState {
  final double emi;
  final double totalInterest;
  CalculatorState(this.emi, this.totalInterest);
}

class LoanCalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  LoanCalculatorBloc() : super(CalculatorState(0, 0)) {
    on<CalculatorEvent>((event, emit) {
      double monthlyRate = event.annualRate / 12 / 100;
      num power = pow(1 + monthlyRate, event.months);

      double emi = (event.amount * monthlyRate * power) / (power - 1);
      double totalPayable = emi * event.months;
      double totalInterest = totalPayable - event.amount;

      emit(CalculatorState(emi, totalInterest));
    });
  }
}