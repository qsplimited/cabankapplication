import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'request_cheque_book_screen.dart';

import 'stop_cheque_screen.dart';
import 'pan_update_screen.dart';

import 'tds_certificate_screen.dart';
// FIX 1: Removed incorrect import of 'nominee_card.dart' and replaced with the actual screen
import 'nominee_list_screen.dart';


class ServicesManagementScreen extends StatelessWidget {
  // CRITICAL FIX: Adding the routeName for popUntil to work
  static const String routeName = '/services_management';

  const ServicesManagementScreen({super.key}); // Added key

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request & Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        /* actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              // Handle logout/sign out
            },
          ),
        ],*/
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingTen),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: kPaddingMedium,
          mainAxisSpacing: kPaddingMedium,
          childAspectRatio: 0.85,
          children: <Widget>[
            // Service 1: Request Cheque Book
            ServiceGridItem(
              icon: Icons.library_books,
              title: 'Request Cheque Book',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RequestChequeBookScreen()),
                );
              },
            ),

            // 🌟 CRITICAL MODIFICATION: Stop Cheque Navigation
            ServiceGridItem(
              icon: Icons.stop_circle_outlined, // Changed icon for relevance
              title: 'Stop Cheque',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StopChequeScreen()),
                );
              },
            ),
            // Service 3: Cheque Status Inquiry (PAN Update)
            ServiceGridItem(
              icon: Icons.edit_document,
              title: 'PAN Update',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PanUpdateScreen()),
                );
              },
            ),
            // Service 4: TDS Certificate Request
            ServiceGridItem(
              icon: Icons.edit_document,
              title: 'TDS Certificate Request',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TdsCertificateScreen()),
                );
              },
            ),
            // Service 5: Nominee Update
            ServiceGridItem(
              icon: Icons.edit_document,
              title: 'Nominee Update',
              onTap: () {
                Navigator.push(
                  context,
                  // FIX 2: Navigating to the correct top-level screen
                  // FIX 3 (CRITICAL): Added the required 'accountType' parameter.
                  // In a real app, this would navigate to an 'Account Selection Screen' first.
                  MaterialPageRoute(builder: (context) => const NomineeListScreen(accountType: 'Savings')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceGridItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ServiceGridItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSmall),
        ),
        elevation: kCardElevation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: kIconSizeExtraLarge,
              color: colorScheme.primary,
            ),
            const SizedBox(height: kSpacingSmall),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPaddingExtraSmall),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}