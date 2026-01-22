// File: lib/screens/detailed_account_view_screen.dart (Final Working Version)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/banking_service.dart';
import '../api/dashboard_repository.dart'; // Contains accountDetailProvider
import '../providers/dashboard_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class DetailedAccountViewScreen extends ConsumerStatefulWidget {
  final String accountId;

  const DetailedAccountViewScreen({super.key, required this.accountId});

  @override
  ConsumerState<DetailedAccountViewScreen> createState() => _DetailedAccountViewScreenState();
}

class _DetailedAccountViewScreenState extends ConsumerState<DetailedAccountViewScreen> {
  // State for toggling visibility of sensitive information
  bool _isAcNoVisible = false;
  bool _isIfscVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Watching the provider using the passed accountId
    final accountAsync = ref.watch(accountDetailProvider(widget.accountId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: accountAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (account) => CustomScrollView(
          slivers: [
            // 1. Custom Sliver AppBar
            _buildCustomSliverAppBar(context, account),

            SliverPadding(
              padding: const EdgeInsets.all(kPaddingMedium),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // 2. UNIFIED Account & Nominee Details Card
                    _buildUnifiedDetailsCard(context, account),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  SliverAppBar _buildCustomSliverAppBar(BuildContext context, Account account) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SliverAppBar(
      expandedHeight: 180.0,
      floating: true,
      pinned: true,
      backgroundColor: colorScheme.primary,
      iconTheme: IconThemeData(color: colorScheme.onPrimary),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: kPaddingMedium, bottom: kPaddingSmall),
        title: Text(
          account.nickname,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, kDarkNavy],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: kPaddingXXL, left: kPaddingLarge, right: kPaddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary.withOpacity(0.7)),
                  ),
                  const SizedBox(height: kPaddingExtraSmall),
                  Text(
                    '₹${account.balance.toStringAsFixed(2)}',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimary,
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

  Widget _buildUnifiedDetailsCard(BuildContext context, Account account) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: kCardElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium),
      ),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2.1 Account Details Section
          _buildCardSectionHeader(context, 'Account Details', Icons.account_balance_wallet_outlined),
          const Divider(height: 0, thickness: 1, color: kDividerColor, indent: kPaddingMedium, endIndent: kPaddingMedium),

          _buildDetailRow('Account Nickname', account.nickname, icon: Icons.person_outline),

          _buildToggleableDetailRow(
            'Full A/C Number',
            account.accountNumber,
            _isAcNoVisible,
                (visible) => setState(() => _isAcNoVisible = visible),
            isAccountNumber: true,
            icon: Icons.credit_card_outlined,
          ),
          _buildToggleableDetailRow(
            'IFSC Code',
            account.ifscCode,
            _isIfscVisible,
                (visible) => setState(() => _isIfscVisible = visible),
            isAccountNumber: false,
            icon: Icons.qr_code_outlined,
          ),

          // Updated Logic for RD Account Display
          _buildDetailRow(
              'Account Type',
              account.accountType == AccountType.recurringDeposit ? "RD ACCOUNT" : account.accountType.name.toUpperCase(),
              icon: Icons.description_outlined
          ),

          _buildDetailRow('Branch Address', account.branchAddress, maxLines: 2, icon: Icons.location_on_outlined),

          // 2.2 Nominee Details Section
          const SizedBox(height: kPaddingSmall),
          _buildCardSectionHeader(context, 'Nominee Details', Icons.person_pin_outlined),
          const Divider(height: 0, thickness: 1, color: kDividerColor, indent: kPaddingMedium, endIndent: kPaddingMedium),

          _buildDetailRow('Nominee Name', account.nominee.name, icon: Icons.badge_outlined, isValueSemiBold: true),
          _buildDetailRow('Relationship', account.nominee.relationship, icon: Icons.groups_outlined, isValueSemiBold: true),
          _buildDetailRow('Nominee D.O.B.', _formatDate(account.nominee.dateOfBirth), icon: Icons.calendar_today_outlined, isValueSemiBold: true),

          const SizedBox(height: kPaddingSmall),
        ],
      ),
    );
  }

  Widget _buildCardSectionHeader(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: kPaddingMedium, bottom: kPaddingExtraSmall, left: kPaddingMedium, right: kPaddingMedium),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.secondary, size: kIconSizeSmall),
          const SizedBox(width: kPaddingExtraSmall),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {int maxLines = 1, required IconData icon, bool isValueSemiBold = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labelColor = colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall, horizontal: kPaddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kLabelColumnWidth,
            child: Row(
              children: [
                Icon(icon, color: labelColor, size: kIconSizeSmall),
                const SizedBox(width: kPaddingSmall),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: labelColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kPaddingMedium),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
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

  Widget _buildToggleableDetailRow(String label, String fullValue, bool isVisible, Function(bool) onToggle, {required bool isAccountNumber, required IconData icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labelColor = colorScheme.onSurface.withOpacity(0.7);

    // FIX: Replaced _bankingService.maskAccountNumber with direct logic
    final maskedValue = isAccountNumber
        ? 'XXXXXX${fullValue.substring(fullValue.length > 4 ? fullValue.length - 4 : 0)}'
        : 'XXXX ${fullValue.substring(fullValue.length > 4 ? fullValue.length - 4 : 0)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall, horizontal: kPaddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: kLabelColumnWidth,
            child: Row(
              children: [
                Icon(icon, color: labelColor, size: kIconSizeSmall),
                const SizedBox(width: kPaddingSmall),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: labelColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: kPaddingMedium),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    isVisible ? fullValue : maskedValue,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: kPaddingExtraSmall),
                GestureDetector(
                  onTap: () => onToggle(!isVisible),
                  child: Container(
                    padding: const EdgeInsets.all(kPaddingExtraSmall / 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(kRadiusExtraSmall),
                    ),
                    child: Icon(
                      isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }
}