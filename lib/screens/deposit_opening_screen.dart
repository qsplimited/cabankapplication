import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../api/mock_fd_api_service.dart';
import '../api/mock_rd_api_service.dart';
import 'fd_td_input_screen.dart';
import 'rd_input_screen.dart';

class DepositOpeningScreen extends StatelessWidget {
  const DepositOpeningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const Color appBarColor = kAccentOrange;
    const Color cardAccentColor = kBrandPurple;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: kLightSurface),
        title: Text(
          'Deposit Opening',
          style: textTheme.titleLarge?.copyWith(
            color: kLightSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
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
                    apiService: MockFdApiService(),
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
                    // 🌟 FIX: Instantiating the concrete class MockRdApiService
                    apiService: MockRdApiService(),
                  ),
                ),
              );
            },
            accentColor: cardAccentColor,
          ),
        ],
      ),
    );
  }

  // --- _buildDepositCard implementation ---
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
      elevation: kCardElevation,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      margin: const EdgeInsets.only(bottom: kPaddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(kPaddingSmall),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                  ),
                  child: Icon(
                    icon,
                    color: finalIconColor,
                    size: kIconSizeLarge,
                  ),
                ),
                const SizedBox(width: kPaddingMedium),
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
                            const SizedBox(width: kPaddingExtraSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: kErrorRed,
                                borderRadius: BorderRadius.circular(3.0),
                              ),
                              child: Text(
                                'NEW',
                                style: textTheme.labelSmall?.copyWith(
                                  color: kLightSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: kPaddingExtraSmall),
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
            const SizedBox(height: kPaddingMedium),
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