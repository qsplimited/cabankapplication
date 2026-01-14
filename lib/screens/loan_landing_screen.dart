import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// Importing your theme files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_sizes.dart';
import '../bloc/loan_bloc.dart';
import '../api/loan_repository.dart';
import '../models/loan_model.dart';
import 'loan_calculator_screen.dart';

class LoanLandingScreen extends StatelessWidget {
  const LoanLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (context) => LoanBloc(LoanRepository())..add(FetchLoanData()),
      child: Scaffold(
        backgroundColor: kLightBackground, // Using your theme background
        appBar: AppBar(
          title: Text("Loan Management", style: textTheme.titleLarge?.copyWith(color: Colors.white)),
          centerTitle: true,
          elevation: kCardElevation,
          backgroundColor: kAccentOrange, // As requested: kAccentOrange for AppBar
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: BlocBuilder<LoanBloc, LoanState>(
          builder: (context, state) {
            if (state is LoanLoading) {
              return const Center(child: CircularProgressIndicator(color: kBrandNavy));
            } else if (state is LoanLoaded) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(kPaddingMedium), // Reusing app_dimensions
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION: ACTIVE LOANS ---
                    Text("Active Loans", style: textTheme.titleMedium),
                    const SizedBox(height: kSpacingSmall),
                    _buildActiveLoanList(state.activeLoans, textTheme),

                    const SizedBox(height: kSpacingLarge),

                    // --- SECTION: NEW LOAN PRODUCTS ---
                    Text("Quick Application", style: textTheme.titleMedium),
                    Text(
                      "Choose a loan type to start your application",
                      style: textTheme.labelSmall?.copyWith(color: kLightTextSecondary),
                    ),
                    const SizedBox(height: kSpacingMedium),
                    _buildProductGrid(state.products, textTheme),


                  ],
                ),
              );
            } else {
              return const Center(child: Text("Something went wrong"));
            }
          },
        ),
      ),
    );
  }

  // --- Reusable Widget: Active Loan Card ---
  Widget _buildActiveLoanList(List<ActiveLoan> loans, TextTheme textTheme) {
    if (loans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Center(child: Text("No active loans found.", style: textTheme.bodyMedium)),
        ),
      );
    }

    return SizedBox(
      height: AppSizes.cardHeight, // Reusing AppSizes constant
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
                    Text(loan.type, style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                    const Icon(Icons.info_outline, color: Colors.white70, size: kIconSizeSmall),
                  ],
                ),
                const Spacer(),
                Text("Balance Remaining", style: textTheme.labelSmall?.copyWith(color: Colors.white70)),
                Text(
                  "\$${loan.balance.toStringAsFixed(2)}",
                  style: textTheme.displayLarge?.copyWith(color: Colors.white, fontSize: kCustomBalanceFontSize),
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
        childAspectRatio: 0.85,
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
                    height: 48.0, // kCardIconBackgroundSize
                    width: 48.0,
                    decoration: BoxDecoration(
                      color: kBrandLightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    child: Icon(product.icon, color: kBrandNavy, size: kIconSize),
                  ),
                  const SizedBox(height: kPaddingSmall),
                  Text(product.title, style: textTheme.titleSmall, textAlign: TextAlign.center),
                  const SizedBox(height: kPaddingExtraSmall),
                  Text("ROI: ${product.interestRate}",
                      style: textTheme.labelSmall?.copyWith(color: kSuccessGreen, fontWeight: FontWeight.bold)),
                  const SizedBox(height: kPaddingSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccentOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(kRadiusExtraSmall),
                    ),
                    child: Text(
                      product.tag,
                      style: textTheme.labelSmall?.copyWith(color: kAccentOrange, fontWeight: FontWeight.bold, fontSize: 10),
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