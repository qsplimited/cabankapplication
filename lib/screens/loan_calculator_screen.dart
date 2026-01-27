import 'dart:math'; // Required for EMI power calculation
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
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
  double _monthlyEMI = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize with product defaults
    _currentAmount = widget.product.minAmount;
    _currentTenure = 12; // Default 1 year
    _calculateEMI();
  }

  // --- REPLACED BLOC LOGIC WITH DIRECT CALCULATION ---
  void _calculateEMI() {
    double principal = _currentAmount;
    double annualRate = widget.product.rawRate;
    int tenureMonths = _currentTenure;

    if (annualRate <= 0) {
      _monthlyEMI = principal / tenureMonths;
    } else {
      // EMI Formula: [P x R x (1+R)^N] / [(1+R)^N - 1]
      double monthlyRate = annualRate / (12 * 100);
      double temp = pow(1 + monthlyRate, tenureMonths).toDouble();
      _monthlyEMI = (principal * monthlyRate * temp) / (temp - 1);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9), // Matching your kLightBackground
      appBar: AppBar(
        backgroundColor: kAccentOrange,
        title: Text(
          "${widget.product.title} Calculator",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                children: [
                  // Amount Slider Card
                  _buildSliderCard(
                    "Loan Amount",
                    _currentAmount,
                    widget.product.minAmount,
                    widget.product.maxAmount,
                    "\$",
                        (val) {
                      setState(() => _currentAmount = val);
                      _calculateEMI();
                    },
                  ),
                  const SizedBox(height: 16),
                  // Tenure Slider Card
                  _buildSliderCard(
                    "Tenure",
                    _currentTenure.toDouble(),
                    12,
                    widget.product.maxTenureMonths.toDouble(),
                    "Mo",
                        (val) {
                      setState(() => _currentTenure = val.toInt());
                      _calculateEMI();
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildSliderCard(String title, double value, double min, double max, String unit, Function(double) onChanged) {
    return Card(
      elevation: 2, // Matching kCardElevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  "$unit ${value.toInt()}",
                  style: const TextStyle(color: kBrandNavy, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              activeColor: kAccentOrange,
              inactiveColor: kAccentOrange.withOpacity(0.2),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(24), // Matching kPaddingLarge
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Matching kRadiusLarge
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Monthly EMI",
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                "\$${_monthlyEMI.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kBrandNavy),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55, // Matching kButtonHeight
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                // Logic to navigate to Document Upload as per original requirement
              },
              child: const Text(
                "PROCEED TO APPLY",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}