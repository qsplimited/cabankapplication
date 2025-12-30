import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../api/mock_fd_api_service.dart';
import '../api/mock_rd_api_service.dart';
import 'fd_td_input_screen.dart';
import 'rd_input_screen.dart';
import 'receipt_selection_screen.dart';
import 'deposit_terms_and_conditions_screen.dart';
import 'interest_rate_screen.dart';
import 'deposit_list_screen.dart';
import 'deposit_receipt_screen.dart'; // Ensure this is imported

class DepositOpeningScreen extends StatelessWidget {
  const DepositOpeningScreen({super.key});

  Widget _buildBottomActions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const Color linkColor = kLightTextLink;

    return Padding(
      padding: const EdgeInsets.only(top: kPaddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DepositTermsAndConditionsScreen()));
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Click here for Terms and Condition', style: textTheme.bodyLarge?.copyWith(color: linkColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: kPaddingSmall),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InterestRateScreen()));
            },
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Click here for Interest Rate', style: textTheme.bodyLarge?.copyWith(color: linkColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Instantiate mock services
    final fdApiService = MockFdApiService();
    final rdApiService = MockRdApiService();

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: kAccentOrange,
        elevation: kCardElevation,
        centerTitle: false,
        iconTheme: const IconThemeData(color: kLightSurface),
        title: Text('Deposit Opening', style: textTheme.titleLarge?.copyWith(color: kLightSurface, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(kPaddingMedium),
        children: [
          // 1. FD Card
          _buildDepositCard(
            context,
            icon: Icons.account_balance_wallet,
            title: 'FD/TD (Fixed Deposit)',
            subtitle: 'Open a new FD account instantly and obtain receipt on the go!',
            actionText: 'Open the Account',
            onActionTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => FdTdInputScreen(apiService: fdApiService))),
            accentColor: kBrandPurple,
          ),

          // 2. RD Card
          _buildDepositCard(
            context,
            icon: Icons.repeat_one_sharp,
            title: 'RD (Recurring Deposit)',
            subtitle: 'Open a new RD account with standing instruction for monthly amount inflow!',
            actionText: 'Open the Account',
            onActionTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => RdInputScreen(apiService: rdApiService))),
            accentColor: kBrandPurple,
          ),

          // 3. View Receipts (Selection Screen)
          _buildDepositCard(
            context,
            icon: Icons.receipt_long,
            title: 'View Last FD Receipt',
            subtitle: 'Access your receipts for New Openings, Renewals, or Closures.',
            actionText: 'View Receipts',
            onActionTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ReceiptSelectionScreen())),
            accentColor: kBrandLightBlue,
            isNew: true,
          ),

          // 4. Manage Deposit
          _buildDepositCard(
            context,
            icon: Icons.settings_applications,
            title: 'Manage Deposit',
            subtitle: 'Manage your maturity instructions and nominee details here.',
            actionText: 'Manage Deposit',
            onActionTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DepositListScreen())),
            accentColor: kBrandPurple,
          ),

          // 5. Loan Against Deposit (FIXED ERROR HERE)
          _buildDepositCard(
            context,
            icon: Icons.monetization_on,
            title: 'Loan Against Deposit',
            subtitle: 'Quickly view the receipt for your most recent Fixed Deposit transaction.',
            actionText: 'View Receipt',
            onActionTap: () async {
              // We fetch the receipt first, then navigate
              final receipt = await fdApiService.fetchDepositReceipt('FD-123456');
/*              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DepositReceiptScreen(receipt: receipt),
                ),
              );*/
            },
            accentColor: kBrandLightBlue,
            isNew: true,
          ),

          _buildBottomActions(context),
        ],
      ),
    );
  }

  Widget _buildDepositCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required String actionText, required VoidCallback onActionTap, required Color accentColor, bool isNew = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
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
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(kRadiusSmall)),
                  child: Icon(icon, color: accentColor, size: kIconSizeLarge),
                ),
                const SizedBox(width: kPaddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold))),
                          if (isNew) ...[
                            const SizedBox(width: kPaddingExtraSmall),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: kErrorRed, borderRadius: BorderRadius.circular(4)),
                              child: Text('NEW', style: textTheme.labelSmall?.copyWith(color: kLightSurface, fontWeight: FontWeight.bold, fontSize: 8)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: kPaddingMedium),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onActionTap, child: Text(actionText, style: textTheme.bodyMedium?.copyWith(color: accentColor, fontWeight: FontWeight.bold))),
            ),
          ],
        ),
      ),
    );
  }
}