// lib/presentation/loan_landing_screen.dart
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// Importing your theme files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_sizes.dart';

import '../api/loan_repository.dart';
import '../models/loan_model.dart';
import 'loan_calculator_screen.dart';

class LoanLandingScreen extends StatefulWidget {
  const LoanLandingScreen({super.key});

  @override
  State<LoanLandingScreen> createState() => _LoanLandingScreenState();
}

class _LoanLandingScreenState extends State<LoanLandingScreen> {
  final LoanRepository _repository = LoanRepository();

  bool _isLoading = true;
  List<ActiveLoan> _activeLoans = [];
  List<LoanProduct> _products = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // --- REPLACED BLOC LOGIC WITH DIRECT DATA FETCH ---
  Future<void> _loadData() async {
    try {
      // Assuming your repository has a method to fetch all data at once
      // If they are separate, you can use await Future.wait([...])
      final activeLoans = await _repository.fetchActiveLoans();
      final products = await _repository.fetchLoanProducts();

      if (mounted) {
        setState(() {
          _activeLoans = activeLoans;
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load loan data")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kLightBackground, // Using your theme background
      appBar: AppBar(
        title: Text("Loan Management",
            style: textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: kCardElevation,
        backgroundColor: kAccentOrange, // As requested: kAccentOrange for AppBar
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kBrandNavy))
          : RefreshIndicator(
        onRefresh: _loadData,
        color: kAccentOrange,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION: ACTIVE LOANS ---
              Text("Active Loans", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: kSpacingSmall),
              _buildActiveLoanList(_activeLoans, textTheme),

              const SizedBox(height: kSpacingLarge),

              // --- SECTION: NEW LOAN PRODUCTS ---
              Text("Quick Application", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                "Choose a loan type to start your application",
                style: textTheme.labelSmall?.copyWith(color: kLightTextSecondary),
              ),
              const SizedBox(height: kSpacingMedium),
              _buildProductGrid(_products, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  // --- Reusable Widget: Active Loan Card ---
  Widget _buildActiveLoanList(List<ActiveLoan> loans, TextTheme textTheme) {
    if (loans.isEmpty) {
      return Card(
        elevation: 0,
        color: kBrandLightBlue.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
        child: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Center(child: Text("No active loans found.", style: textTheme.bodyMedium)),
        ),
      );
    }

    return SizedBox(
      height: 190.0, // Fixed height for the horizontal cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: loans.length,
        itemBuilder: (context, index) {
          final loan = loans[index];
          return Container(
            width: MediaQuery.of(context).size.width * 0.85,
            margin: const EdgeInsets.only(right: kPaddingSmall),
            padding: const EdgeInsets.all(kPaddingMedium),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBrandNavy, kBrandLightBlue], // Professional Navy gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(kRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: kBrandNavy.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loan.type, style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Icon(Icons.info_outline, color: Colors.white70, size: kIconSizeSmall),
                  ],
                ),
                const Spacer(),
                Text("Balance Remaining", style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
                Text(
                  "\$${loan.balance.toStringAsFixed(2)}",
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28, // Using a specific size if kCustomBalanceFontSize is missing
                  ),
                ),
                const SizedBox(height: kPaddingMedium),
                LinearPercentIndicator(
                  lineHeight: 6.0,
                  percent: loan.progress,
                  backgroundColor: Colors.white24,
                  progressColor: kAccentOrange, // High contrast visibility
                  barRadius: const Radius.circular(kRadiusSmall),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: kPaddingSmall),
                Text("Next EMI: ${loan.nextEmiDate}", style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Reusable Widget: Loan Product Grid ---
  Widget _buildProductGrid(List<LoanProduct> products, TextTheme textTheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: kPaddingSmall,
        mainAxisSpacing: kPaddingSmall,
        childAspectRatio: 0.82,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
          child: InkWell(
            borderRadius: BorderRadius.circular(kRadiusMedium),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoanCalculatorScreen(product: product),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(kPaddingSmall),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 52.0,
                    width: 52.0,
                    decoration: BoxDecoration(
                      color: kBrandLightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    child: Icon(product.icon, color: kBrandNavy, size: 28),
                  ),
                  const SizedBox(height: kPaddingSmall),
                  Text(product.title,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: kPaddingExtraSmall),
                  Text("ROI: ${product.interestRate}",
                      style: textTheme.labelSmall?.copyWith(color: kSuccessGreen, fontWeight: FontWeight.bold)),
                  const SizedBox(height: kPaddingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccentOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(kRadiusExtraSmall),
                    ),
                    child: Text(
                      product.tag,
                      style: textTheme.labelSmall?.copyWith(
                          color: kAccentOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}