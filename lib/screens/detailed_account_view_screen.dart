// File: lib/screens/detailed_account_view_screen.dart (Final Stable Banking Design)

import 'package:flutter/material.dart';
import '../api/banking_service.dart';

// NOTE: Placeholder for model types from your banking_service.dart
// You must ensure these models are correctly defined or imported from there.
// class Account {
//   final String nickname;
//   final String accountNumber;
//   final String ifscCode;
//   final AccountType accountType;
//   final String branchAddress;
//   final double balance;
//   final Nominee nominee;
//   Account(...);
// }
// enum AccountType { savings, current, fixedDeposit, recurringDeposit }
// class Nominee {
//   final String name;
//   final String relationship;
//   final DateTime dateOfBirth;
//   Nominee(...);
// }
// class BankingService {
//   String maskAccountNumber(String accountNo) => '******${accountNo.substring(accountNo.length - 4)}';
// }


// --- UNIQUE BANKING DESIGN PALETTE ---
const Color _primaryNavyBlue = Color(0xFF003366); // Main Brand Color
const Color _secondaryLightBlue = Color(0xFF1E88E5); // Accent Color
const Color _cardBackground = Color(0xFFFFFFFF); // Pure white background for better contrast/cleanliness
const Color _detailLabelColor = Color(0xFF757575); // Lighter gray for descriptive labels
const Color _detailValueColor = Colors.black87; // Near-black for important data
const Color _bodyBackground = Color(0xFFF0F2F5); // Light gray background for body
// ------------------------------------

class DetailedAccountViewScreen extends StatefulWidget {
  final Account account;

  const DetailedAccountViewScreen({super.key, required this.account});

  @override
  State<DetailedAccountViewScreen> createState() => _DetailedAccountViewScreenState();
}

class _DetailedAccountViewScreenState extends State<DetailedAccountViewScreen> {
  // NOTE: You must ensure this is a valid instance.
  final BankingService _bankingService = BankingService();

  bool _isAcNoVisible = false;
  bool _isIfscVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bodyBackground,
      body: CustomScrollView(
        slivers: [
          // 1. Custom Sliver AppBar focusing only on Current Balance
          _buildCustomSliverAppBar(context),

          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  // 2. UNIFIED Account & Nominee Details Card (Stable Design)
                  _buildUnifiedDetailsCard(context),
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
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: true,
      pinned: true,
      backgroundColor: _primaryNavyBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
        // Title appears when collapsed (Reduced size)
        title: Text(
          widget.account.nickname,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryNavyBlue, Color(0xFF004488)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  // Balance amount size reduced from 36 to 30
                  Text(
                    '₹${widget.account.balance.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontSize: 30,
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
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: _cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2.1 Account Details Section
          _buildCardSectionHeader(context, 'Account Details', Icons.account_balance_wallet_outlined),
          const Divider(height: 0, thickness: 1, color: Color(0xFFE0E5EA), indent: 16, endIndent: 16),

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
          const SizedBox(height: 10),
          _buildCardSectionHeader(context, 'Nominee Details', Icons.person_pin_outlined),
          const Divider(height: 0, thickness: 1, color: Color(0xFFE0E5EA), indent: 16, endIndent: 16),

          _buildDetailRow('Nominee Name', widget.account.nominee.name, icon: Icons.badge_outlined, isValueSemiBold: true),
          _buildDetailRow('Relationship', widget.account.nominee.relationship, icon: Icons.groups_outlined, isValueSemiBold: true),
          _buildDetailRow('Nominee D.O.B.', _formatDate(widget.account.nominee.dateOfBirth), icon: Icons.calendar_today_outlined, isValueSemiBold: true),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCardSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          Icon(icon, color: _secondaryLightBlue, size: 20),
          const SizedBox(width: 8),
          // Section header size reduced from 17 to 16
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _primaryNavyBlue,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ALIGNMENT FIX: Uses fixed width for label section and Expanded for value.
  Widget _buildDetailRow(
      String label,
      String value,
      {
        int maxLines = 1,
        required IconData icon,
        bool isValueSemiBold = false, // New parameter for non-critical value styling
      }
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Icon + Label (Fixed width for clean vertical alignment)
          SizedBox(
            width: 150,
            child: Row(
              children: [
                Icon(icon, color: _detailLabelColor.withOpacity(0.8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _detailLabelColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16), // Separator space

          // Right Side: Value (Takes remaining space)
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // Use semi-bold for general details, bold for numbers/critical items
                fontWeight: isValueSemiBold ? FontWeight.w600 : FontWeight.bold,
                color: _detailValueColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ALIGNMENT FIX: Uses fixed width for label section and Expanded for value/toggle.
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
    final maskedValue = isAccountNumber
        ? _bankingService.maskAccountNumber(fullValue)
        : 'XXXX ${fullValue.substring(fullValue.length - 4)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Left Side: Icon + Label (Fixed width for alignment)
          SizedBox(
            width: 150,
            child: Row(
              children: [
                Icon(icon, color: _detailLabelColor.withOpacity(0.8), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _detailLabelColor,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16), // Separator space

          // Right side: Value + Toggle button (Takes remaining space)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible( // Use Flexible to protect the toggle button space
                  child: Text(
                    isVisible ? fullValue : maskedValue,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, // Keep sensitive numbers bold
                      color: _detailValueColor,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Security toggle button
                GestureDetector(
                  onTap: () => onToggle(!isVisible),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _primaryNavyBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _primaryNavyBlue,
                      size: 20,
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

  // Helper to format DateTime object
  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }
}