// File: lib/screens/detailed_account_view_screen.dart (Final Working Version)

import 'package:flutter/material.dart';
import '../api/banking_service.dart';

// 💡 IMPORTANT: Import centralized design files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// NOTE: Placeholder for model types from your banking_service.dart
// Ensure Account, AccountType, Nominee, and BankingService are accessible.

class DetailedAccountViewScreen extends StatefulWidget {
  final Account account;

  const DetailedAccountViewScreen({super.key, required this.account});

  @override
  State<DetailedAccountViewScreen> createState() => _DetailedAccountViewScreenState();
}

class _DetailedAccountViewScreenState extends State<DetailedAccountViewScreen> {
  final BankingService _bankingService = BankingService();

  bool _isAcNoVisible = false;
  bool _isIfscVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // Replaced hardcoded _bodyBackground with theme color
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // 1. Custom Sliver AppBar focusing only on Current Balance
          _buildCustomSliverAppBar(context),

          SliverPadding(
            // Replaced hardcoded 16.0 with kPaddingMedium
            padding: const EdgeInsets.all(kPaddingMedium),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // 2. UNIFIED Account & Nominee Details Card (Stable Design)
                  _buildUnifiedDetailsCard(context),
                  // Keeping 30 for space at the bottom
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  SliverAppBar _buildCustomSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      expandedHeight: 180.0,
      floating: true,
      pinned: true,
      // Replaced hardcoded _primaryNavyBlue with colorScheme.primary
      backgroundColor: colorScheme.primary,
      // Replaced hardcoded Colors.white with colorScheme.onPrimary
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        // Replaced hardcoded (left: 16, bottom: 12) with constants
        titlePadding: const EdgeInsets.only(left: kPaddingMedium, bottom: kPaddingSmall),
        title: Text(
          widget.account.nickname,
          // Replaced hardcoded style with theme and colorScheme.onPrimary
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // Replaced hardcoded gradient colors with theme/constants
              colors: [colorScheme.primary, kDarkNavy],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              // Replaced hardcoded (top: 40, left: 20, right: 20) with constants
              padding: const EdgeInsets.only(top: kPaddingXXL, left: kPaddingLarge, right: kPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    // Replaced hardcoded style with theme and onPrimary.withOpacity(0.7)
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary.withOpacity(0.7)),
                  ),
                  const SizedBox(height: kPaddingExtraSmall),
                  Text(
                    '₹${widget.account.balance.toStringAsFixed(2)}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimary,
                      // Replaced hardcoded 30 with kCustomBalanceFontSize
                      fontSize: kCustomBalanceFontSize,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnifiedDetailsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // Replaced hardcoded 4 with kCardElevation
      elevation: kCardElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        // Replaced hardcoded 12 with kRadiusMedium
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      // Replaced hardcoded _cardBackground with colorScheme.surface
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2.1 Account Details Section
          _buildCardSectionHeader(context, 'Account Details', Icons.account_balance_wallet_outlined),
          // Replaced hardcoded color, indent, endIndent with constants
          const Divider(height: 0, thickness: 1, color: kDividerColor, indent: kPaddingMedium, endIndent: kPaddingMedium),

          _buildDetailRow('Account Nickname', widget.account.nickname, icon: Icons.person_outline),

          _buildToggleableDetailRow(
            'Full A/C Number',
            widget.account.accountNumber,
            _isAcNoVisible,
                (visible) => setState(() => _isAcNoVisible = visible),
            isAccountNumber: true,
            icon: Icons.credit_card_outlined,
          ),
          _buildToggleableDetailRow(
            'IFSC Code',
            widget.account.ifscCode,
            _isIfscVisible,
                (visible) => setState(() => _isIfscVisible = visible),
            isAccountNumber: false,
            icon: Icons.qr_code_outlined,
          ),
          _buildDetailRow('Account Type', widget.account.accountType.name.toUpperCase(), icon: Icons.description_outlined),

          _buildDetailRow('Branch Address', widget.account.branchAddress, maxLines: 2, icon: Icons.location_on_outlined),

          // 2.2 Nominee Details Section
          const SizedBox(height: kPaddingSmall), // Replaced hardcoded 10 with kPaddingSmall
          _buildCardSectionHeader(context, 'Nominee Details', Icons.person_pin_outlined),
          // Replaced hardcoded color, indent, endIndent with constants
          const Divider(height: 0, thickness: 1, color: kDividerColor, indent: kPaddingMedium, endIndent: kPaddingMedium),

          _buildDetailRow('Nominee Name', widget.account.nominee.name, icon: Icons.badge_outlined, isValueSemiBold: true),
          _buildDetailRow('Relationship', widget.account.nominee.relationship, icon: Icons.groups_outlined, isValueSemiBold: true),
          _buildDetailRow('Nominee D.O.B.', _formatDate(widget.account.nominee.dateOfBirth), icon: Icons.calendar_today_outlined, isValueSemiBold: true),

          const SizedBox(height: kPaddingSmall), // Replaced hardcoded 10 with kPaddingSmall
        ],
      ),
    );
  }

  Widget _buildCardSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // Replaced hardcoded padding with constants
      padding: const EdgeInsets.only(top: kPaddingMedium, bottom: kPaddingExtraSmall, left: kPaddingMedium, right: kPaddingMedium),
      child: Row(
        children: [
          // Replaced hardcoded _secondaryLightBlue and 20 with constants
          Icon(icon, color: colorScheme.secondary, size: kIconSizeSmall),
          const SizedBox(width: kPaddingExtraSmall),
          Text(
            title,
            // Replaced hardcoded style with theme and colorScheme.primary
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value,
      {
        int maxLines = 1,
        required IconData icon,
        bool isValueSemiBold = false,
      }
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Derived color for detail labels from hardcoded _detailLabelColor (0xFF757575)
    final labelColor = colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      // Replaced hardcoded padding with constants
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall, horizontal: kPaddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Icon + Label
          SizedBox(
            // Replaced hardcoded 150 with kLabelColumnWidth
            width: kLabelColumnWidth,
            child: Row(
              children: [
                // Replaced hardcoded color and 20 with constants
                Icon(icon, color: labelColor, size: kIconSizeSmall),
                const SizedBox(width: kPaddingSmall),
                Expanded(
                  child: Text(
                    label,
                    // Replaced hardcoded style with theme
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: kPaddingMedium), // Separator space

          // Right Side: Value
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              // Replaced hardcoded style with theme and colorScheme.onSurface
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: isValueSemiBold ? FontWeight.w600 : FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleableDetailRow(
      String label,
      String fullValue,
      bool isVisible,
      Function(bool) onToggle,
      {
        required bool isAccountNumber,
        required IconData icon,
      }
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // Derived color for detail labels from hardcoded _detailLabelColor (0xFF757575)
    final labelColor = colorScheme.onSurface.withOpacity(0.7);

    final maskedValue = isAccountNumber
        ? _bankingService.maskAccountNumber(fullValue)
        : 'XXXX ${fullValue.substring(fullValue.length - 4)}';

    return Padding(
      // Replaced hardcoded padding with constants
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall, horizontal: kPaddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Left Side: Icon + Label
          SizedBox(
            // Replaced hardcoded 150 with kLabelColumnWidth
            width: kLabelColumnWidth,
            child: Row(
              children: [
                // Replaced hardcoded color and 20 with constants
                Icon(icon, color: labelColor, size: kIconSizeSmall),
                const SizedBox(width: kPaddingSmall),
                Expanded(
                  child: Text(
                    label,
                    // Replaced hardcoded style with theme
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: labelColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: kPaddingMedium), // Separator space

          // Right side: Value + Toggle button
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    isVisible ? fullValue : maskedValue,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    // Replaced hardcoded style with theme and colorScheme.onSurface
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: kPaddingExtraSmall), // Replaced hardcoded 8 with constant
                // Security toggle button
                GestureDetector(
                  onTap: () => onToggle(!isVisible),
                  child: Container(
                    // Replaced hardcoded 4 with kPaddingExtraSmall/2
                    padding: const EdgeInsets.all(kPaddingExtraSmall / 2),
                    decoration: BoxDecoration(
                      // Replaced hardcoded _primaryNavyBlue with colorScheme.primary
                      color: colorScheme.primary.withOpacity(0.1),
                      // Replaced hardcoded 5 with kRadiusExtraSmall
                      borderRadius: BorderRadius.circular(kRadiusExtraSmall),
                    ),
                    child: Icon(
                      isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      // Replaced hardcoded _primaryNavyBlue and 20 with constants
                      color: colorScheme.primary,
                      size: kIconSizeSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format DateTime object (Unchanged)
  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }
}