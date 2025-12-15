// File: lib/screens/deposit_opening_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../api/mock_fd_api_service.dart';
import '../api/mock_rd_api_service.dart';
import 'fd_td_input_screen.dart';
import 'rd_input_screen.dart';
import 'deposit_receipt_screen.dart';

import 'deposit_terms_and_conditions_screen.dart';

import 'interest_rate_screen.dart';


const String kMockTransactionIdFd = 'FD-TXN-123456789';

class DepositOpeningScreen extends StatelessWidget {
  const DepositOpeningScreen({super.key});

  // --- New method for the two bottom buttons ---
  Widget _buildBottomActions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Using kLightTextLink (which is kBrandPurple) for link color
    const Color linkColor = kLightTextLink;

    return Padding(
      padding: const EdgeInsets.only(top: kPaddingMedium), //
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Terms and Conditions Button
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DepositTermsAndConditionsScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Click here for Terms and Condition',
              style: textTheme.bodyLarge?.copyWith(
                color: linkColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: kPaddingSmall), //

          // 2. Interest Rate Button
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InterestRateScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Click here for Interest Rate',
              style: textTheme.bodyLarge?.copyWith(
                color: linkColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ---------------------------------------------


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const Color appBarColor = kAccentOrange; //
    const Color cardAccentColor = kBrandPurple; //
    const Color receiptAccentColor = kBrandLightBlue; // Use theme color

    // Instantiate mock services once
    final fdApiService = MockFdApiService();
    final rdApiService = MockRdApiService();

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        // Colors are explicitly set here, overriding the theme's default AppBar color (surface)
        backgroundColor: appBarColor,
        elevation: kCardElevation, // Use theme elevation
        centerTitle: false,
        iconTheme: const IconThemeData(color: kLightSurface), // Use theme color
        title: Text(
          'Deposit Opening',
          style: textTheme.titleLarge?.copyWith(
            color: kLightSurface, // Use theme color
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium), // Use theme padding
        children: [
          // 1. Fixed Deposit/Term Deposit Card (FD/TD)
          _buildDepositCard(
            context,
            icon: Icons.account_balance_wallet,
            title: 'FD/TD (Fixed Deposit/Term Deposit)',
            subtitle: 'Open a new FD account instantly and obtain receipt on the go!',
            actionText: 'Open the Account',
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FdTdInputScreen(
                    apiService: fdApiService,
                  ),
                ),
              );
            },
            accentColor: cardAccentColor,
            iconColor: colorScheme.primary,
          ),

          // 2. Recurring Deposit Card (RD)
          _buildDepositCard(
            context,
            icon: Icons.repeat_one_sharp,
            title: 'RD (Recurring Deposit)',
            subtitle: 'Open a new RD account with standing instruction for monthly amount inflow!',
            actionText: 'Open the Account',
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RdInputScreen(
                    apiService: rdApiService,
                  ),
                ),
              );
            },
            accentColor: cardAccentColor,
          ),

          // 3. View Last Deposit Receipt Card (links to DepositReceiptScreen)
          _buildDepositCard(
            context,
            icon: Icons.receipt_long,
            title: 'View Last FD Receipt',
            subtitle: 'Quickly view the receipt for your most recent Fixed Deposit transaction.',
            actionText: 'View Receipt',
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DepositReceiptScreen(
                    transactionId: kMockTransactionIdFd,
                    fdApiService: fdApiService,
                    rdApiService: rdApiService,
                    depositType: 'FD',
                  ),
                ),
              );
            },
            accentColor: receiptAccentColor,
            iconColor: receiptAccentColor,
            isNew: true,
          ),

          _buildBottomActions(context),
        ],
      ),
    );
  }

  // --- _buildDepositCard implementation (Remains unchanged but included for completeness) ---
  Widget _buildDepositCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required String actionText,
        required VoidCallback onActionTap,
        required Color accentColor,
        Color? iconColor,
        bool isNew = false,
      }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final finalIconColor = iconColor ?? accentColor;

    return Card(
      elevation: kCardElevation, //
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium), //
      ) ,
      margin: const EdgeInsets.only(bottom: kPaddingMedium), //
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium), //
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(kPaddingSmall), //
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kRadiusSmall), //
                  ),
                  child: Icon(
                    icon,
                    color: finalIconColor,
                    size: kIconSizeLarge, //
                  ),
                ),
                const SizedBox(width: kPaddingMedium), //
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isNew) ...[
                            const SizedBox(width: kPaddingExtraSmall), //
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: kBadgePaddingHorizontal, //
                                vertical: kBadgePaddingVertical,   //
                              ),
                              decoration: BoxDecoration(
                                color: kErrorRed, //
                                borderRadius: BorderRadius.circular(kRadiusExtraSmall), //
                              ),
                              child: Text(
                                'NEW',
                                style: textTheme.labelSmall?.copyWith(
                                  color: kLightSurface, //
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: kPaddingExtraSmall), //
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: kPaddingMedium), //
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onActionTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}