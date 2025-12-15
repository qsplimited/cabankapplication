// File: lib/screens/interest_rate_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// Mock data structure for the interest rates
class InterestRate {
  final String tenure;
  final String generalRate;
  final String seniorCitizenRate;

  InterestRate(this.tenure, this.generalRate, this.seniorCitizenRate);
}

// Mock Data Source for FD Rates
final List<InterestRate> mockFdRates = [
  InterestRate('7 - 14 Days', '3.00%', '3.50%'),
  InterestRate('15 - 45 Days', '4.50%', '5.00%'),
  InterestRate('46 - 90 Days', '5.25%', '5.75%'),
  InterestRate('91 - 180 Days', '5.75%', '6.25%'),
  InterestRate('181 Days - 1 Year', '6.50%', '7.00%'),
  InterestRate('1 Year - 2 Years', '7.25%', '7.75%'),
  InterestRate('2 Years - 3 Years', '7.00%', '7.50%'),
  InterestRate('3 Years - 5 Years', '6.75%', '7.25%'),
  InterestRate('5 Years - 10 Years', '6.50%', '7.00%'),
];

// Mock Data Source for RD Rates (usually slightly different or less variation)
final List<InterestRate> mockRdRates = [
  InterestRate('6 Months', '5.50%', '6.00%'),
  InterestRate('1 Year', '6.75%', '7.25%'),
  InterestRate('2 Years', '7.00%', '7.50%'),
  InterestRate('3 Years', '6.75%', '7.25%'),
  InterestRate('5 Years', '6.50%', '7.00%'),
];

class InterestRateScreen extends StatelessWidget {
  const InterestRateScreen({super.key});

  // Helper method to build the Rate Table (DataTable)
  Widget _buildRateTable(BuildContext context, List<InterestRate> rates) {
    final textTheme = Theme.of(context).textTheme;
    const Color headerColor = kAccentOrange; //
    const Color dividerColor = kLightDivider; //

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Allows horizontal scrolling for narrow screens
      child: DataTable(
        // Set column spacing based on design system
        columnSpacing: kPaddingLarge, //
        dataRowMinHeight: kButtonHeight, // Use button height for generous row spacing
        dataRowMaxHeight: kButtonHeight,
        headingRowColor: MaterialStateProperty.all(headerColor.withOpacity(0.1)),
        horizontalMargin: kPaddingMedium, //
        dividerThickness: 1.0,
        columns: [
          DataColumn(
              label: Text('Tenure',
                  style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: headerColor))),
          DataColumn(
              label: Text('General Public',
                  style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: headerColor)),
              numeric: true),
          DataColumn(
              label: Text('Senior Citizen*',
                  style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: headerColor))),
        ],
        rows: rates
            .map(
              (rate) => DataRow(
            cells: [
              DataCell(Text(rate.tenure,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600))),
              DataCell(Text(rate.generalRate,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: kBrandNavy))), //
              DataCell(Text(rate.seniorCitizenRate,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: kSuccessGreen, fontWeight: FontWeight.bold))), // Highlighted rate
            ],
            // Add a visual separator between rows
            color: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                  return dividerColor.withOpacity(0.5);
                }),
          ),
        )
            .toList(),
      ),
    );
  }

  // Helper method to build the Disclaimer Section
  Widget _buildDisclaimer(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium), //
      child: Container(
        padding: const EdgeInsets.all(kPaddingMedium), //
        decoration: BoxDecoration(
          color: kWarningYellow.withOpacity(0.1), // Light warning background
          borderRadius: BorderRadius.circular(kRadiusMedium), //
          border: Border.all(color: kWarningYellow, width: 1.0), //
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Important Notes:',
              style: textTheme.titleSmall?.copyWith(
                color: kWarningYellow, //
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: kPaddingExtraSmall), //
            Text(
              'Rates shown are for deposits below ₹2 Crore (Retail) and are effective from ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}. Senior Citizen rates are applicable for individuals aged 60 years and above.',
              style: textTheme.bodySmall?.copyWith(
                color: kLightTextPrimary.withOpacity(0.8), //
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 2, // Two tabs: FD and RD
      child: Scaffold(
        backgroundColor: kLightBackground, //
        appBar: AppBar(
          title: Text(
            'Current Interest Rate Chart',
            style: textTheme.titleLarge!.copyWith(
              color: kLightSurface, //
            ),
          ),
          backgroundColor: kAccentOrange, //
          iconTheme: const IconThemeData(color: kLightSurface),
          bottom: TabBar(
            indicatorColor: kAccentOrange, // Tab indicator highlight color
            labelColor: kAccentOrange, // Active tab label color
            unselectedLabelColor: kLightSurface, // Inactive tab label color
            labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            unselectedLabelStyle: textTheme.titleSmall,
            tabs: const [
              Tab(text: 'Fixed Deposit (FD)'),
              Tab(text: 'Recurring Deposit (RD)'),
            ],
          ),
        ),
        body: Column(
          children: [
            // 1. Disclaimer Section (always visible at the top)
            _buildDisclaimer(context),

            // 2. Tab Views (Rate Tables)
            Expanded(
              child: TabBarView(
                children: [
                  // FD Tab Content
                  _buildRateTable(context, mockFdRates),

                  // RD Tab Content
                  _buildRateTable(context, mockRdRates),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}