// lib/presentation/loan_calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../bloc/loan_calculator_bloc.dart';
import '../models/loan_model.dart';

class LoanCalculatorScreen extends StatefulWidget {
  final LoanProduct product;
  const LoanCalculatorScreen({super.key, required this.product});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  late double _currentAmount;
  late int _currentTenure;

  @override
  void initState() {
    super.initState();
    _currentAmount = widget.product.minAmount;
    _currentTenure = 12;
  }

  void _updateCalc(BuildContext context) {
    context.read<LoanCalculatorBloc>().add(
        CalculatorEvent(_currentAmount, _currentTenure, widget.product.rawRate)
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoanCalculatorBloc()..add(
          CalculatorEvent(_currentAmount, _currentTenure, widget.product.rawRate)
      ),
      child: Scaffold(
        backgroundColor: kLightBackground,
        appBar: AppBar(
          backgroundColor: kAccentOrange,
          title: Text("${widget.product.title} Calculator", style: const TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(kPaddingMedium),
                child: Column(
                  children: [
                    _buildSliderCard("Loan Amount", _currentAmount, widget.product.minAmount, widget.product.maxAmount, "\$", (val) {
                      setState(() => _currentAmount = val);
                      _updateCalc(context);
                    }),
                    const SizedBox(height: kSpacingMedium),
                    _buildSliderCard(
                      "Tenure",
                      _currentTenure.toDouble(),
                      12,
                      widget.product.maxTenureMonths.toDouble(), // Changed from maxTenure to maxTenureMonths
                      "Mo",
                          (val) {
                        setState(() => _currentTenure = val.toInt());
                        _updateCalc(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderCard(String title, double value, double min, double max, String unit, Function(double) onChanged) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("$unit ${value.toInt()}", style: const TextStyle(color: kBrandNavy, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: value, min: min, max: max,
              activeColor: kAccentOrange,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary() {
    return BlocBuilder<LoanCalculatorBloc, CalculatorState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(kPaddingLarge),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLarge)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monthly EMI"),
                  Text("\$${state.emi.toStringAsFixed(2)}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandNavy)),
                ],
              ),
              const SizedBox(height: kSpacingMedium),
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kBrandNavy),
                  onPressed: () { /* Navigate to Document Upload */ },
                  child: const Text("PROCEED TO APPLY", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}