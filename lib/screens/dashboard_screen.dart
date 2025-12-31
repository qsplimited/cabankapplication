// File: dashboard_screen.dart (Refactored)
import 'package:flutter/material.dart';
import '../api/banking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'profile_management_screen.dart';
import 'transfer_funds_screen.dart';
import 'tpin_management_screen.dart';
import 'detailed_statement_screen.dart';
import 'quick_transfer_screen.dart';
import 'detailed_account_view_screen.dart';
// CRITICAL FIX: Use prefixes for screens that are incorrectly defining duplicate types.
import 'transaction_history_screen.dart' as ths;
import 'beneficiary_management_screen.dart' as bms;

import 'services_management_screen.dart';
import 'deposit_opening_screen.dart';

import 'chat_bot_screen.dart';

import 'atm_locator_screen.dart';

final BankingService _bankingService = BankingService();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  // Data State
  UserProfile? _userProfile;
  List<Account> _allAccounts = [];
  List<Transaction>? _miniStatement;
  // UI State
  bool _isLoading = true;
  String _errorMessage = '';
  // Global toggle for all account balances (Starts OFF / masked)
  bool _isBalanceVisible = false;
  // State for toggling Account Number visibility (Starts OFF / masked)
  bool _isAccountNoVisible = false; // <<< THIS IS CRITICAL: Starts as false
  int _currentAccountIndex = 0;
  // CRITICAL FIX: Initialize PageController
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _fetchDashboardData();
    _bankingService.onDataUpdate.listen((_) {
      if (mounted) {
        _fetchDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (!_isLoading) {
      setState(() {
        _errorMessage = '';
      });
    }

    try {
      final results = await Future.wait([
        _bankingService.fetchUserProfile(),
        _bankingService.fetchUserAccounts(),
      ]);

      final userProfile = results[0] as UserProfile;
      final allAccounts = results[1] as List<Account>;

      List<Transaction>? miniStatement;
      if (allAccounts.isNotEmpty) {
        miniStatement = await _bankingService.fetchMiniStatement();
      }

      if (mounted) {
        setState(() {
          _userProfile = userProfile;
          _allAccounts = allAccounts;
          _miniStatement = miniStatement;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data. Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // 1. Account Carousel
  Widget _buildAccountCarousel(BuildContext context) {
    if (_allAccounts.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('No accounts found.')));
    }

    const cardHeight = 180.0;
    return SizedBox(
      height: cardHeight,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _allAccounts.length,
        onPageChanged: (index) {
          setState(() {
            _currentAccountIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final account = _allAccounts[index];
          // Use kPaddingSmall for horizontal spacing
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: kPaddingSmall),
            child: _buildSingleAccountCard(context, account),
          );
        },
      ),
    );
  }

  // **Card Implementation Refactored to Theme Constants**
  Widget _buildSingleAccountCard(BuildContext context, Account account) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final balanceText = _isBalanceVisible
        ? '₹${account.balance.toStringAsFixed(2)}'
        : '•••••••';

    // Use specific colors from app_colors.dart for distinction
    Color stripeColor;
    if (account.accountType == AccountType.fixedDeposit || account.accountType == AccountType.recurringDeposit) {
      stripeColor = kFixedDepositCardColor;
    } else if (account.accountType == AccountType.current) {
      stripeColor = kCurrentCardColor;
    } else {
      stripeColor = colorScheme.secondary;
    }

    final String fullAccountNo = account.accountNumber;
    final String maskedAccountNo = '${fullAccountNo.substring(0, 4)} **** ${fullAccountNo.substring(fullAccountNo.length - 4)}';
    final String displayAccountNo = _isAccountNoVisible ? fullAccountNo : maskedAccountNo;

    return GestureDetector(
      onTap: () {
        _navigateTo(DetailedAccountViewScreen(account: account));
      },
      child: Card(
        // Refactored Color & Elevation/Shape
        color: colorScheme.surface,
        elevation: kCardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)), // Use kRadiusLarge (16) to fit original 15
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(kRadiusLarge),
          ),
          child: Row(
            children: [
              // UNIQUE DESIGN: Colored Vertical Stripe
              Container(
                width: 6.0,
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(kRadiusLarge),
                    bottomLeft: Radius.circular(kRadiusLarge),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Type & Balance Visibility Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${account.accountType.name.toUpperCase()} ACCOUNT',
                              // Refactored Text Style (using onSurface for secondary text)
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Balance Visibility Toggle Icon
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isBalanceVisible = !_isBalanceVisible;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(kPaddingExtraSmall),
                              child: Icon(
                                _isBalanceVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: colorScheme.primary, // Use primary color for icon
                                size: kIconSize,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: kPaddingSmall),

                      // Balance Display
                      Text(
                        'Available Balance',
                        // Refactored Text Style
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            letterSpacing: 0.5
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          balanceText,
                          // Refactored Text Style
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                            fontSize: 30,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const Spacer(),

                      // Account Nickname & Number with new Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Account Nickname & Number
                          Flexible(
                            child: Text(
                              '${account.nickname} | $displayAccountNo',
                              // Refactored Text Style
                              style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: kPaddingSmall),

                          // Account Number Toggle
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isAccountNoVisible = !_isAccountNoVisible;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(kPaddingExtraSmall),
                              child: Icon(
                                _isAccountNoVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: colorScheme.primary.withOpacity(0.7),
                                size: kIconSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Quick Actions Grid - Refactored
  Widget _buildQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final List<Map<String, dynamic>> actions = [
      {'label': 'Quick Transfer', 'icon': Icons.flash_on_outlined, 'color': kAccentOrange, 'screen': const QuickTransferScreen()},
      {'label': 'Standard Transfer', 'icon': Icons.send_outlined, 'color': colorScheme.primary, 'screen': TransferFundsScreen(bankingService: _bankingService)},
      {'label': 'Manage Payees', 'icon': Icons.people_alt_outlined, 'color': colorScheme.primary, 'screen': const bms.BeneficiaryManagementScreen()},
      {'label': 'Scan & Pay (UPI)', 'icon': Icons.qr_code_scanner, 'color': colorScheme.primary, 'screen': null},
      {'label': 'Transaction History', 'icon': Icons.history, 'color': colorScheme.primary, 'screen': ths.TransactionHistoryScreen(bankingService: _bankingService)},
      {'label': 'T-PIN Management', 'icon': Icons.lock_reset_outlined, 'color': colorScheme.primary, 'screen': const TpinManagementScreen()},
      {'label': 'Service Management', 'icon': Icons.design_services, 'color': colorScheme.primary, 'screen': ServicesManagementScreen()},
      {'label': 'Deposit Management',
        'icon': Icons.lock_clock,
        'color': colorScheme.primary,
        'screen': DepositOpeningScreen()},

      {'label': 'Locate Us',
        'icon': Icons.lock_clock,
        'color': colorScheme.primary,
        'screen': AtmLocatorScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: kPaddingSmall, top: kPaddingMedium),
            child: Text(
              'Quick Services',
              // Refactored Text Style
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onBackground),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: kPaddingSmall,
              mainAxisSpacing: kPaddingSmall,
              childAspectRatio: 1.0,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: () {
                  if (action['screen'] != null) {
                    _navigateTo(action['screen'] as Widget);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${action['label']} feature coming soon!')),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(kRadiusMedium),
                child: Card(
                  // Refactored Card Style
                  color: colorScheme.surface,
                  elevation: kCardElevation,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                  child: Container(
                    padding: const EdgeInsets.all(kPaddingSmall),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(action['icon'], size: 36, color: action['color']),
                        const SizedBox(height: kPaddingSmall),
                        Text(
                          action['label'],
                          textAlign: TextAlign.center,
                          // Refactored Text Style
                          style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. T-PIN Status Alert - Refactored
  Widget _buildTpinAlertCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_bankingService.isTpinSet) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingSmall),
      child: Card(
        // Refactored Alert Color (using error)
        color: colorScheme.error.withOpacity(0.1),
        elevation: kCardElevation,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMedium),
            side: BorderSide(color: colorScheme.error, width: 1.5)
        ),
        child: Padding(
          padding: const EdgeInsets.all(kPaddingMedium),
          child: Row(
            children: [
              Icon(Icons.security_update_warning, color: colorScheme.error, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTION REQUIRED: T-PIN Not Set',
                      // Refactored Text Style
                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.error),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set your T-PIN now to enable secure transactions.',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.error.withOpacity(0.8)),
                    ),
                    const SizedBox(height: kPaddingSmall),
                    GestureDetector(
                      onTap: () => _navigateTo(const TpinManagementScreen()),
                      child: Text(
                        'SET T-PIN NOW >',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary, // Primary color for the action link
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // 4. Mini Statement List - Refactored
  Widget _buildMiniStatement(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_miniStatement == null || _miniStatement!.isEmpty || _allAccounts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Text(
          'No recent transactions found for ${_allAccounts.isNotEmpty ? _allAccounts[_currentAccountIndex].nickname : 'the selected account'}.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.6)),
        ),
      );
    }
    final currentAccount = _allAccounts[_currentAccountIndex];

    return Padding(
      padding: const EdgeInsets.only(left: kPaddingMedium, right: kPaddingMedium, top: kPaddingSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: kPaddingSmall),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Transactions (${currentAccount.nickname})',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    _navigateTo(
                      DetailedStatementScreen(
                        bankingService: _bankingService,
                        account: currentAccount,
                      ),
                    );
                  },
                  child: Text(
                    'VIEW ALL',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Card(
            // Refactored Card Style
            elevation: kCardElevation,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
            color: colorScheme.surface,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _miniStatement!.length > 5 ? 5 : _miniStatement!.length,
              separatorBuilder: (context, index) =>
              // Use theme divider color
              Divider(height: 1, color: colorScheme.onSurface.withOpacity(0.1), indent: kPaddingMedium, endIndent: kPaddingMedium),
              itemBuilder: (context, index) {
                final tx = _miniStatement![index];
                final isDebit = tx.type == TransactionType.debit;

                // Use adaptive success/error colors
                final amountColor = isDebit ? colorScheme.error : kSuccessGreen;
                final iconColor = isDebit ? colorScheme.error : kSuccessGreen;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: kPaddingSmall, horizontal: kPaddingMedium),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDebit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          color: iconColor,
                          size: kIconSize,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description,
                              // Refactored Text Style
                              style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${tx.date.day}/${tx.date.month} | ${tx.date.hour}:${tx.date.minute.toString().padLeft(2, '0')}',
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.6)
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 2,
                        child: Text(
                          '${isDebit ? '-' : '+'} ₹${tx.amount.toStringAsFixed(2)}',
                          textAlign: TextAlign.end,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // 💡 THEME REFERENCES 💡
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: kPaddingMedium),
              Text(
                  'Loading dashboard data...',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground)
              )
            ],
          ),
        ),
      );
    }
    if (_errorMessage.isNotEmpty || _userProfile == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: $_errorMessage',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final String userFullName = _userProfile!.fullName;
    final String userFirstName = userFullName.split(' ').first;
    final String userInitial = userFullName.split(' ').first.substring(0, 1).toUpperCase();



    return Scaffold(
      backgroundColor: colorScheme.background,
      // --- DRAWER (Menu Bar) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              // Refactored Drawer Header Color
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                CircleAvatar(
                  // Refactored Avatar Colors
                    backgroundColor: colorScheme.onPrimary,
                    radius: 30,
                    child: Text(
                        userInitial,
                        style: textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary // Text color is primary
                        )
                    )
                ),
                const SizedBox(height: kPaddingSmall),
                // Refactored Text Styles
                Text(userFullName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
                Text('Account Holder', style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.7))),
              ]),
            ),



            // Refactored ListTiles (using primary color for active icons)
            ListTile(leading: Icon(Icons.dashboard_outlined, color: colorScheme.primary),
                title: Text('Dashboard', style: textTheme.bodyMedium), onTap: () => Navigator.pop(context)),

            ListTile(leading: Icon(Icons.person_2_outlined, color: kAccentOrange),
                title: Text('Profile', style: textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); _navigateTo(const ProfileManagementScreen()); }),

            ListTile(leading: Icon(Icons.flash_on_outlined, color: kAccentOrange),
                title: Text('Quick Transfer (IMPS)', style: textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); _navigateTo(const QuickTransferScreen()); }),
            ListTile(leading: Icon(Icons.payments_outlined, color: colorScheme.primary),
                title: Text('Standard Transfer (Beneficiary)', style: textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); _navigateTo(TransferFundsScreen(bankingService: _bankingService)); }),
            ListTile(leading: Icon(Icons.people_alt_outlined, color: kCurrentCardColor),
                title: Text('Beneficiary Management', style: textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); _navigateTo(const bms.BeneficiaryManagementScreen()); }),

            ListTile(leading: Icon(Icons.qr_code_scanner, color: kSuccessGreen),
                title: Text('Scan & Pay (UPI)', style: textTheme.bodyMedium), onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan & Pay (UPI) feature coming soon!')));
                }),
            ListTile(leading: Icon(Icons.history_toggle_off_outlined, color: kSavingsCardColor),
                title: Text('Transaction History', style: textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); _navigateTo(ths.TransactionHistoryScreen(bankingService: _bankingService)); }),
            ListTile(leading: Icon(Icons.lock_reset_outlined, color: colorScheme.primary),
                title: Text('T-PIN Management', style: textTheme.bodyMedium),
                onTap: () { Navigator.pop(context); _navigateTo(const TpinManagementScreen()); }),

            const Divider(),

            ListTile(leading: const Icon(Icons.logout, color: kErrorRed), title: Text('Logout', style: textTheme.bodyMedium), onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logging out user...')));
              Navigator.pop(context);
            }),
          ],
        ),
      ),
      // --- APP BAR (Unique Integrated Design) ---
      appBar: AppBar(
        // Refactored Header Color
        backgroundColor: colorScheme.primary,
        elevation: 0,
        toolbarHeight: 0,
      ),
      // --- BODY (Stabilized CustomScrollView) ---
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: colorScheme.primary,
        child: CustomScrollView(
          slivers: <Widget>[

            // 1. UNIQUE HEADER & WELCOME MESSAGE
            SliverToBoxAdapter(
              child: Container(
                height: 100,
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: kPaddingMedium, right: kPaddingMedium),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(kPaddingExtraLarge)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu, color: colorScheme.onPrimary, size: 28),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back,',
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.7)),
                            ),
                            Text(
                              userFirstName,
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: colorScheme.onPrimary, size: 28),
                          onPressed: () { /* Notifications */ },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, top: 12),
                          child: CircleAvatar(
                            // Refactored Avatar Colors
                            backgroundColor: colorScheme.onPrimary,
                            radius: 15,
                            child: Text(
                              userInitial,
                              style: textTheme.labelLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 2. Account Summary Carousel (Pulled up into the header curve)
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -50),
                child: _buildAccountCarousel(context),
              ),
            ),

            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  children: [
                    // Page Indicator Dots
                    Padding(
                      padding: const EdgeInsets.only(bottom: kPaddingSmall),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_allAccounts.length, (index) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Refactored Color
                              color: _currentAccountIndex == index
                                  ? colorScheme.secondary
                                  : colorScheme.onBackground.withOpacity(0.3),
                            ),
                          );
                        }),
                      ),
                    ),
                    // T-PIN Status Alert
                    _buildTpinAlertCard(),
                    // Quick Actions
                    _buildQuickActions(),
                    // Mini Statement List
                    _buildMiniStatement(context),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary, // Matches your app's theme
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        tooltip: 'Chat with Assistant',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatBotScreen()),
          );
        },
      ),
    );
  }
}