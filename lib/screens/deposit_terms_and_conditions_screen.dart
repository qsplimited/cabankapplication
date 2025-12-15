// File: lib/screens/deposit_terms_and_conditions_screen.dart

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class DepositTermsAndConditionsScreen extends StatefulWidget {
  const DepositTermsAndConditionsScreen({Key? key}) : super(key: key);

  @override
  State<DepositTermsAndConditionsScreen> createState() =>
      _DepositTermsAndConditionsScreenState();
}

class _DepositTermsAndConditionsScreenState
    extends State<DepositTermsAndConditionsScreen> {
  // State to track agreement status
  bool _isAgreed = false;

  // --- Helper Widget: Collapsible Section Card ---
  Widget _buildSectionCard(
      BuildContext context, {
        required String title,
        required List<Widget> children,
      }) {
    return Card(
      elevation: kCardElevation, //
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(kRadiusMedium)), //
      ),
      color: kLightSurface, //
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: kPaddingMedium, vertical: kPaddingExtraSmall), //
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.bold,
            color: kAccentOrange, //
          ),
        ),
        // Force initial state to collapsed for better UX on long lists
        initiallyExpanded: false,
        children: [
          const Divider(height: kDividerHeight, color: kLightDivider), //
          Padding(
            padding: const EdgeInsets.all(kPaddingMedium), //
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widget: Single Detail Row for Terms ---
  Widget _buildDetailRow(
      BuildContext context, {
        required String label,
        required String value,
        Color? highlightColor,
        bool isCritical = false,
      }) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: kLabelColumnWidth, //
          child: Text(
            '$label ',
            style: textTheme.bodyMedium!.copyWith(
              color: kLightTextSecondary, //
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium!.copyWith(
              color: highlightColor ?? (isCritical ? kBrandNavy : kLightTextPrimary), //
              fontWeight: isCritical ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // --- Footer: Agreement Checkbox and Button ---
  Widget _buildBottomAffirmation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kPaddingMedium), //
      decoration: BoxDecoration(
        color: kLightSurface, //
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox for agreement
            Row(
              children: [
                Checkbox(
                  value: _isAgreed,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isAgreed = newValue ?? false;
                    });
                  },
                  activeColor: kBrandNavy, //
                ),
                Expanded(
                  child: Text(
                    'I have read and agree to the Deposit Terms & Conditions.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .copyWith(color: kLightTextPrimary), //
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpacingMedium), //
            // Confirmation Button
            ElevatedButton(
              onPressed: _isAgreed
                  ? () {
                // Action: Typically closes the T&C screen and proceeds to deposit input
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Terms Accepted. Proceeding...')),
                );
              }
                  : null, // Button is disabled if terms are not agreed
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandNavy, //
                minimumSize: const Size(double.infinity, kButtonHeight), //
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMedium), //
                ),
              ),
              child: Text(
                'Confirm Deposit',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(color: kLightSurface), //
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kLightBackground, //
      appBar: AppBar(
        title: Text(
          'Deposit Terms & Conditions',
          style: textTheme.titleLarge!.copyWith(
            color: kLightSurface, //
          ),
        ),
        backgroundColor: kAccentOrange, //
        iconTheme: const IconThemeData(color: kLightSurface), // White icons
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(kPaddingMedium), //
              children: [
                // Section I: Premature Withdrawal Policy
                _buildSectionCard(
                  context,
                  title: 'I. Premature Withdrawal Policy (Penalty)',
                  children: [
                    _buildDetailRow(context, label: 'Withdrawal Allowed:', value: 'Yes (Subject to Penalty)', isCritical: true),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Penalty Rate:', value: '1.00% on Applicable Rate', isCritical: true, highlightColor: kErrorRed), // Penalty highlighted in red
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Applicable Rate:', value: 'Lower of contracted rate or rate for actual period held.'),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Lock-in Period:', value: 'No interest paid if withdrawn within 7 days of deposit.', highlightColor: kAccentOrange), //
                  ],
                ),
                const SizedBox(height: kSpacingMedium), //

                // Section II: Interest & Maturity Rules
                _buildSectionCard(
                  context,
                  title: 'II. Interest & Maturity Rules',
                  children: [
                    _buildDetailRow(context, label: 'Compounding Frequency:', value: 'Quarterly'),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Interest Payout:', value: 'Monthly/Quarterly to linked Savings A/C.'),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Auto-Renewal Policy:', value: 'Auto-renewed for same tenure at prevailing interest rate.', highlightColor: kAccentOrange),
                  ],
                ),
                const SizedBox(height: kSpacingMedium),

                // Section III: Loan Against Deposit (LAD)
                _buildSectionCard(
                  context,
                  title: 'III. Loan Against Deposit (LAD)',
                  children: [
                    _buildDetailRow(context, label: 'Loan Eligibility:', value: 'Up to 90% of Principal Amount', isCritical: true),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Interest Rate on Loan:', value: 'Deposit Rate + 2.00%'),
                  ],
                ),
                const SizedBox(height: kSpacingMedium),

                // Section IV: Tax (TDS) and Forms
                _buildSectionCard(
                  context,
                  title: 'IV. Tax (TDS) and Forms',
                  children: [
                    _buildDetailRow(context, label: 'TDS Threshold:', value: 'As per prevailing IT Act regulations.'),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'TDS Prevention:', value: 'Submit Form 15G/H via the Tax Services menu.', highlightColor: kBrandLightBlue), // Link color
                  ],
                ),
                const SizedBox(height: kSpacingMedium),

                // Section V: Nomination & Succession
                _buildSectionCard(
                  context,
                  title: 'V. Nomination & Succession',
                  children: [
                    _buildDetailRow(context, label: 'Nomination Status:', value: 'Registered', isCritical: true),
                    const SizedBox(height: kSpacingSmall),
                    _buildDetailRow(context, label: 'Joint Account Mandate:', value: 'Either or Survivor (Default)'),
                  ],
                ),
                const SizedBox(height: kPaddingLarge), // Space before the sticky footer
              ],
            ),
          ),
          // Sticky footer with agreement checkbox and button
          _buildBottomAffirmation(context),
        ],
      ),
    );
  }
}